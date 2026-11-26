import 'package:carenest_app/core/integration/api_dates.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/teacher/rewards/domain/teacher_rewards.dart';
import 'package:carenest_app/features/teacher/school_year/presentation/selected_school_year.dart';

/// Khen thưởng từ BE, App chỉ xem: đề xuất cuối năm (OBS-14) `GET /assessment/reward-lists` và
/// `/classes/{classId}` (tên năm học tra từ `GET /school-years`); phiếu bé ngoan
/// `GET /assessment/behaviour-tickets/board` và `/summary`.
class LiveTeacherRewardSource implements TeacherRewardSource {
  LiveTeacherRewardSource(this._api, {String? Function()? schoolYearId})
    : _schoolYearId = schoolYearId ?? (() => SelectedSchoolYear.apiYearId);

  final MobileApi _api;
  final String? Function() _schoolYearId;

  @override
  Future<TeacherRewards> load(String classId) async {
    final data =
        await _api.json('GET', '/assessment/reward-lists/classes/$classId')
            as Map? ??
        const {};
    return TeacherRewards(
      className: data['className']?.toString() ?? '',
      schoolYearLabel: await _yearLabel(data['schoolYearId']),
      status: _status(data['status']),
      titleOptions: _strings(data['titleOptions']),
      children: [
        for (final row in _maps(data['children']))
          TeacherRewardChild(
            childId: '${row['childId']}',
            fullName: row['fullName']?.toString() ?? '',
            schoolDays: _int(row['schoolDays']),
            presentDays: _int(row['presentDays']),
            weeklyTickets: _int(row['weeklyTickets']),
            monthlyTickets: _int(row['monthlyTickets']),
            suggested: _strings(row['suggested']),
            titles: _strings(row['titles']),
            note: row['note']?.toString() ?? '',
          ),
      ],
    );
  }

  @override
  Future<TicketBoard> loadBoard(
    String classId,
    TicketKind kind, {
    DateTime? periodStart,
  }) async {
    final query = [
      'classId=$classId',
      'type=${kind.code}',
      if (periodStart != null) 'periodStart=${apiDate(periodStart)}',
    ].join('&');
    final data =
        await _api.json('GET', '/assessment/behaviour-tickets/board?$query')
            as Map? ??
        const {};
    final period = data['period'];
    return TicketBoard(
      className: (data['cls'] as Map?)?['name']?.toString() ?? '',
      kind: kind,
      periods: [for (final p in _maps(data['periods'])) ?_period(p)],
      period: period is Map ? _period(period) : null,
      rules: {
        for (final e in (data['rules'] as Map? ?? const {}).entries)
          if (e.value is num) '${e.key}': (e.value as num).toInt(),
      },
      rows: [
        for (final row in _maps(data['rows']))
          TicketBoardRow(
            childId: '${(row['child'] as Map?)?['id']}',
            fullName: (row['child'] as Map?)?['fullName']?.toString() ?? '',
            presentDays: _int(row['presentDays']),
            flagCount: _int(row['flagCount']),
            weeklyTickets: _int(row['weeklyTickets']),
            eligible: row['eligible'] == true,
            hasTicket: row['ticket'] != null,
            issuedAt: _instant((row['ticket'] as Map?)?['issuedAt']),
            issuedElsewhere: row['issuedElsewhere'] == true,
            canIssue: row['canIssue'] != false,
          ),
      ],
    );
  }

  @override
  Future<TicketSummary> loadSummary(String classId, {DateTime? month}) async {
    final query = [
      'classId=$classId',
      if (month != null) 'month=${apiDate(month)}',
    ].join('&');
    final data =
        await _api.json('GET', '/assessment/behaviour-tickets/summary?$query')
            as Map? ??
        const {};
    final totals = data['totals'] as Map? ?? const {};
    return TicketSummary(
      className: (data['cls'] as Map?)?['name']?.toString() ?? '',
      month: _date(data['month']),
      months: [for (final m in data['months'] as List? ?? const []) ?_date(m)],
      weekly: _int(totals['weekly']),
      monthly: _int(totals['monthly']),
      children: _int(totals['children']),
      total: _int(totals['total']),
      rows: [
        for (final row in _maps(data['rows']))
          TicketSummaryRow(
            childId: '${(row['child'] as Map?)?['id']}',
            fullName: (row['child'] as Map?)?['fullName']?.toString() ?? '',
            weekly: _int(row['weekly']),
            monthly: _int(row['monthly']),
            flags: _int(row['flags']),
          ),
      ],
    );
  }

  @override
  Future<List<RewardClassRow>> loadClasses() async {
    final yearId = _schoolYearId();
    final data = await _api.json(
      'GET',
      '/assessment/reward-lists${yearId == null ? '' : '?schoolYearId=$yearId'}',
    );
    return [
      for (final row in _maps(data))
        RewardClassRow(
          classId: '${row['classId']}',
          className: row['className']?.toString() ?? '',
          children: _int(row['children']),
          awarded: (row['awarded'] as num?)?.toInt(),
          status: _status(row['status']),
          submittedAt: _instant(row['submittedAt']),
        ),
    ];
  }

  Future<String> _yearLabel(Object? yearId) async {
    if (yearId == null) return '';
    try {
      final years =
          await _api.json('GET', '/school-years') as List? ?? const [];
      for (final year in years.whereType<Map>()) {
        if ('${year['id']}' == '$yearId') {
          return '${year['name'] ?? ''}'.replaceAll('-', '–');
        }
      }
    } on ApiFailure {
      // Thiếu tên năm học ⇒ để trống, không chặn danh sách
    }
    return '';
  }

  static Iterable<Map<Object?, Object?>> _maps(Object? list) =>
      (list as List? ?? const []).whereType<Map>();

  static int _int(Object? value) => (value as num?)?.round() ?? 0;

  static DateTime? _date(Object? value) {
    if (value is! String) return null;
    final parsed = DateTime.tryParse(value);
    return parsed == null
        ? null
        : DateTime(parsed.year, parsed.month, parsed.day);
  }

  static DateTime? _instant(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;

  static TicketPeriod? _period(Map<Object?, Object?> json) {
    final start = _date(json['start']);
    final end = _date(json['end']);
    if (start == null || end == null) return null;
    return TicketPeriod(
      start: start,
      end: end,
      weekNo: (json['weekNo'] as num?)?.toInt(),
    );
  }

  static RewardStatus? _status(Object? code) {
    for (final status in RewardStatus.values) {
      if (status.code == code) return status;
    }
    return null;
  }

  static List<String> _strings(Object? list) => [
    for (final item in list as List? ?? const []) '$item',
  ];
}

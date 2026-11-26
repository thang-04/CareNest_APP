import 'package:carenest_app/core/integration/api_dates.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/features/parent/evaluation/domain/evaluation.dart'
    as ev;
import 'package:carenest_app/features/parent/evaluation/presentation/evaluation_labels.dart';
import 'package:carenest_app/features/teacher/daily_review/domain/daily_review.dart';
import 'package:carenest_app/features/teacher/school_year/presentation/selected_school_year.dart';

/// Đánh giá của lớp từ BE (chỉ xem): ngày = `GET /classes/{classId}/daily-assessment` (hôm nay; `rows` = trẻ có mặt,
/// `absentChildren` = trẻ vắng / chưa điểm danh); tuần = `GET /assessment/weekly-comments?classId=` (tuần BE mặc định);
/// học kỳ / cuối năm = `GET /assessment/evaluations?classId=` (nội dung `finalContent`). API này không có đánh giá
/// theo chủ đề và không trả giờ đến ⇒ không có kỳ chủ đề, dòng hiện diện chỉ "Có mặt".
class LiveDailyReviewSource implements DailyReviewSource {
  LiveDailyReviewSource(this._api, {String? Function()? schoolYearId})
    : _schoolYearId = schoolYearId ?? (() => SelectedSchoolYear.apiYearId);

  final MobileApi _api;
  final String? Function() _schoolYearId;

  @override
  Future<ReviewDay> loadDay(String classId, {DateTime? date}) async {
    final query = date == null ? '' : '?date=${apiDate(date)}';
    final sheet =
        await _api.json('GET', '/classes/$classId/daily-assessment$query')
            as Map? ??
        const {};
    final sessions = [
      for (final code in sheet['mealSessions'] as List? ?? const [])
        ?_sessions[code],
    ];
    return ReviewDay(
      date: DateTime.parse(sheet['date']! as String),
      activityLine: _activityLine(sheet['lesson']),
      criteria: _criteria(sessions),
      flagLabel: 'Cờ bé ngoan',
      attendanceTaken: sheet['attendanceTaken'] != false,
      locked: sheet['locked'] == true,
      yearReadOnly: sheet['yearReadOnly'] == true,
      classComment: (sheet['classComment'] as Map?)?['text']?.toString() ?? '',
      kids: [
        for (final row in _maps(sheet['rows'])) _kid(row, sessions),
        for (final child in _maps(sheet['absentChildren'])) _absent(child),
      ],
    );
  }

  @override
  Future<List<PeriodReview>> loadPeriods(String classId) async {
    final yearId = _schoolYearId();
    final yearQuery = yearId == null ? '' : '&schoolYearId=$yearId';
    final results = await Future.wait([
      _api.json('GET', '/assessment/weekly-comments?classId=$classId'),
      _api.json('GET', '/assessment/evaluations?classId=$classId$yearQuery'),
    ]);
    final board = results[0] as Map? ?? const {};
    final week = board['week'] as Map?;
    final weekLabel = week == null
        ? ''
        : EvaluationLabels.week(
            week['label']?.toString() ?? 'Tuần',
            DateTime.parse(week['from']! as String),
            DateTime.parse(week['to']! as String),
          );
    return [
      for (final row in _maps(board['children']))
        if (row['status'] == 'SENT')
          PeriodReview(
            childId: '${row['childId']}',
            fullName: row['fullName']?.toString() ?? '',
            kind: ReviewPeriodKind.week,
            periodLabel: weekLabel,
            summary: row['content']?.toString() ?? '',
            statusLabel: 'Đã gửi',
          ),
      for (final row in _maps(results[1])) ?_evaluation(row),
    ];
  }

  static PeriodReview? _evaluation(Map<Object?, Object?> row) {
    final kind = switch (row['periodType']) {
      'SEMESTER' => ReviewPeriodKind.semester,
      'YEAR' => ReviewPeriodKind.yearEnd,
      _ => null,
    };
    if (kind == null) return null;
    final range = switch ((row['periodStart'], row['periodEnd'])) {
      (final String from, final String to) => DateLabels.range(
        DateTime.parse(from),
        DateTime.parse(to),
      ),
      _ => '',
    };
    final confirmed = row['status'] == 'CONFIRMED';
    final title = kind == ReviewPeriodKind.yearEnd ? 'Cuối năm học' : 'Học kỳ';
    return PeriodReview(
      childId: '${row['childId']}',
      fullName: row['childName']?.toString() ?? '',
      kind: kind,
      periodLabel: '$title · $range',
      // Bản chưa xác nhận là nháp của hệ thống, chưa phải nhận xét chính thức
      summary: confirmed ? row['finalContent']?.toString() ?? '' : '',
      statusLabel: confirmed ? 'Đã xác nhận' : 'Chờ xác nhận',
    );
  }

  static Iterable<Map<Object?, Object?>> _maps(Object? list) =>
      (list as List? ?? const []).whereType<Map>();

  static String _activityLine(Object? lesson) => [
    for (final a in _maps((lesson as Map?)?['activities']))
      [
        a['label'],
        a['topic'],
      ].where((t) => t != null && '$t'.isNotEmpty).join(': '),
  ].where((line) => line.isNotEmpty).join(' · ');

  static const _sessions = {
    'MORNING': ev.MealSession.morning,
    'LUNCH': ev.MealSession.lunch,
    'AFTERNOON': ev.MealSession.afternoon,
  };
  static const _eating = {
    'AN_HET': ev.EatingLevel.finished,
    'AN_IT': ev.EatingLevel.little,
    'KHONG_AN': ev.EatingLevel.none,
  };
  static const _naps = {
    'NGU_TOT': ev.NapLevel.good,
    'NGU_IT': ev.NapLevel.little,
    'KHONG_NGU': ev.NapLevel.none,
  };
  static const _emotions = {
    'HAPPY': ev.Emotion.happy,
    'CALM': ev.Emotion.calm,
    'SAD': ev.Emotion.sad,
    'UPSET': ev.Emotion.upset,
  };
  static const _participations = {
    'TICH_CUC': ev.Participation.active,
    'BINH_THUONG': ev.Participation.normal,
    'CHUA_TICH_CUC': ev.Participation.passive,
  };
  static const _signs = {
    'FEVER': ev.HealthSign.fever,
    'COUGH': ev.HealthSign.cough,
    'RUNNY_NOSE': ev.HealthSign.runnyNose,
    'FLU': ev.HealthSign.flu,
    'TIRED': ev.HealthSign.tired,
    'OTHER': ev.HealthSign.other,
  };
  static const _behaviors = {
    'HOP_TAC_TOT': ev.ObservedBehavior.cooperative,
    'GIUP_DO_BAN': ev.ObservedBehavior.helpful,
    'CHUA_HOP_TAC': ev.ObservedBehavior.uncooperative,
    'TRANH_GIANH': ev.ObservedBehavior.grabbing,
    'KHONG_TAP_TRUNG': ev.ObservedBehavior.unfocused,
    'RUT_RE': ev.ObservedBehavior.shy,
    'KHAC': ev.ObservedBehavior.other,
  };

  static List<ReviewCriterionDef> _criteria(List<ev.MealSession> sessions) {
    final eating = [
      for (final l in ev.EatingLevel.values) EvaluationLabels.eating(l),
    ];
    return [
      for (final s in sessions)
        ReviewCriterionDef(
          id: 'meal-${s.name}',
          title: 'Ăn ${EvaluationLabels.mealShort(s).toLowerCase()}',
          options: eating,
          defaultOption: eating.first,
        ),
      ReviewCriterionDef(
        id: 'nap',
        title: 'Ngủ trưa',
        options: [for (final l in ev.NapLevel.values) EvaluationLabels.nap(l)],
        defaultOption: EvaluationLabels.nap(ev.NapLevel.good),
      ),
      ReviewCriterionDef(
        id: 'emotion',
        title: 'Cảm xúc',
        options: [
          for (final l in ev.Emotion.values) EvaluationLabels.emotion(l),
        ],
        defaultOption: EvaluationLabels.emotion(ev.Emotion.happy),
      ),
      ReviewCriterionDef(
        id: 'participation',
        title: 'Tham gia hoạt động',
        options: [
          for (final l in ev.Participation.values)
            EvaluationLabels.participation(l),
        ],
        defaultOption: EvaluationLabels.participation(ev.Participation.active),
      ),
      const ReviewCriterionDef(
        id: 'health',
        title: 'Sức khỏe',
        options: ['Bình thường', 'Có biểu hiện'],
        defaultOption: 'Bình thường',
      ),
    ];
  }

  static KidReview _kid(
    Map<Object?, Object?> row,
    List<ev.MealSession> sessions,
  ) {
    final recorded = row['recorded'] == true;
    final meals = row['meals'] as Map? ?? const {};
    final signs = (row['health'] as Map?)?['signs'] as List? ?? const [];
    final answers = <String, String>{
      if (recorded) ...{
        for (final s in sessions)
          if (_eating[meals[_codeOf(s)]] case final level?)
            'meal-${s.name}': EvaluationLabels.eating(level),
        if (_naps[row['nap']] case final level?)
          'nap': EvaluationLabels.nap(level),
        if (_emotions[row['emotion']] case final e?)
          'emotion': EvaluationLabels.emotion(e),
        if (_participations[row['participation']] case final p?)
          'participation': EvaluationLabels.participation(p),
        'health': signs.isEmpty ? 'Bình thường' : 'Có biểu hiện',
      },
    };
    final note = row['behaviorNote']?.toString() ?? '';
    return KidReview(
      childId: '${row['childId']}',
      fullName: row['fullName']?.toString() ?? '',
      state: recorded ? KidReviewState.done : KidReviewState.pending,
      presenceLine: 'Có mặt',
      answers: answers,
      comment: row['comment']?.toString() ?? '',
      attentionNotes: [
        for (final code in row['behaviors'] as List? ?? const [])
          if (_behaviors[code] case final b?) EvaluationLabels.behavior(b),
        if (note.isNotEmpty) note,
      ],
      flagged: row['flag'] == true,
      healthSigns: [
        for (final code in signs)
          if (_signs[code] case final sign?) EvaluationLabels.healthSign(sign),
      ],
    );
  }

  static String _codeOf(ev.MealSession s) => s.name.toUpperCase();

  static KidReview _absent(Map<Object?, Object?> child) => KidReview(
    childId: '${child['childId']}',
    fullName: child['fullName']?.toString() ?? '',
    state: KidReviewState.absent,
    presenceLine: switch (child['attendanceStatus']) {
      'EXCUSED' => 'Vắng có phép',
      'UNEXCUSED' => 'Vắng không phép',
      _ => 'Chưa điểm danh',
    },
  );
}

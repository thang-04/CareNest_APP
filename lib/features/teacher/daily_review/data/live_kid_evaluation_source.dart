import 'package:carenest_app/core/integration/api_dates.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/features/parent/evaluation/domain/evaluation.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/evaluation_labels.dart';
import 'package:carenest_app/features/parent/school_year/domain/child_school_year.dart';

/// Đánh giá một bé cho GV (chỉ xem), cùng các API Web dùng (quyền `ASSESSMENT_VIEW`, BE lọc theo lớp của GV):
/// ngày + cuối năm = `GET /assessment/children/{childId}/development` (lớp hiện tại lấy từ `cls.id`);
/// nhận xét tuần = `GET /assessment/weekly-comments?classId=&weekStart=` (chỉ bản `SENT`);
/// chủ đề = `GET /assessment/theme-evaluations/themes` + `/assessment/theme-evaluations` (chỉ `CONFIRMED`);
/// học kỳ = `GET /assessment/semester-evaluations?classId=&semester=` (chỉ `CONFIRMED`);
/// phiếu cuối năm = `GET /assessment/evaluations/{id}/year-sheet`. Bản nháp không hiện.
class LiveKidEvaluationSource implements EvaluationSource {
  LiveKidEvaluationSource(this._api);

  final MobileApi _api;

  /// Số tuần gần nhất tải nhận xét tuần (mỗi tuần 1 lời gọi).
  static const _maxWeeks = 8;

  @override
  Future<EvaluationBook> load(String childId, {ChildSchoolYear? year}) async {
    final data =
        await _api.json('GET', '/assessment/children/$childId/development')
            as Map? ??
        const {};
    final classId = (data['cls'] as Map?)?['id'];
    final byWeek = <DateTime, List<DayEvaluation>>{};
    for (final item in _maps(data['days'])) {
      final day = _day(item);
      byWeek.putIfAbsent(mondayOf(day.date), () => []).add(day);
    }
    final mondays = byWeek.keys.toList()..sort((a, b) => b.compareTo(a));
    final yearEnd = _maps(
      data['yearEnd'],
    ).where((row) => row['status'] == 'CONFIRMED').firstOrNull;
    final comments = classId == null
        ? const <WeeklyComment>[]
        : await _comments(classId, childId);
    final themes = classId == null
        ? const <ThemeResult>[]
        : await _themes(classId, childId);
    final semesters = classId == null
        ? const <SemesterResult>[]
        : await _semesters(classId, childId);
    return EvaluationBook(
      weeks: [
        for (final monday in mondays)
          EvaluationWeek(
            label: 'Tuần ${DateLabels.dayMonth(monday)}',
            from: monday,
            to: DateTime(monday.year, monday.month, monday.day + 4),
            days: byWeek[monday]!..sort((a, b) => a.date.compareTo(b.date)),
          ),
      ],
      weeklyComments: comments,
      themes: themes,
      semesters: semesters,
      yearEnd: yearEnd == null ? null : await _yearEnd(yearEnd),
    );
  }

  /// Gọi API phụ: lỗi (chưa có kỳ, không đủ quyền với lớp cũ…) ⇒ bỏ qua phần đó, không làm hỏng cả trang.
  Future<Object?> _optional(String path) async {
    try {
      return await _api.json('GET', path);
    } on ApiFailure {
      return null;
    }
  }

  Future<List<WeeklyComment>> _comments(Object classId, String childId) async {
    final first = await _optional(
      '/assessment/weekly-comments?classId=$classId',
    );
    if (first is! Map) return const [];
    final options = _maps(first['weeks']).toList()
      ..sort((a, b) => '${b['weekStart']}'.compareTo('${a['weekStart']}'));
    final defaultStart = (first['week'] as Map?)?['weekStart'];
    final others = [
      for (final option in options)
        if ('${option['weekStart']}' != '$defaultStart') option,
    ].take(_maxWeeks - 1);
    final boards = [
      first,
      ...await Future.wait([
        for (final option in others)
          _optional(
            '/assessment/weekly-comments?classId=$classId'
            '&weekStart=${option['weekStart']}',
          ),
      ]),
    ];
    final comments = <WeeklyComment>[];
    for (final board in boards.whereType<Map>()) {
      final week = board['week'] as Map?;
      final from = DateTime.tryParse('${week?['from']}');
      final to = DateTime.tryParse('${week?['to']}');
      if (from == null || to == null) continue;
      for (final row in _maps(board['children'])) {
        // Chỉ bản đã gửi phụ huynh; DRAFT là bản nháp (có thể do AI soạn) nên không hiện
        if ('${row['childId']}' != childId || row['status'] != 'SENT') continue;
        comments.add(
          WeeklyComment(
            weekLabel: EvaluationLabels.week(
              week?['label']?.toString() ?? 'Tuần',
              from,
              to,
            ),
            from: from,
            to: to,
            paragraphs: [
              for (final line in '${row['content'] ?? ''}'.split('\n'))
                if (line.trim().isNotEmpty) line.trim(),
            ],
            teacherName: row['sentByName']?.toString() ?? '',
            sentAt: _instant(row['sentAt']) ?? to,
          ),
        );
      }
    }
    return comments..sort((a, b) => b.from.compareTo(a.from));
  }

  Future<List<ThemeResult>> _themes(Object classId, String childId) async {
    final list = await _optional(
      '/assessment/theme-evaluations/themes?classId=$classId',
    );
    final confirmed = _maps(list).where((t) => t['status'] == 'CONFIRMED');
    final boards = await Future.wait([
      for (final theme in confirmed)
        _optional(
          '/assessment/theme-evaluations?classId=$classId'
          '&themeId=${theme['themeId']}',
        ),
    ]);
    final results = <ThemeResult>[];
    for (final board in boards.whereType<Map>()) {
      if (board['status'] != 'CONFIRMED') continue;
      final row = _maps(
        board['rows'],
      ).where((r) => '${r['childId']}' == childId).firstOrNull;
      if (row == null) continue;
      final goalById = {
        for (final goal in _maps(board['goals'])) '${goal['goalId']}': goal,
      };
      final met = (row['met'] as num?)?.toInt() ?? 0;
      final notMet = (row['notMet'] as num?)?.toInt() ?? 0;
      results.add(
        ThemeResult(
          id: 'theme-${board['themeId']}',
          name: board['themeName']?.toString() ?? '',
          semester: null,
          from: DateTime.parse(board['startDate']! as String),
          to: DateTime.parse(board['endDate']! as String),
          metGoals: met,
          totalGoals: met + notMet,
          passed: row['passed'] as bool?,
          passPercent: (board['passPercent'] as num?)?.toInt(),
          // Ô chưa chấm (met null) bỏ qua như phụ huynh
          goals: [
            for (final cell in _maps(row['cells']))
              if (cell['met'] case final bool ok)
                GoalResult(
                  goalById['${cell['goalId']}']?['text']?.toString() ?? '',
                  met: ok,
                ),
          ],
          confirmedBy: board['confirmedByName']?.toString(),
          confirmedAt: _instant(board['confirmedAt']),
        ),
      );
    }
    return results..sort((a, b) => b.from.compareTo(a.from));
  }

  Future<List<SemesterResult>> _semesters(
    Object classId,
    String childId,
  ) async {
    final boards = await Future.wait([
      for (final semester in const [1, 2])
        _optional(
          '/assessment/semester-evaluations?classId=$classId&semester=$semester',
        ),
    ]);
    final results = <SemesterResult>[];
    for (final board in boards.whereType<Map>()) {
      if (board['status'] != 'CONFIRMED') continue;
      final row = _maps(
        board['rows'],
      ).where((r) => '${r['childId']}' == childId).firstOrNull;
      if (row == null) continue;
      final domains = [
        for (final domain in _maps(row['domains']))
          DomainResult(
            name: domain['name']?.toString() ?? '',
            metGoals: (domain['metCount'] as num?)?.toInt(),
            totalGoals: switch ((domain['metCount'], domain['notMetCount'])) {
              (final num met, final num notMet) => (met + notMet).toInt(),
              _ => null,
            },
            met: domain['met'] as bool?,
            goals: _goals(domain['goals']),
          ),
      ];
      results.add(
        SemesterResult(
          semester: (board['semester'] as num?)?.toInt() ?? 1,
          schoolYear: board['yearName']?.toString(),
          from: DateTime.parse(board['startDate']! as String),
          to: DateTime.parse(board['endDate']! as String),
          domainsMet: domains.where((d) => d.met == true).length,
          domainsTotal: domains.where((d) => d.met != null).length,
          domains: domains,
          confirmedBy: board['confirmedByName']?.toString(),
          confirmedAt: _instant(board['confirmedAt']),
        ),
      );
    }
    return results..sort((a, b) => b.semester.compareTo(a.semester));
  }

  /// Phiếu cuối năm: nhận xét + chương trình từ dòng đánh giá; lĩnh vực / lưu ý từ `year-sheet` (nếu tải được).
  Future<YearEndResult> _yearEnd(Map<Object?, Object?> row) async {
    final sheet = row['id'] == null
        ? null
        : await _optional('/assessment/evaluations/${row['id']}/year-sheet');
    final sheetMap = sheet is Map ? sheet : null;
    final notes = sheetMap?['notes'] as Map?;
    final met = (sheetMap?['metCount'] as num?)?.toInt() ?? 0;
    final notMet = (sheetMap?['notMetCount'] as num?)?.toInt() ?? 0;
    return YearEndResult(
      schoolYear: null,
      ageGroup: sheetMap?['ageGroupName']?.toString(),
      metGoals: met,
      totalGoals: met + notMet,
      programCompleted: row['programCompleted'] as bool?,
      teacherComment: row['finalContent']?.toString(),
      noteForParent: notes?['forParent']?.toString(),
      domains: [
        for (final domain in _maps(sheetMap?['domains']))
          DomainResult(
            name: domain['name']?.toString() ?? '',
            metGoals: null,
            totalGoals: null,
            goals: _goals(domain['goals']),
            comment: domain['comment']?.toString(),
          ),
      ],
      confirmedBy: row['confirmedByName']?.toString(),
      confirmedAt: _instant(row['confirmedAt']),
    );
  }

  /// MT chưa có kết quả (`met` null) bỏ qua.
  static List<GoalResult> _goals(Object? goals) => [
    for (final goal in _maps(goals))
      if (goal['met'] case final bool met)
        GoalResult(goal['text']?.toString() ?? '', met: met),
  ];

  static Iterable<Map<Object?, Object?>> _maps(Object? list) =>
      (list as List? ?? const []).whereType<Map>();

  static DateTime? _instant(Object? value) => switch (value) {
    final String at => DateTime.parse(at).toLocal(),
    _ => null,
  };

  static DayEvaluation _day(Map<Object?, Object?> item) {
    final meals = item['meals'] as Map? ?? const {};
    final health = item['health'] as Map?;
    return DayEvaluation(
      date: DateTime.parse(item['date']! as String),
      teacherName: item['recordedByName']?.toString(),
      savedAt: _instant(item['recordedAt']),
      healthSigns: [
        for (final code in health?['signs'] as List? ?? const [])
          ?_healthSigns[code],
      ],
      meals: {
        for (final MapEntry(:key, :value) in meals.entries)
          if ((_mealSessions[key], _eatingLevels[value]) case (
            final MealSession session?,
            final EatingLevel level?,
          ))
            session: level,
      },
      nap: _napLevels[item['nap']],
      emotion: _emotions[item['emotion']],
      behaviors: [
        for (final code in item['behaviors'] as List? ?? const [])
          ?_behaviors[code],
      ],
      goals: [
        for (final goal in _maps(item['met']))
          GoalResult(goal['name']?.toString() ?? '', met: true),
        // "Cố gắng" tính là chưa đạt như màn phụ huynh
        for (final goal in _maps(item['effort']))
          GoalResult(goal['name']?.toString() ?? '', met: false),
        for (final goal in _maps(item['notMet']))
          GoalResult(goal['name']?.toString() ?? '', met: false),
      ],
      comment: item['comment']?.toString(),
    );
  }

  static const _healthSigns = {
    'FEVER': HealthSign.fever,
    'COUGH': HealthSign.cough,
    'RUNNY_NOSE': HealthSign.runnyNose,
    'FLU': HealthSign.flu,
    'TIRED': HealthSign.tired,
    'OTHER': HealthSign.other,
  };
  static const _mealSessions = {
    'MORNING': MealSession.morning,
    'LUNCH': MealSession.lunch,
    'AFTERNOON': MealSession.afternoon,
  };
  static const _eatingLevels = {
    'AN_HET': EatingLevel.finished,
    'AN_IT': EatingLevel.little,
    'KHONG_AN': EatingLevel.none,
  };
  static const _napLevels = {
    'NGU_TOT': NapLevel.good,
    'NGU_IT': NapLevel.little,
    'KHONG_NGU': NapLevel.none,
  };
  static const _emotions = {
    'HAPPY': Emotion.happy,
    'CALM': Emotion.calm,
    'SAD': Emotion.sad,
    'UPSET': Emotion.upset,
  };
  static const _behaviors = {
    'HOP_TAC_TOT': ObservedBehavior.cooperative,
    'GIUP_DO_BAN': ObservedBehavior.helpful,
    'CHUA_HOP_TAC': ObservedBehavior.uncooperative,
    'TRANH_GIANH': ObservedBehavior.grabbing,
    'KHONG_TAP_TRUNG': ObservedBehavior.unfocused,
    'RUT_RE': ObservedBehavior.shy,
    'KHAC': ObservedBehavior.other,
  };
}

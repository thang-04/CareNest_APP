import 'package:carenest_app/core/integration/api_dates.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/features/parent/evaluation/domain/evaluation.dart';

/// Trang Đánh giá từ BE (OBS-36): đánh giá ngày `GET /children/{id}/daily-assessments` (8 tuần gần nhất),
/// nhận xét tuần `GET /children/{id}/weekly-comments`, chủ đề / học kỳ / cuối năm `GET /children/{id}/evaluations`.
/// BE chỉ trả kết quả đã chốt ⇒ mọi kỳ là `confirmed`.
class LiveEvaluationSource implements EvaluationSource {
  LiveEvaluationSource(this._api, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final MobileApi _api;
  final DateTime Function() _clock;

  @override
  Future<EvaluationBook> load(String childId) async {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    final results = await Future.wait([
      // Đầu năm học: 8 tuần trước có thể trước khai giảng (BE 4109) ⇒ thu hẹp
      loadFromNearestStart(
        recentStarts(today),
        (from) => _api.json(
          'GET',
          '/children/$childId/daily-assessments'
              '?from=${apiDate(from)}&to=${apiDate(today)}',
        ),
      ),
      _api.json('GET', '/children/$childId/weekly-comments'),
      _api.json('GET', '/children/$childId/evaluations'),
    ]);
    final comments = [for (final item in _maps(results[1])) _comment(item)]
      ..sort((a, b) => b.from.compareTo(a.from));
    final evaluations = results[2] as Map? ?? const {};
    return EvaluationBook(
      weeks: _weeksOf(_maps(results[0]), comments),
      weeklyComments: comments,
      themes: [for (final item in _maps(evaluations['themes'])) _theme(item)]
        ..sort((a, b) => b.from.compareTo(a.from)),
      semesters: [
        for (final item in _maps(evaluations['semesters'])) _semester(item),
      ]..sort((a, b) => b.semester.compareTo(a.semester)),
      yearEnd: switch (evaluations['yearEnd']) {
        final Map item => _yearEnd(item),
        _ => null,
      },
    );
  }

  static Iterable<Map<Object?, Object?>> _maps(Object? list) =>
      (list as List? ?? const []).whereType<Map>();

  static DateTime? _instant(Object? value) => switch (value) {
    final String at => DateTime.parse(at).toLocal(),
    _ => null,
  };

  static DateTime _date(Object? value) => DateTime.parse(value! as String);

  /// Ngày học theo tuần (thứ Hai – thứ Sáu); tuần mới nhất trước, ngày trong tuần tăng dần.
  static List<EvaluationWeek> _weeksOf(
    Iterable<Map<Object?, Object?>> items,
    List<WeeklyComment> comments,
  ) {
    final byWeek = <DateTime, List<DayEvaluation>>{};
    for (final item in items) {
      final day = _day(item);
      byWeek.putIfAbsent(mondayOf(day.date), () => []).add(day);
    }
    final mondays = byWeek.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final monday in mondays)
        EvaluationWeek(
          // Tên tuần của giáo án chỉ có ở nhận xét tuần; tuần chưa có nhận xét ghi ngày đầu tuần
          label:
              comments.where((c) => c.from == monday).firstOrNull?.weekLabel ??
              'Tuần ${DateLabels.dayMonth(monday)}',
          from: monday,
          to: DateTime(monday.year, monday.month, monday.day + 4),
          days: byWeek[monday]!..sort((a, b) => a.date.compareTo(b.date)),
        ),
    ];
  }

  static DayEvaluation _day(Map<Object?, Object?> item) {
    final date = _date(item['date']);
    final status = switch (item['status']) {
      'ASSESSED' => DayStatus.evaluated,
      'ABSENT' => DayStatus.absent,
      _ => DayStatus.notRecorded,
    };
    if (status != DayStatus.evaluated) {
      return DayEvaluation(date: date, status: status);
    }
    final meals = item['meals'] as Map? ?? const {};
    return DayEvaluation(
      date: date,
      teacherName: item['teacherName']?.toString(),
      savedAt: _instant(item['savedAt']),
      flagged: item['flag'] == true,
      healthSigns: [
        for (final code in item['symptoms'] as List? ?? const [])
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
      participation: _participations[item['participation']],
      goals: [
        for (final activity in _maps(item['activities'])) ..._goals(activity),
      ],
      comment: item['comment']?.toString(),
    );
  }

  /// Mục tiêu của một hoạt động; "cố gắng" tính là chưa đạt (FE bỏ mức này từ 04/11).
  static List<GoalResult> _goals(Map<Object?, Object?> activity) {
    final label = activity['label']?.toString();
    List<GoalResult> of(String key, {required bool met}) => [
      for (final text in activity[key] as List? ?? const [])
        GoalResult('$text', met: met, activity: label),
    ];
    return [
      ...of('goalsMet', met: true),
      ...of('goalsEffort', met: false),
      ...of('goalsNotMet', met: false),
    ];
  }

  static WeeklyComment _comment(Map<Object?, Object?> item) => WeeklyComment(
    weekLabel: item['weekLabel']?.toString() ?? '',
    from: _date(item['weekFrom'] ?? item['weekStart']),
    to: _date(item['weekEnd']),
    paragraphs: [
      for (final line in '${item['content'] ?? ''}'.split('\n'))
        if (line.trim().isNotEmpty) line.trim(),
    ],
    teacherName: item['teacherName']?.toString() ?? '',
    sentAt: _instant(item['sentAt']) ?? _date(item['weekEnd']),
  );

  /// MT cô chưa đánh giá (`met` null) bỏ qua: BE không tính vào đạt / chưa đạt.
  static List<GoalResult> _parentGoals(Object? goals) => [
    for (final goal in _maps(goals))
      if (goal['met'] case final bool met)
        GoalResult(goal['text']?.toString() ?? '', met: met),
  ];

  static DomainResult _domain(Map<Object?, Object?> item) => DomainResult(
    name: item['name']?.toString() ?? '',
    metGoals: null,
    totalGoals: null,
    goals: _parentGoals(item['goals']),
    comment: item['comment']?.toString(),
  );

  static ThemeResult _theme(Map<Object?, Object?> item) {
    final met = (item['met'] as num?)?.toInt() ?? 0;
    final notMet = (item['notMet'] as num?)?.toInt() ?? 0;
    return ThemeResult(
      // Màn chi tiết tải lại sổ rồi tìm theo ID ⇒ ID ổn định theo kỳ của chủ đề
      id: 'theme-${item['startDate']}-${item['classId']}',
      name: item['themeName']?.toString() ?? '',
      semester: null,
      from: _date(item['startDate']),
      to: _date(item['endDate']),
      metGoals: met,
      totalGoals: met + notMet,
      passPercent: null,
      goals: _parentGoals(item['goals']),
      confirmedAt: _instant(item['confirmedAt']),
    );
  }

  static SemesterResult _semester(Map<Object?, Object?> item) => SemesterResult(
    semester: (item['semester'] as num?)?.toInt() ?? 1,
    schoolYear: null,
    from: _date(item['startDate']),
    to: _date(item['endDate']),
    domainsMet: null,
    domainsTotal: null,
    domains: [for (final domain in _maps(item['domains'])) _domain(domain)],
    confirmedAt: _instant(item['confirmedAt']),
  );

  static YearEndResult _yearEnd(Map<Object?, Object?> item) {
    final met = (item['met'] as num?)?.toInt() ?? 0;
    final notMet = (item['notMet'] as num?)?.toInt() ?? 0;
    return YearEndResult(
      schoolYear: null,
      ageGroup: null,
      metGoals: met,
      totalGoals: met + notMet,
      programCompleted: item['programCompleted'] as bool?,
      teacherComment: item['comment']?.toString(),
      noteForParent: item['noteForParent']?.toString(),
      domains: [for (final domain in _maps(item['domains'])) _domain(domain)],
      confirmedAt: _instant(item['confirmedAt']),
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
  static const _participations = {
    'TICH_CUC': Participation.active,
    'BINH_THUONG': Participation.normal,
    'CHUA_TICH_CUC': Participation.passive,
  };
}

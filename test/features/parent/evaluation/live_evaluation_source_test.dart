import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/parent/evaluation/data/live_evaluation_source.dart';
import 'package:carenest_app/features/parent/evaluation/domain/evaluation.dart';

import '../../../helpers/live_fakes.dart';

void main() {
  late FakeLiveSession session;
  // Thứ Tư; 8 tuần gần nhất, lùi tới ngày 1 tháng trước (cùng khoảng với Khen thưởng)
  final today = DateTime(2026, 11, 25);
  const days =
      'GET /children/5/daily-assessments?from=2026-10-01&to=2026-11-25';

  setUp(() => session = FakeLiveSession(['PARENT'], childIds: [5]));

  Map<String, Object? Function(Object?)> routes({
    List<Object> assessments = const [],
    List<Object> comments = const [],
    Map<String, Object?>? evaluations,
  }) => {
    days: (_) => assessments,
    'GET /children/5/weekly-comments': (_) => comments,
    'GET /children/5/evaluations': (_) =>
        evaluations ??
        {
          'childId': 5,
          'themes': <Object>[],
          'semesters': <Object>[],
          'yearEnd': null,
        },
  };

  Future<EvaluationBook> load(Map<String, Object? Function(Object?)> r) =>
      LiveEvaluationSource(
        ScriptedApi(session, r),
        clock: () => today,
      ).load('5');

  Map<String, Object?> emptyDay(String date, String status) => {
    'date': date,
    'status': status,
    'meals': <String, Object>{},
    'behaviors': <String>[],
    'activities': <Object>[],
    'symptoms': <String>[],
  };

  test('load_groupsDaysIntoWeeks', () async {
    final book = await load(
      routes(
        assessments: [
          emptyDay('2026-11-17', 'ABSENT'),
          emptyDay('2026-11-18', 'NOT_RECORDED'),
          {
            'date': '2026-11-24',
            'status': 'ASSESSED',
            'teacherName': 'Cô Hà',
            'savedAt': '2026-11-24T09:30:00Z',
            'symptoms': ['COUGH'],
            'meals': {'MORNING': 'AN_HET', 'LUNCH': 'AN_IT'},
            'nap': 'NGU_TOT',
            'emotion': 'HAPPY',
            'participation': 'TICH_CUC',
            'behaviors': ['HOP_TAC_TOT'],
            'activities': [
              {
                'label': 'Hoạt động học · Làm quen chữ p',
                'goalsMet': ['Nhận biết chữ p'],
                'goalsEffort': ['Tô chữ p'],
                'goalsNotMet': ['Đọc chữ q'],
              },
            ],
            'flag': true,
            'comment': 'Con học chăm.',
          },
        ],
        comments: [
          {
            'weekStart': '2026-11-16',
            'weekFrom': '2026-11-16',
            'weekEnd': '2026-11-20',
            'weekLabel': 'Tuần 11',
            'content': 'Đoạn một.\n\nĐoạn hai.',
            'sentAt': '2026-11-20T10:00:00Z',
            'teacherName': 'Cô Hà',
          },
        ],
      ),
    );

    // Tuần mới nhất trước, ngày trong tuần tăng dần
    expect(book.weeks.map((w) => w.from), [
      DateTime(2026, 11, 23),
      DateTime(2026, 11, 16),
    ]);
    expect(book.weeks.first.to, DateTime(2026, 11, 27));
    // Tên tuần lấy từ nhận xét tuần BE trả; không có thì ghi ngày đầu tuần
    expect(book.weeks.last.label, 'Tuần 11');
    expect(book.weeks.first.label, 'Tuần 23/11');
    expect(book.weeks.last.days.map((d) => d.status), [
      DayStatus.absent,
      DayStatus.notRecorded,
    ]);

    final day = book.weeks.first.days.single;
    expect(day.status, DayStatus.evaluated);
    expect(day.teacherName, 'Cô Hà');
    expect(day.savedAt, DateTime.utc(2026, 11, 24, 9, 30).toLocal());
    expect(day.flagged, isTrue);
    expect(day.healthSigns, [HealthSign.cough]);
    expect(day.meals, {
      MealSession.morning: EatingLevel.finished,
      MealSession.lunch: EatingLevel.little,
    });
    expect(day.nap, NapLevel.good);
    expect(day.emotion, Emotion.happy);
    expect(day.participation, Participation.active);
    expect(day.behaviors, [ObservedBehavior.cooperative]);
    expect(day.goals.map((g) => '${g.text}|${g.met}|${g.activity}'), [
      'Nhận biết chữ p|true|Hoạt động học · Làm quen chữ p',
      // FE bỏ "Cần cố gắng" từ 04/11: cố gắng = chưa đạt
      'Tô chữ p|false|Hoạt động học · Làm quen chữ p',
      'Đọc chữ q|false|Hoạt động học · Làm quen chữ p',
    ]);
    expect(day.comment, 'Con học chăm.');

    final comment = book.weeklyComments.single;
    expect(comment.weekLabel, 'Tuần 11');
    expect(comment.from, DateTime(2026, 11, 16));
    expect(comment.to, DateTime(2026, 11, 20));
    expect(comment.paragraphs, ['Đoạn một.', 'Đoạn hai.']);
    expect(comment.teacherName, 'Cô Hà');
  });

  test('load_mapsThemeSemesterYearEnd', () async {
    final book = await load(
      routes(
        evaluations: {
          'childId': 5,
          'themes': [
            {
              'themeName': 'Gia đình',
              'startDate': '2026-10-05',
              'endDate': '2026-10-30',
              'met': 3,
              'notMet': 1,
              'goals': [
                {'goalNo': 1, 'text': 'Kể tên người thân', 'met': true},
                {'goalNo': 2, 'text': 'Hát bài về gia đình', 'met': false},
              ],
              'confirmedAt': '2026-11-02T08:00:00Z',
            },
          ],
          'semesters': [
            {
              'semester': 1,
              'startDate': '2026-09-05',
              'endDate': '2027-01-15',
              'domains': [
                {
                  'name': 'Phát triển thể chất',
                  'goals': [
                    {'goalNo': 1, 'text': 'Đi thăng bằng', 'met': true},
                  ],
                  'comment': null,
                },
              ],
              'comment': 'Bé tiến bộ.',
              'confirmedAt': '2027-01-20T08:00:00Z',
            },
          ],
          'yearEnd': {
            'domains': [
              {
                'name': 'Phát triển ngôn ngữ',
                'goals': [
                  {'goalNo': 5, 'text': 'Kể chuyện', 'met': true},
                ],
                'comment': 'Bé kể chuyện mạch lạc.',
              },
            ],
            'met': 20,
            'notMet': 2,
            'programCompleted': true,
            'comment': 'Bé sẵn sàng vào lớp 1.',
            'noteForParent': 'Cho bé đọc sách mỗi tối.',
            'confirmedAt': '2027-05-25T08:00:00Z',
          },
        },
      ),
    );

    final theme = book.themes.single;
    expect(theme.name, 'Gia đình');
    expect(theme.from, DateTime(2026, 10, 5));
    expect(theme.to, DateTime(2026, 10, 30));
    expect(theme.status, PeriodStatus.confirmed);
    expect(theme.metGoals, 3);
    expect(theme.totalGoals, 4);
    // BE chưa trả "đạt chủ đề", ngưỡng %, học kỳ của chủ đề ⇒ không tự suy
    expect(theme.passed, isNull);
    expect(theme.passPercent, isNull);
    expect(theme.semester, isNull);
    expect(theme.goals.map((g) => '${g.text}|${g.met}'), [
      'Kể tên người thân|true',
      'Hát bài về gia đình|false',
    ]);
    expect(book.themeById(theme.id), same(theme));

    final semester = book.semesters.single;
    expect(semester.semester, 1);
    expect(semester.schoolYear, isNull);
    expect(semester.domainsMet, isNull);
    expect(semester.domains.single.name, 'Phát triển thể chất');
    expect(semester.domains.single.met, isNull);
    expect(semester.domains.single.metGoals, isNull);
    expect(semester.domains.single.goals.single.met, isTrue);

    final yearEnd = book.yearEnd!;
    expect(yearEnd.metGoals, 20);
    expect(yearEnd.totalGoals, 22);
    expect(yearEnd.programCompleted, isTrue);
    expect(yearEnd.teacherComment, 'Bé sẵn sàng vào lớp 1.');
    expect(yearEnd.noteForParent, 'Cho bé đọc sách mỗi tối.');
    expect(yearEnd.domains.single.comment, 'Bé kể chuyện mạch lạc.');
    expect(yearEnd.confirmedAt, DateTime.utc(2027, 5, 25, 8).toLocal());
  });

  test('load_unassessedGoals_notShownAsNotMet', () async {
    final book = await load(
      routes(
        evaluations: {
          'themes': [
            {
              'themeName': 'Gia đình',
              'startDate': '2026-10-05',
              'endDate': '2026-10-30',
              'met': 1,
              'notMet': 1,
              'goals': [
                {'goalNo': 1, 'text': 'Kể tên người thân', 'met': true},
                {'goalNo': 2, 'text': 'Hát bài về gia đình', 'met': false},
                // Cô chưa đánh giá MT này: BE không tính vào đạt / chưa đạt
                {'goalNo': 3, 'text': 'Vẽ người thân', 'met': null},
              ],
            },
          ],
          'semesters': <Object>[],
          'yearEnd': null,
        },
      ),
    );

    expect(book.themes.single.goals.map((g) => g.text), [
      'Kể tên người thân',
      'Hát bài về gia đình',
    ]);
  });

  test('load_outsideSchoolYear_keepsThemesAndYearEnd', () async {
    // Hè: lớp năm cũ còn mở tới khi kích hoạt năm mới ⇒ BE 4109 với mọi khoảng tới hôm nay
    final r = routes(
      evaluations: {
        'themes': <Object>[],
        'semesters': <Object>[],
        'yearEnd': {'met': 20, 'notMet': 2, 'domains': <Object>[]},
      },
    );
    for (final from in ['10-01', '10-05', '11-01', '11-23', '11-25']) {
      r['GET /children/5/daily-assessments?from=2026-$from&to=2026-11-25'] =
          (_) =>
              throw ApiFailure(400, 'Chọn khoảng ngày trong một năm học', 4109);
    }

    final book = await load(r);

    expect(book.weeks, isEmpty);
    expect(book.yearEnd!.totalGoals, 22);
  });

  test('load_noYearEnd_null', () async {
    final book = await load(routes());

    expect(book.yearEnd, isNull);
    expect(book.themes, isEmpty);
    expect(book.weeks, isEmpty);
  });
}

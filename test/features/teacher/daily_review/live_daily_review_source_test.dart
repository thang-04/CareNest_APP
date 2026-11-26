import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/parent/evaluation/domain/evaluation.dart';
import 'package:carenest_app/features/teacher/daily_review/data/live_daily_review_source.dart';
import 'package:carenest_app/features/teacher/daily_review/data/live_kid_evaluation_source.dart';
import 'package:carenest_app/features/teacher/daily_review/domain/daily_review.dart';

import '../../../helpers/live_fakes.dart';

void main() {
  final session = FakeLiveSession(['TEACHER']);

  test('loadDay_mapsRowsAbsentAndCriteria', () async {
    final api = ScriptedApi(session, {
      'GET /classes/12/daily-assessment': (_) => {
        'date': '2026-11-25',
        'mealSessions': ['MORNING', 'LUNCH'],
        'lesson': {
          'activities': [
            {'key': 'a', 'label': 'Tạo hình', 'topic': 'Tô lá', 'goals': []},
          ],
        },
        'classComment': {'text': 'Lớp ngoan'},
        'rows': [
          {
            'childId': 5,
            'fullName': 'Nguyễn Minh Anh',
            'recorded': true,
            'meals': {'MORNING': 'AN_HET', 'LUNCH': 'AN_IT'},
            'nap': 'NGU_IT',
            'emotion': 'HAPPY',
            'participation': 'TICH_CUC',
            'behaviors': ['HOP_TAC_TOT'],
            'behaviorNote': 'Giúp cô',
            'flag': true,
            'comment': 'Tốt',
            'health': {
              'signs': ['COUGH'],
            },
          },
          {'childId': 6, 'fullName': 'Trần Bảo', 'recorded': false},
        ],
        'absentChildren': [
          {'childId': 7, 'fullName': 'Lê Na', 'attendanceStatus': 'EXCUSED'},
          {'childId': 8, 'fullName': 'Phạm Vy', 'attendanceStatus': null},
        ],
      },
    });
    final day = await LiveDailyReviewSource(api).loadDay('12');
    expect(day.activityLine, 'Tạo hình: Tô lá');
    expect(day.classComment, 'Lớp ngoan');
    expect(day.criteria.map((c) => c.id), [
      'meal-morning',
      'meal-lunch',
      'nap',
      'emotion',
      'participation',
      'health',
    ]);
    final done = day.kids[0];
    expect(done.state, KidReviewState.done);
    expect(done.answers['meal-lunch'], 'Ăn ít');
    expect(done.answers['nap'], 'Ngủ ít');
    expect(done.answers['health'], 'Có biểu hiện');
    expect(done.healthSigns, ['Ho']);
    expect(done.attentionNotes, ['Hợp tác tốt', 'Giúp cô']);
    expect(done.flagged, isTrue);
    expect(day.kids[1].state, KidReviewState.pending);
    expect(day.kids[2].presenceLine, 'Vắng có phép');
    expect(day.kids[3].presenceLine, 'Chưa điểm danh');
  });

  test('loadPeriods_mapsSentWeekAndEvaluations', () async {
    final api = ScriptedApi(session, {
      'GET /assessment/weekly-comments?classId=12': (_) => {
        'week': {'label': 'Tuần 12', 'from': '2026-11-23', 'to': '2026-11-27'},
        'children': [
          {'childId': 5, 'fullName': 'A', 'status': 'SENT', 'content': 'Ổn'},
          {'childId': 6, 'fullName': 'B', 'status': 'DRAFT', 'content': 'x'},
        ],
      },
      'GET /assessment/evaluations?classId=12': (_) => [
        {
          'childId': 5,
          'childName': 'A',
          'periodType': 'SEMESTER',
          'periodStart': '2026-09-05',
          'periodEnd': '2026-12-31',
          'status': 'CONFIRMED',
          'finalContent': 'Tốt',
        },
        {'childId': 6, 'childName': 'B', 'periodType': 'MONTH'},
        {
          'childId': 6,
          'childName': 'B',
          'periodType': 'YEAR',
          'status': 'AWAITING_REVIEW',
          'finalContent': 'nháp',
        },
      ],
    });
    final list = await LiveDailyReviewSource(api).loadPeriods('12');
    expect(list.map((p) => p.kind), [
      ReviewPeriodKind.week,
      ReviewPeriodKind.semester,
      ReviewPeriodKind.yearEnd,
    ]);
    expect(list[0].summary, 'Ổn');
    expect(list[1].statusLabel, 'Đã xác nhận');
    expect(list[2].summary, '');
  });

  test('kidEvaluation_groupsDaysByWeekAndMapsYearEnd', () async {
    final api = ScriptedApi(session, {
      'GET /assessment/children/5/development': (_) => {
        'days': [
          {
            'date': '2026-11-24',
            'meals': {'LUNCH': 'AN_HET'},
            'nap': 'NGU_TOT',
            'emotion': 'CALM',
            'behaviors': <String>[],
            'health': {'signs': <String>[]},
            'met': [
              {'id': 1, 'name': 'MT1'},
            ],
            'effort': <Object>[],
            'notMet': [
              {'id': 2, 'name': 'MT2'},
            ],
            'comment': 'Tốt',
            'recordedByName': 'Cô Hoa',
          },
        ],
        'yearEnd': [
          {
            'status': 'CONFIRMED',
            'finalContent': 'Hoàn thành',
            'programCompleted': true,
          },
        ],
      },
    });
    final book = await LiveKidEvaluationSource(api).load('5');
    expect(book.weeks.single.from, DateTime(2026, 11, 23));
    final day = book.weeks.single.days.single;
    expect(day.meals[MealSession.lunch], EatingLevel.finished);
    expect(day.goals.map((g) => g.met), [true, false]);
    expect(day.teacherName, 'Cô Hoa');
    expect(book.yearEnd?.teacherComment, 'Hoàn thành');
    expect(book.yearEnd?.programCompleted, isTrue);
  });

  test('kidEvaluation_mapsWeeklyThemeSemesterYearSheetConfirmedOnly', () async {
    final api = ScriptedApi(session, {
      'GET /assessment/children/5/development': (_) => {
        'cls': {'id': 12},
        'days': <Object>[],
        'yearEnd': [
          {
            'id': 90,
            'status': 'CONFIRMED',
            'finalContent': 'Hoàn thành',
            'programCompleted': true,
            'confirmedByName': 'Cô Hoa',
          },
        ],
      },
      'GET /assessment/weekly-comments?classId=12': (_) => {
        'week': {
          'weekStart': '2026-11-23',
          'label': 'Tuần 12',
          'from': '2026-11-23',
          'to': '2026-11-27',
        },
        'weeks': [
          {'weekStart': '2026-11-23'},
          {'weekStart': '2026-11-16'},
        ],
        'children': [
          {
            'childId': 5,
            'status': 'SENT',
            'content': 'Ổn\nTốt',
            'sentByName': 'Cô Hoa',
            'sentAt': '2026-11-27T03:00:00Z',
          },
        ],
      },
      'GET /assessment/weekly-comments?classId=12&weekStart=2026-11-16': (_) =>
          {
            'week': {
              'weekStart': '2026-11-16',
              'label': 'Tuần 11',
              'from': '2026-11-16',
              'to': '2026-11-20',
            },
            'children': [
              {'childId': 5, 'status': 'DRAFT', 'content': 'nháp'},
            ],
          },
      'GET /assessment/theme-evaluations/themes?classId=12': (_) => [
        {'themeId': 3, 'status': 'CONFIRMED'},
        {'themeId': 4, 'status': 'DRAFT'},
      ],
      'GET /assessment/theme-evaluations?classId=12&themeId=3': (_) => {
        'themeId': 3,
        'themeName': 'Bản thân',
        'startDate': '2026-09-05',
        'endDate': '2026-10-02',
        'status': 'CONFIRMED',
        'passPercent': 70,
        'confirmedByName': 'Cô Hoa',
        'goals': [
          {'goalId': 1, 'text': 'MT1'},
          {'goalId': 2, 'text': 'MT2'},
          {'goalId': 3, 'text': 'MT3'},
        ],
        'rows': [
          {
            'childId': 5,
            'met': 1,
            'notMet': 1,
            'passed': false,
            'cells': [
              {'goalId': 1, 'met': true},
              {'goalId': 2, 'met': false},
              {'goalId': 3, 'met': null},
            ],
          },
        ],
      },
      'GET /assessment/semester-evaluations?classId=12&semester=1': (_) => {
        'semester': 1,
        'yearName': '2026-2027',
        'startDate': '2026-09-05',
        'endDate': '2027-01-15',
        'status': 'CONFIRMED',
        'rows': [
          {
            'childId': 5,
            'domains': [
              {
                'name': 'Thể chất',
                'metCount': 2,
                'notMetCount': 1,
                'met': true,
                'goals': [
                  {'text': 'MT1', 'met': true},
                ],
              },
            ],
          },
        ],
      },
      'GET /assessment/semester-evaluations?classId=12&semester=2': (_) => {
        'semester': 2,
        'status': 'DRAFT',
        'rows': <Object>[],
      },
      'GET /assessment/evaluations/90/year-sheet': (_) => {
        'ageGroupName': 'Nhóm 5-6 tuổi',
        'metCount': 8,
        'notMetCount': 2,
        'notes': {'forParent': 'Luyện viết'},
        'domains': [
          {
            'name': 'Ngôn ngữ',
            'comment': 'Tốt',
            'goals': [
              {'text': 'MT9', 'met': false},
            ],
          },
        ],
      },
    });
    final book = await LiveKidEvaluationSource(api).load('5');
    expect(book.weeklyComments.single.paragraphs, ['Ổn', 'Tốt']);
    expect(book.weeklyComments.single.teacherName, 'Cô Hoa');
    final theme = book.themes.single;
    expect(theme.id, 'theme-3');
    expect((theme.metGoals, theme.totalGoals, theme.passed), (1, 2, false));
    expect(theme.goals.map((g) => g.text), ['MT1', 'MT2']);
    final semester = book.semesters.single;
    expect(semester.semester, 1);
    expect(semester.domains.single.metGoals, 2);
    expect(semester.domains.single.totalGoals, 3);
    expect(semester.domainsMet, 1);
    final yearEnd = book.yearEnd!;
    expect(yearEnd.ageGroup, 'Nhóm 5-6 tuổi');
    expect((yearEnd.metGoals, yearEnd.totalGoals), (8, 10));
    expect(yearEnd.noteForParent, 'Luyện viết');
    expect(yearEnd.domains.single.comment, 'Tốt');
    expect(yearEnd.confirmedBy, 'Cô Hoa');
  });
}

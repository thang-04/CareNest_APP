import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/teacher/attendance/data/live_attendance_source.dart';
import 'package:carenest_app/features/teacher/attendance/domain/attendance.dart';
import 'package:carenest_app/features/shared/school_menu/data/live_teacher_menu_source.dart';
import 'package:carenest_app/features/teacher/activity_schedule/data/live_activity_schedule_source.dart';
import 'package:carenest_app/features/teacher/class_roster/data/live_class_roster_source.dart';
import 'package:carenest_app/features/teacher/class_roster/data/live_teacher_classes.dart';
import 'package:carenest_app/features/teacher/class_roster/domain/class_roster.dart';
import 'package:carenest_app/features/teacher/daily_health/data/live_daily_health_source.dart';
import 'package:carenest_app/features/teacher/daily_health/domain/daily_health.dart';
import 'package:carenest_app/features/teacher/teacher_home/data/live_teacher_home_source.dart';
import 'package:carenest_app/features/teacher/teacher_home/domain/teacher_today.dart';

import '../../../helpers/live_fakes.dart';

void main() {
  late FakeLiveSession session;
  setUp(() => session = FakeLiveSession(['TEACHER']));

  final classes = [
    {
      'id': 3,
      'name': 'Lớp khác',
      'campusId': 1,
      'mealSessions': ['LUNCH'],
      'teaches': false,
      'canRecord': false,
      'canUnlock': false,
    },
    {
      'id': 12,
      'name': 'Mầm 3A',
      'campusId': 1,
      'mealSessions': ['MORNING', 'LUNCH', 'AFTERNOON'],
      'teaches': true,
      'canRecord': true,
      'canUnlock': false,
    },
  ];

  Map<String, Object?> sheet() => {
    'day': {
      'date': '2026-11-26',
      'today': '2026-11-26',
      'cutoff': '08:30',
      'schoolDay': true,
      'locked': false,
    },
    'classId': 12,
    'className': 'Mầm 3A',
    'campusId': 1,
    'mealSessions': ['LUNCH', 'AFTERNOON'],
    'canRecord': true,
    'children': [
      {
        'child': {'id': 101, 'fullName': 'Nguyễn Minh Anh', 'hasAllergy': true},
        'record': {
          'status': 'PRESENT',
          'meals': {'LUNCH': true, 'AFTERNOON': false},
        },
        'health': {
          'checked': true,
          'entryCount': 2,
          'observation': 'NOTED',
          'temperature': 37.8,
          'symptoms': ['COUGH'],
          'note': 'Ho nhẹ',
          'recordedAt': '2026-11-26T01:00:00Z',
        },
        'leave': null,
      },
      {
        'child': {'id': 102, 'fullName': 'Lê Hoàng Nam'},
        'record': null,
        'health': {'checked': false, 'entryCount': 0},
        'leave': {'requestId': 9, 'reason': 'Ốm'},
      },
      {
        'child': {'id': 103, 'fullName': 'Phạm Khánh Linh'},
        'record': {'status': 'UNEXCUSED', 'meals': <String, Object?>{}},
        'health': {'checked': false, 'entryCount': 0},
      },
    ],
  };

  test('loadTeacherClasses_putsTaughtFirst', () async {
    final result = await loadTeacherClasses(
      ScriptedApi(session, {'GET /attendance/classes': (_) => classes}),
    );
    expect(result.map((c) => c.id), ['12', '3']);
    expect(result.first.canRecord, isTrue);
  });

  test(
    'loadTeacherClasses_withSchoolYearId_sendsQueryAndKeepsHistorical',
    () async {
      final api = ScriptedApi(session, {
        'GET /attendance/classes?schoolYearId=5': (_) => [
          {
            'id': 7,
            'name': 'Nhà trẻ 2',
            'teaches': false,
            'canRecord': false,
            'historicalReadOnly': true,
          },
        ],
      });
      final result = await loadTeacherClasses(api, schoolYearId: '5');
      expect(api.calls, ['GET /attendance/classes?schoolYearId=5']);
      expect(result.single.historicalReadOnly, isTrue);
      expect(result.single.canRecord, isFalse);
    },
  );

  test('loadRoster_withYear_sendsSchoolYearQuery', () async {
    final api = ScriptedApi(session, {
      'GET /children?classId=7&size=100&schoolYear=5': (_) => {'items': []},
      'GET /attendance/classes?schoolYearId=5': (_) => [
        {'id': 7, 'name': 'Nhà trẻ 2', 'historicalReadOnly': true},
      ],
    });
    final roster = await LiveClassRosterSource(
      api,
      schoolYearId: () => '5',
    ).loadRoster('7');
    expect(roster.className, 'Nhà trẻ 2');
  });

  group('attendance', () {
    test('loadSheet_mapsRowsAndDay', () async {
      final result = await LiveAttendanceSource(
        ScriptedApi(session, {'GET /classes/12/attendance': (_) => sheet()}),
      ).loadSheet('12');
      expect(result.classSummary.name, 'Mầm 3A');
      expect(result.classSummary.childCount, 3);
      expect(result.date, DateTime(2026, 11, 26));
      expect(result.lockAt, '08:30');
      expect(result.mealSessions, [MealSession.lunch, MealSession.afternoon]);
      expect(result.editable, isTrue);
      final first = result.kids[0];
      expect(first.status, AttendanceStatus.present);
      expect(first.meals, {
        MealSession.lunch: true,
        MealSession.afternoon: false,
      });
      expect(first.hasAllergy, isTrue);
      expect(first.health.noted, isTrue);
      expect(first.health.temperature, 37.8);
      final second = result.kids[1];
      expect(second.status, AttendanceStatus.notRecorded);
      expect(second.hasLeaveNotice, isTrue);
      expect(second.leave!.reason, 'Ốm');
      expect(second.leave!.part, DayPartCode.fullDay);
      expect(result.kids[2].status, AttendanceStatus.unexcused);
    });

    test('save_putsEntriesWithoutNotRecorded', () async {
      Object? sent;
      final api = ScriptedApi(session, {
        'PUT /classes/12/attendance': (body) {
          sent = body;
          return {'count': 2, 'changed': 2};
        },
      });
      await LiveAttendanceSource(api).save('12', DateTime(2026, 11, 26), [
        const KidAttendance(
          childId: '101',
          fullName: 'A',
          status: AttendanceStatus.present,
          meals: {MealSession.lunch: true},
        ),
        const KidAttendance(
          childId: '103',
          fullName: 'B',
          status: AttendanceStatus.unexcused,
        ),
        const KidAttendance(
          childId: '104',
          fullName: 'C',
          status: AttendanceStatus.notRecorded,
        ),
      ]);
      expect(sent, {
        'date': '2026-11-26',
        'entries': [
          {
            'childId': 101,
            'status': 'PRESENT',
            'meals': {'LUNCH': true},
          },
          {'childId': 103, 'status': 'UNEXCUSED'},
        ],
      });
    });

    test('save_propagatesApiFailure', () async {
      final api = ScriptedApi(session, {
        'PUT /classes/12/attendance': (_) => throw ApiFailure(409, 'Đã khóa'),
      });
      expect(
        LiveAttendanceSource(api).save('12', DateTime(2026, 11, 26), const [
          KidAttendance(
            childId: '101',
            fullName: 'A',
            status: AttendanceStatus.unexcused,
          ),
        ]),
        throwsA(isA<ApiFailure>()),
      );
    });

    test('save_allNotRecorded_skipsCallBecauseBeRejectsEmptyEntries', () async {
      final api = ScriptedApi(session, {});
      await LiveAttendanceSource(api).save('12', DateTime(2026, 11, 26), const [
        KidAttendance(
          childId: '104',
          fullName: 'C',
          status: AttendanceStatus.notRecorded,
        ),
      ]);
      expect(api.calls, isEmpty);
    });
  });

  group('daily health', () {
    test('loadSheet_onlyPresentKidsWithLatest', () async {
      final result = await LiveDailyHealthSource(
        ScriptedApi(session, {'GET /classes/12/attendance': (_) => sheet()}),
      ).loadSheet('12');
      expect(result.canRecord, isTrue);
      expect(result.kids.length, 1);
      final kid = result.kids.single;
      expect(kid.childId, '101');
      expect(kid.entryCount, 2);
      expect(kid.checked, isTrue);
      expect(kid.latest!.observation, HealthObservation.noted);
      expect(kid.latest!.temperature, 37.8);
      expect(kid.latest!.symptoms, [HealthSymptom.cough]);
    });

    test('save_postsRequestIdAndMapsResponse', () async {
      Map? sent;
      final api = ScriptedApi(session, {
        'POST /daily-health-entries': (body) {
          sent = body as Map;
          return {
            'id': 1,
            'requestId': 'req-1',
            'classId': 12,
            'childId': 101,
            'date': '2026-11-26',
            'temperature': 38.2,
            'observation': 'NOTED',
            'symptoms': ['FEVER'],
            'note': 'Sốt nhẹ',
            'actions': ['MONITOR'],
            'referral': {'place': 'Phòng y tế', 'time': '09:30'},
            'recordedAt': '2026-11-26T02:00:00Z',
          };
        },
      });
      final saved = await LiveDailyHealthSource(api).save(
        DailyHealthEntry(
          requestId: 'req-1',
          classId: '12',
          childId: '101',
          date: DateTime(2026, 11, 26),
          observation: HealthObservation.noted,
          temperature: 38.2,
          symptoms: const [HealthSymptom.fever],
          actions: const [HealthAction.monitor],
          note: 'Sốt nhẹ',
        ),
      );
      expect(sent!['requestId'], 'req-1');
      expect(sent!['classId'], 12);
      expect(sent!['date'], '2026-11-26');
      expect(sent!['observation'], 'NOTED');
      expect(sent!['symptoms'], ['FEVER']);
      expect(sent!.containsKey('referral'), isFalse);
      expect(saved.requestId, 'req-1');
      expect(saved.referral!.place, 'Phòng y tế');
      expect(saved.actions, [HealthAction.monitor]);
    });
  });

  group('class roster', () {
    test('loadRoster_mapsChildren', () async {
      final api = ScriptedApi(session, {
        'GET /children?classId=12&size=100': (_) => {
          'items': [
            {
              'id': 101,
              'fullName': 'Nguyễn Minh Anh',
              'dateOfBirth': '2022-03-14',
              'className': 'Mầm 3A',
              'status': 'PENDING_PLACEMENT',
              'allergies': ['hải sản'],
              'guardians': [
                {
                  'fullName': 'Trần Thu Lan',
                  'relation': 'MOTHER',
                  'phone': null,
                },
                {
                  'fullName': 'Nguyễn Văn Hùng',
                  'relation': 'FATHER',
                  'phone': '0900000001',
                },
              ],
            },
          ],
          'page': 0,
          'totalElements': 1,
        },
        'GET /attendance/classes': (_) => classes,
      });
      final roster = await LiveClassRosterSource(
        api,
        clock: () => DateTime(2026, 11, 26),
      ).loadRoster('12');
      expect(roster.className, 'Mầm 3A');
      expect(roster.campusName, '');
      final kid = roster.kids.single;
      expect(kid.ageLabel, '4 tuổi');
      expect(kid.dateOfBirth, DateTime(2022, 3, 14));
      expect(kid.status, RosterKidStatus.pendingPlacement);
      expect(kid.guardianLine, 'Bố: 0900000001');
      expect(kid.tag!.kind, RosterTagKind.allergy);
      expect(kid.tag!.label, 'Dị ứng hải sản');
    });
  });

  group('teacher home', () {
    Map<String, Object? Function(Object?)> routes() => {
      'GET /accounts/me': (_) => {'fullName': 'Trần Thu Hà'},
      'GET /attendance/classes': (_) => classes,
      'GET /classes/12/attendance': (_) => sheet(),
      'GET /leave-requests?classId=12': (_) => [
        {'id': 1},
        {'id': 2},
      ],
    };

    test('loadToday_mapsOriginalTasksFromBe', () async {
      final today = await LiveTeacherHomeSource(
        ScriptedApi(session, routes()),
      ).loadToday();
      expect(today.teacherName, 'Trần Thu Hà');
      expect(today.className, 'Mầm 3A');
      expect(today.childCount, 3);
      expect(today.deadlineNote, 'Hạn điểm danh: 08:30');
      expect(today.currentActivity, isNull);
      expect(today.attendanceRecorded, 2);
      expect(today.tasks.map((t) => t.kind), [
        TeacherTaskKind.attendance,
        TeacherTaskKind.dailyHealth,
        TeacherTaskKind.pickup,
        TeacherTaskKind.leave,
        TeacherTaskKind.review,
        TeacherTaskKind.menu,
        TeacherTaskKind.rewards,
      ]);
      expect(today.tasks[0].subtitle, '2/3 trẻ · trước 08:30');
      expect(today.tasks[0].badge, 'Cần làm');
      expect(today.tasks[3].subtitle, '2 đơn');
    });

    test('loadToday_leaveSourceFails_stillLoads', () async {
      final api = ScriptedApi(session, {
        'GET /accounts/me': (_) => {'fullName': 'Trần Thu Hà'},
        'GET /attendance/classes': (_) => classes,
        'GET /classes/12/attendance': (_) => sheet(),
      });
      final today = await LiveTeacherHomeSource(api).loadToday();
      expect(today.tasks, isNotEmpty);
    });

    test('loadToday_ctorClassId_picksThatClass', () async {
      final api = ScriptedApi(session, routes());
      await LiveTeacherHomeSource(api, classId: '12').loadToday();
      expect(api.calls, contains('GET /classes/12/attendance'));
    });

    test('loadToday_noTaughtClass_empty', () async {
      final api = ScriptedApi(session, {
        'GET /accounts/me': (_) => {'fullName': 'Trần Thu Hà'},
        'GET /attendance/classes': (_) => [classes.first],
      });
      final today = await LiveTeacherHomeSource(
        api,
        clock: () => DateTime(2026, 11, 26),
      ).loadToday();
      expect(today.className, isEmpty);
      expect(today.tasks, isEmpty);
    });

    test('loadToday_includesFirstTeachingActivityToday', () async {
      final api = ScriptedApi(session, {
        ...routes(),
        'GET /classes/12/teaching-activities?weekStart=2026-11-23': (_) => [
          {
            'date': '2026-11-26',
            'weekLabel': 'Tuần 13',
            'activities': [
              {'label': 'Hoạt động học', 'topic': 'Tạo hình: Tô màu chiếc lá'},
            ],
          },
        ],
      });
      final schedule = LiveActivityScheduleSource(
        api,
        clock: () => DateTime(2026, 11, 26),
      );
      final today = await LiveTeacherHomeSource(
        api,
        schedule: schedule,
        clock: () => DateTime(2026, 11, 26),
      ).loadToday();
      expect(
        today.currentActivity,
        'Hoạt động học · Tạo hình: Tô màu chiếc lá',
      );
    });
  });

  group('teacher read-only views', () {
    test('menu maps published meals of assigned class', () async {
      final api = ScriptedApi(session, {
        'GET /classes/12/menu?weekStart=2026-11-23': (_) => {
          'classId': 12,
          'className': 'Mầm 3A',
          'weekStart': '2026-11-23',
          'published': true,
          'days': [
            {
              'date': '2026-11-23',
              'dayOff': false,
              'meals': [
                {
                  'session': 'LUNCH',
                  'dishes': ['Cơm', 'Canh bí đỏ'],
                },
              ],
            },
          ],
        },
      });
      final week = await LiveTeacherMenuSource(
        api,
        clock: () => DateTime(2026, 11, 26),
      ).loadWeek('12');
      expect(week.groups.single, ('12', 'Mầm 3A'));
      expect(week.publishedNote, 'Đã công bố');
      expect(
        week.days[DateTime(2026, 11, 23)]!['12']!.meals.single.dishes,
        'Cơm · Canh bí đỏ',
      );
    });

    test('schedule maps approved teaching activities by day', () async {
      final api = ScriptedApi(session, {
        'GET /classes/12/teaching-activities?weekStart=2026-11-23': (_) => [
          {
            'date': '2026-11-26',
            'weekLabel': 'Tuần 13',
            'activities': [
              {
                'key': 'hoc',
                'label': 'Hoạt động học',
                'topic': 'Tạo hình: Tô màu chiếc lá',
              },
            ],
          },
        ],
      });
      final week = await LiveActivityScheduleSource(
        api,
        clock: () => DateTime(2026, 11, 26),
      ).loadWeek('12');
      expect(week.theme, 'Tuần 13');
      expect(week.days[DateTime.thursday]!.single.title, 'Hoạt động học');
      expect(
        week.days[DateTime.thursday]!.single.detail,
        'Tạo hình: Tô màu chiếc lá',
      );
    });
  });
}

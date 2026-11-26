import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/teacher/attendance/data/live_attendance_source.dart';
import 'package:carenest_app/features/teacher/attendance/data/live_attendance_summary_source.dart';
import 'package:carenest_app/features/teacher/attendance/domain/attendance.dart';
import 'package:carenest_app/features/teacher/daily_health/data/live_daily_health_source.dart';
import 'package:carenest_app/features/teacher/daily_health/domain/daily_health.dart';

import '../../../helpers/live_fakes.dart';

void main() {
  late FakeLiveSession session;
  setUp(() => session = FakeLiveSession(['TEACHER']));

  Map<String, Object?> sheet() => {
    'day': {
      'date': '2026-11-25',
      'today': '2026-11-26',
      'cutoff': '08:30',
      'schoolDay': true,
      'locked': true,
    },
    'className': 'Mầm 3A',
    'mealSessions': ['LUNCH', 'AFTERNOON'],
    'canRecord': true,
    'children': [
      {
        'child': {
          'id': 1,
          'fullName': 'A',
          'hasAllergy': true,
          'mealRegistered': false,
        },
        'record': {
          'status': 'PRESENT',
          'absentPart': 'MORNING',
          'meals': {'AFTERNOON': true},
        },
        'health': {'checked': true, 'observation': 'NOTED'},
        'leave': {
          'fromDate': '2026-11-25',
          'toDate': '2026-11-25',
          'reason': 'Khám',
          'part': 'MORNING',
          'eats': true,
          'eatsMeals': ['AFTERNOON'],
          'noticeOnly': false,
        },
      },
    ],
  };

  group('attendance', () {
    test('loadSheet_withDate_sendsQueryAndMapsDayAndLeave', () async {
      final api = ScriptedApi(session, {
        'GET /classes/12/attendance?date=2026-11-25': (_) => sheet(),
      });
      final result = await LiveAttendanceSource(
        api,
      ).loadSheet('12', date: DateTime(2026, 11, 25));
      expect(result.today, DateTime(2026, 11, 26));
      expect(result.locked, isTrue);
      expect(result.editable, isFalse);
      final kid = result.kids.single;
      expect(kid.mealRegistered, isFalse);
      expect(kid.hasAllergy, isTrue);
      expect(kid.absentPart, DayPartCode.morning);
      expect(kid.presentPart, DayPartCode.afternoon);
      expect(kid.leave!.part, DayPartCode.morning);
      expect(kid.leave!.isHalfDay, isTrue);
      expect(kid.leave!.eatsMeals, [MealSession.afternoon]);
      expect(kid.health.noted, isTrue);
    });

    test('loadSheet_withoutDate_omitsQuery', () async {
      final api = ScriptedApi(session, {
        'GET /classes/12/attendance': (_) => sheet(),
      });
      await LiveAttendanceSource(api).loadSheet('12');
      expect(api.calls, ['GET /classes/12/attendance']);
    });
  });

  group('daily health', () {
    test('loadSheet_withDate_sendsQuery', () async {
      final api = ScriptedApi(session, {
        'GET /classes/12/attendance?date=2026-11-25': (_) => sheet(),
      });
      final result = await LiveDailyHealthSource(
        api,
      ).loadSheet('12', date: DateTime(2026, 11, 25));
      // Ngày xem khác hôm nay ⇒ chỉ xem dù BE cho lớp ghi
      expect(result.canRecord, isFalse);
    });

    test('loadChildDay_mapsEntriesAndRecorder', () async {
      final api = ScriptedApi(session, {
        'GET /classes/12/children/5/daily-health?date=2026-11-25': (_) => {
          'canRecord': false,
          'handedOverAt': '2026-11-25T03:15:00Z',
          'entries': [
            {
              'requestId': 'r1',
              'date': '2026-11-25',
              'temperature': 38.1,
              'observation': 'NOTED',
              'symptoms': ['FEVER'],
              'actions': ['MONITOR'],
              'recordedByName': 'Cô Lan',
              'recordedAt': '2026-11-25T01:00:00Z',
            },
          ],
        },
      });
      final day = await LiveDailyHealthSource(
        api,
      ).loadChildDay('12', '5', date: DateTime(2026, 11, 25));
      expect(day.canRecord, isFalse);
      expect(day.handedOverAt, isNotNull);
      final entry = day.entries.single;
      expect(entry.observation, HealthObservation.noted);
      expect(entry.recordedByName, 'Cô Lan');
      expect(entry.actions, [HealthAction.monitor]);
    });
  });

  group('summary', () {
    test('load_sendsRangeAndMapsRows', () async {
      final api = ScriptedApi(session, {
        'GET /classes/12/attendance/summary?from=2026-11-01&to=2026-11-26':
            (_) => {
              'className': 'Mầm 3A',
              'from': '2026-11-01',
              'to': '2026-11-26',
              'size': 28,
              'mealSessions': ['LUNCH'],
              'days': [
                {
                  'date': '2026-11-25',
                  'present': 24,
                  'excused': 2,
                  'unexcused': 1,
                  'missing': 1,
                  'mealTotal': 22,
                  'meals': {'LUNCH': 22},
                  'morningOff': 1,
                  'afternoonOff': 0,
                },
              ],
              'children': [
                {
                  'child': {'id': 1, 'fullName': 'A'},
                  'attendedDays': 12.5,
                  'excused': 1,
                  'unexcused': 0,
                  'meals': 12,
                  'mealCounts': {'LUNCH': 12},
                  'morningOff': 1,
                  'afternoonOff': 0,
                },
              ],
            },
      });
      final summary = await LiveAttendanceSummarySource(
        api,
      ).load('12', from: DateTime(2026, 11), to: DateTime(2026, 11, 26));
      expect(summary.size, 28);
      expect(summary.days.single.present, 24);
      expect(summary.days.single.meals[MealSession.lunch], 22);
      expect(summary.children.single.attendedDays, 12.5);
      expect(summary.children.single.mealDays, 12);
    });
  });
}

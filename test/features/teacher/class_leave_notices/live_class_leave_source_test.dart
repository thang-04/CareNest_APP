import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/teacher/class_leave_notices/data/live_class_leave_source.dart';
import 'package:carenest_app/features/teacher/class_leave_notices/domain/class_leave_notice.dart';

import '../../../helpers/live_fakes.dart';

void main() {
  test('load_mapsActiveAndCancelledEntries', () async {
    final api = ScriptedApi(FakeLiveSession(['TEACHER']), {
      'GET /leave-requests?classId=12&from=2026-11-01&to=2027-01-24': (_) => [
        {
          'id': 1,
          'childId': 5,
          'childName': 'Nguyễn Minh Anh',
          'fromDate': '2026-11-11',
          'toDate': '2026-11-13',
          'effectiveTo': '2026-11-12',
          'reason': 'Bé ốm',
          'status': 'ACTIVE',
          'className': 'Mầm 3A',
          'part': 'AFTERNOON',
          'eats': false,
          'eatsMeals': ['LUNCH'],
          'noticeOnly': true,
          'createdByName': 'Trần Thu Lan',
          'createdAt': '2026-11-10T13:10:00Z',
          'cancelledAt': null,
          'appliedDates': ['2026-11-12'],
          'skippedDates': ['2026-11-11'],
        },
        {
          'id': 2,
          'childId': 6,
          'childName': 'Lê Hoàng Nam',
          'fromDate': '2026-11-16',
          'toDate': '2026-11-16',
          'reason': 'Việc nhà',
          'status': 'CANCELLED',
          'createdByName': 'Lê Thị Mai',
          'createdAt': '2026-11-09T12:00:00Z',
          'cancelledAt': '2026-11-11T01:00:00Z',
          'appliedDates': <Object>[],
          'skippedDates': <Object>[],
        },
      ],
    });

    final entries = await LiveClassLeaveSource(
      api,
      clock: () => DateTime(2026, 11, 25),
    ).load('12');

    expect(entries, hasLength(2));
    expect(entries[0].id, '1');
    expect(entries[0].status, LeaveRequestStatus.active);
    expect(entries[0].effectiveTo, DateTime(2026, 11, 12));
    expect(entries[0].appliedDates, [DateTime(2026, 11, 12)]);
    expect(entries[0].skippedDates, [DateTime(2026, 11, 11)]);
    expect(entries[0].part, LeavePart.afternoon);
    expect(entries[0].eats, isFalse);
    expect(entries[0].eatsMeals, ['LUNCH']);
    expect(entries[0].noticeOnly, isTrue);
    expect(entries[0].className, 'Mầm 3A');
    expect(entries[1].part, LeavePart.fullDay);
    expect(entries[1].noticeOnly, isFalse);
    expect(entries[1].status, LeaveRequestStatus.cancelled);
    expect(entries[1].cancelledAt, isNotNull);
    expect(entries[1].effectiveTo, isNull);
  });

  test('load_sendsChosenRange', () async {
    final api = ScriptedApi(FakeLiveSession(['TEACHER']), {
      'GET /leave-requests?classId=12&from=2026-10-05&to=2026-10-20': (_) =>
          <Object>[],
    });

    final entries = await LiveClassLeaveSource(
      api,
    ).load('12', from: DateTime(2026, 10, 5), to: DateTime(2026, 10, 20));

    expect(entries, isEmpty);
  });
}

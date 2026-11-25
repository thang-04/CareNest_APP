import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/parent/parent_home/data/live_parent_home_source.dart';
import 'package:carenest_app/features/parent/parent_home/domain/parent_today.dart';

import '../../../helpers/live_fakes.dart';

void main() {
  late FakeLiveSession session;
  late ScriptedApi api;

  setUp(() {
    session = FakeLiveSession(['PARENT'], childIds: [5, 3]);
    session.account!['fullName'] = 'Nguyễn Thu Lan';
    api = ScriptedApi(session, {
      'GET /children/5/profile': (_) => profileJson(5, 'Nguyễn Minh Anh'),
      'GET /children/3/profile': (_) =>
          profileJson(3, 'Nguyễn Bảo Ngọc', className: 'Lá 1'),
      'GET /me/notifications': (_) => {'unreadCount': 4, 'items': <Object>[]},
    });
  });

  test('loadChildren_mapsProfilesInAccountOrder', () async {
    final children = await LiveParentHomeSource(api, session).loadChildren();

    expect(children.map((c) => c.id), ['5', '3']);
    expect(children.first.fullName, 'Nguyễn Minh Anh');
    expect(children.first.shortName, 'Minh Anh');
    expect(children.last.className, 'Lá 1');
    // Quyết định 2 (user 25/11): BE chưa có ⇒ ẩn
    expect(children.first.campusName, isNull);
    expect(children.first.ageLabel, isNull);
    expect(children.first.homeroomTeacher, isNull);
  });

  test('loadChildren_cachedPerSession', () async {
    final source = LiveParentHomeSource(api, session);
    await source.loadChildren();
    await source.loadChildren();
    expect(api.calls.where((c) => c.endsWith('/profile')), hasLength(2));
  });

  test('loadToday_mapsAllSixStatuses', () async {
    const expected = {
      'PRESENT': ParentAttendanceStatus.present,
      'ABSENT_EXCUSED': ParentAttendanceStatus.absentExcused,
      'ABSENT': ParentAttendanceStatus.absentUnexcused,
      'NOT_RECORDED': ParentAttendanceStatus.notRecorded,
      'NO_SCHOOL': ParentAttendanceStatus.noSchool,
      'NOT_ENROLLED': ParentAttendanceStatus.notEnrolled,
    };
    for (final entry in expected.entries) {
      api.routes['GET /children/5/attendance/today'] = (_) => {
        'date': '2026-11-25',
        'status': entry.key,
        'absentPart': null,
        'arrivedAt': entry.key == 'PRESENT' ? '2026-11-25T00:42:00Z' : null,
        'classId': 12,
        'className': 'Mầm 3A',
      };
      final today = await LiveParentHomeSource(api, session).loadToday('5');
      expect(today.attendance, entry.value, reason: entry.key);
    }
  });

  test('loadToday_mapsGreetingArrivalAndUnread', () async {
    api.routes['GET /children/5/attendance/today'] = (_) => {
      'date': '2026-11-25',
      'status': 'PRESENT',
      'absentPart': 'AFTERNOON',
      'arrivedAt': '2026-11-25T00:42:00Z',
      'classId': 12,
      'className': 'Mầm 3A',
    };

    final today = await LiveParentHomeSource(api, session).loadToday('5');

    expect(today.greetingName, 'Nguyễn Thu Lan');
    expect(today.date, DateTime(2026, 11, 25));
    expect(today.arrivedAt, DateTime.utc(2026, 11, 25, 0, 42).toLocal());
    expect(today.absentPart, AbsentPart.afternoon);
    expect(today.unreadNotifications, 4);
    expect(today.child.fullName, 'Nguyễn Minh Anh');
    expect(today.menuPublished, isFalse);
    expect(today.activityTitle, isNull);
  });

  test('loadToday_403_keepsBeMessage', () async {
    api.routes['GET /children/5/attendance/today'] = (_) =>
        throw ApiFailure(403, 'Bạn chỉ xem được thông tin của con mình', 4108);

    await expectLater(
      LiveParentHomeSource(api, session).loadToday('5'),
      throwsA(isA<ApiFailure>().having((e) => e.status, 'status', 403)),
    );
  });
}

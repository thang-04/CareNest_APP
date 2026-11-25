import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/storage/last_mode_store.dart';
import 'package:carenest_app/core/widgets/app_coming_soon.dart';
import 'package:carenest_app/features/auth/presentation/screens/activation_screen.dart';
import 'package:carenest_app/features/parent/leave_notice/presentation/screens/leave_notice_list_screen.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/parent/parent_home/presentation/screens/parent_home_screen.dart';
import 'package:carenest_app/features/parent/parent_home/presentation/selected_child.dart';
import 'package:carenest_app/features/shared/notifications/presentation/screens/notification_detail_screen.dart';
import 'package:carenest_app/features/teacher/teacher_home/presentation/screens/teacher_home_screen.dart';
import 'package:carenest_app/routing/app_router.dart';
import 'package:carenest_app/routing/route_paths.dart';

import '../helpers/live_fakes.dart';

void main() {
  tearDown(SelectedChild.reset);

  testWidgets('live_teacher_landsOnNotifications_thenHomeTabShowsTeacherHome', (
    tester,
  ) async {
    await pumpLiveApp(tester, FakeLiveSession(['TEACHER']));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Chưa có thông báo'), findsOneWidget);

    await tester.tap(find.text('Trang chủ').last);
    await tester.pumpAndSettle();
    expect(find.byType(TeacherHomeScreen), findsOneWidget);
  });

  /// Phụ huynh 1 con (ID 5) với API giả đủ cho Trang chủ, đơn nghỉ.
  ScriptedApi parentApi(FakeLiveSession session) => ScriptedApi(session, {
    'GET /children/5/profile': (_) => profileJson(5, 'Nguyễn Minh Anh'),
    'GET /children/5/attendance/today': (_) => {
      'date': '2026-11-25',
      'status': 'NOT_RECORDED',
      'classId': 12,
      'className': 'Mầm 3A',
    },
    'GET /me/notifications': (_) => {'unreadCount': 0, 'items': <Object>[]},
    'GET /leave-requests/me': (_) => <Object>[],
  });

  /// Điểm danh tháng hiện tại của bé 5: khoảng từ ngày 1 tới hôm nay (giờ máy).
  void addAttendance(ScriptedApi api) {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final range =
        'from=${now.year}-${two(now.month)}-01'
        '&to=${now.year}-${two(now.month)}-${two(now.day)}';
    api.routes['GET /children/5/attendance?$range'] = (_) => {
      'days': <Object>[],
      'totals': {'schoolDays': 3, 'present': 2.5, 'excused': 0.5, 'absent': 0},
    };
    api.routes['GET /children/5/daily-health/parent?$range'] = (_) =>
        <Object>[];
  }

  testWidgets('live_parentChildRoute_opens', (tester) async {
    final session = FakeLiveSession(['PARENT'], childIds: [5]);
    await pumpLiveApp(
      tester,
      session,
      api: parentApi(session),
      location: RoutePaths.withChild(RoutePaths.parentLeaveNotices, '5'),
    );
    expect(find.byType(LeaveNoticeListScreen), findsOneWidget);
  });

  testWidgets('live_parentChildRoute_unknownChild_notFound', (tester) async {
    final session = FakeLiveSession(['PARENT'], childIds: [5]);
    await pumpLiveApp(
      tester,
      session,
      api: parentApi(session),
      location: RoutePaths.withChild(RoutePaths.parentLeaveNotices, '999'),
    );
    expect(find.byType(LeaveNoticeListScreen), findsNothing);
    expect(find.byType(NotFoundScreen), findsOneWidget);
  });

  testWidgets('live_parentHome_showsRealChild', (tester) async {
    final session = FakeLiveSession(['PARENT'], childIds: [5]);
    await pumpLiveApp(
      tester,
      session,
      api: parentApi(session),
      location: RoutePaths.parentToday,
    );
    expect(find.textContaining('Minh Anh'), findsWidgets);
    expect(find.textContaining('Cơ sở'), findsNothing);
  });

  testWidgets('live_parentHome_menuAndActivityComingSoon', (tester) async {
    final session = FakeLiveSession(['PARENT'], childIds: [5]);
    await pumpLiveApp(
      tester,
      session,
      api: parentApi(session),
      location: RoutePaths.parentToday,
    );
    expect(find.bySemanticsLabel('Thực đơn: Sắp có'), findsOneWidget);
  });

  for (final path in [RoutePaths.parentMenu, RoutePaths.parentActivities]) {
    testWidgets('live_parentNoApiRoute_showsComingSoon $path', (tester) async {
      final session = FakeLiveSession(['PARENT'], childIds: [5]);
      await pumpLiveApp(
        tester,
        session,
        api: parentApi(session),
        location: RoutePaths.withChild(path, '5'),
      );
      // Q1: chưa có API ở BE ⇒ không hiện thực đơn/hoạt động giả
      expect(find.byType(AppComingSoon), findsOneWidget);
    });
  }

  testWidgets('live_myChildTab_showsBeProfile', (tester) async {
    final session = FakeLiveSession(['PARENT'], childIds: [5]);
    await pumpLiveApp(
      tester,
      session,
      api: parentApi(session),
      location: RoutePaths.parentChild,
    );
    expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
    // Hồ sơ giả có "Năm học 2026–2027"; BE chưa trả tên năm học
    expect(find.textContaining('Năm học'), findsNothing);
  });

  testWidgets('live_parentAttendance_showsBeTotals', (tester) async {
    final session = FakeLiveSession(['PARENT'], childIds: [5]);
    final api = parentApi(session);
    addAttendance(api);
    await pumpLiveApp(
      tester,
      session,
      api: api,
      location: RoutePaths.withChild(RoutePaths.parentAttendance, '5'),
    );
    expect(find.bySemanticsLabel('Có mặt: 2,5'), findsOneWidget);
  });

  testWidgets('live_otherRolePath_goesOwnHome', (tester) async {
    await pumpLiveApp(
      tester,
      FakeLiveSession(['TEACHER']),
      location: RoutePaths.withChild(
        RoutePaths.parentLeaveNotices,
        FakeParentHomeSource.children.first.id,
      ),
    );
    expect(find.byType(LeaveNoticeListScreen), findsNothing);
    expect(find.byType(TeacherHomeScreen), findsOneWidget);
  });

  testWidgets('live_pushDeepLink_opensDetail', (tester) async {
    await pumpLiveApp(
      tester,
      FakeLiveSession(['TEACHER']),
      location: '/live/notifications/7',
    );
    expect(find.byType(NotificationDetailScreen), findsOneWidget);
  });

  testWidgets('live_signOut_resetsSelectedChild', (tester) async {
    final session = FakeLiveSession(['PARENT'], childIds: [1]);
    await pumpLiveApp(tester, session);
    SelectedChild.notifier.value = FakeParentHomeSource.children.last.id;

    await tester.tap(find.text('Tài khoản').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng xuất').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng xuất').last);
    await tester.pumpAndSettle();

    expect(session.signedOut, isTrue);
    expect(
      SelectedChild.notifier.value,
      FakeParentHomeSource.children.first.id,
    );
    expect(find.byType(NavigationBar), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('live_teacherParent_switchToParent_opensParentShell', (
    tester,
  ) async {
    await pumpLiveApp(
      tester,
      FakeLiveSession(['TEACHER', 'PARENT'], childIds: [1]),
      location: RoutePaths.teacherAccount,
    );
    expect(find.text('Chuyển sang chế độ phụ huynh'), findsOneWidget);

    await tester.tap(find.text('Chuyển sang chế độ phụ huynh'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byType(ParentHomeScreen), findsOneWidget);
    expect(find.byType(TeacherHomeScreen), findsNothing);
  });

  testWidgets('liveLogin_activateLink_opensActivation', (tester) async {
    final session = FakeLiveSession(['PARENT']);
    await session.signOut();
    await pumpLiveApp(tester, session, location: RoutePaths.login);

    await tester.tap(find.text('Kích hoạt tài khoản'));
    await tester.pumpAndSettle();

    expect(find.byType(ActivationScreen), findsOneWidget);
  });

  testWidgets('live_parentWithoutPortrait_opensApp', (tester) async {
    // User chốt 13/11: App không buộc cập nhật ảnh chân dung khi đăng nhập
    await pumpLiveApp(
      tester,
      FakeLiveSession(['PARENT'], childIds: [1], photoMissing: true),
    );
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Cập nhật ảnh chân dung'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('liveLogin_expired_showsNotice', (tester) async {
    final session = FakeLiveSession(['TEACHER']);
    await session.signOut();
    session.expired = true;
    await pumpLiveApp(tester, session, location: RoutePaths.login);

    expect(
      find.text('Phiên đăng nhập đã hết. Vui lòng đăng nhập lại.'),
      findsOneWidget,
    );
  });

  testWidgets('live_sessionExpiresWhileUsing_goesLogin', (tester) async {
    final session = FakeLiveSession(['TEACHER']);
    await pumpLiveApp(tester, session);

    session.expired = true;
    await session.signOut();
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(
      find.text('Phiên đăng nhập đã hết. Vui lòng đăng nhập lại.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('live_storedParentMode_pushLinkWaitsForMode', (tester) async {
    final store = SlowSecureStore({'carenest.test.last_mode.4': 'parent'});
    final router = await pumpLiveApp(
      tester,
      FakeLiveSession(['TEACHER', 'PARENT'], childIds: [1]),
      location: '/live/notifications/7',
      modeStore: LastModeStore(store, env: 'test'),
    );

    store.release();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/parent/notifications/7',
    );
    expect(find.byType(NotificationDetailScreen), findsOneWidget);
  });

  testWidgets('live_parentNoChild_onlyTeacher_noSwitch', (tester) async {
    await pumpLiveApp(
      tester,
      FakeLiveSession(['TEACHER', 'PARENT']),
      location: RoutePaths.teacherAccount,
    );
    expect(find.textContaining('Chuyển sang chế độ'), findsNothing);
  });
}

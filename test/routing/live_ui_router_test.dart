import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/parent/leave_notice/presentation/screens/leave_notice_list_screen.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/parent/parent_home/presentation/screens/parent_home_screen.dart';
import 'package:carenest_app/features/parent/parent_home/presentation/selected_child.dart';
import 'package:carenest_app/features/shared/notifications/presentation/screens/notification_detail_screen.dart';
import 'package:carenest_app/features/teacher/teacher_home/presentation/screens/teacher_home_screen.dart';
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

  testWidgets('live_parentChildRoute_opens', (tester) async {
    await pumpLiveApp(
      tester,
      FakeLiveSession(['PARENT'], childIds: [1]),
      location: RoutePaths.withChild(
        RoutePaths.parentLeaveNotices,
        FakeParentHomeSource.children.first.id,
      ),
    );
    expect(find.byType(LeaveNoticeListScreen), findsOneWidget);
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

  testWidgets('live_parentNoChild_onlyTeacher_noSwitch', (tester) async {
    await pumpLiveApp(
      tester,
      FakeLiveSession(['TEACHER', 'PARENT']),
      location: RoutePaths.teacherAccount,
    );
    expect(find.textContaining('Chuyển sang chế độ'), findsNothing);
  });
}

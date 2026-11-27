import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/parent/school_year/presentation/parent_selected_year.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
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
    'GET /me/notifications?limit=1': (_) => {
      'unreadCount': 0,
      'items': <Object>[],
    },
    'GET /leave-requests/me': (_) => <Object>[],
    // Năm đang chạy phủ hôm nay (giờ máy) ⇒ khoảng ngày như trước khi có ô Năm học
    'GET /children/5/school-years': (_) {
      final now = DateTime.now();
      String day(DateTime d) => d.toIso8601String().substring(0, 10);
      return [
        {
          'schoolYearId': 3,
          'name': '2026-2027',
          'startDate': day(now.subtract(const Duration(days: 400))),
          'endDate': day(now.add(const Duration(days: 200))),
          'status': 'ACTIVE',
          'className': 'Mầm 3A',
        },
      ];
    },
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

  testWidgets('live_parentActivities_usesBe (EDU-37)', (tester) async {
    final session = FakeLiveSession(['PARENT'], childIds: [5]);
    final api = parentApi(session);
    api.routes['GET /children/5/activities'] = (_) => {
      'date': '2026-11-24',
      'activities': [
        {
          'label': 'Hoạt động học',
          'items': ['Bật xa'],
        },
      ],
    };
    await pumpLiveApp(
      tester,
      session,
      api: api,
      location: RoutePaths.withChild(RoutePaths.parentActivities, '5'),
    );
    expect(find.text('Bật xa'), findsOneWidget);
  });

  testWidgets('live_parentHome_menuStatusFromBe (PAR-14)', (tester) async {
    final session = FakeLiveSession(['PARENT'], childIds: [5]);
    final api = parentApi(session)
      ..routes['GET /children/5/menu'] = (_) => {'published': true};
    await pumpLiveApp(
      tester,
      session,
      api: api,
      location: RoutePaths.parentToday,
    );
    expect(find.bySemanticsLabel('Thực đơn: Đã công bố'), findsOneWidget);
  });

  testWidgets('live_parentMenu_loadsWeekFromBe (PAR-14)', (tester) async {
    final session = FakeLiveSession(['PARENT'], childIds: [5]);
    final api = parentApi(session)
      ..routes['GET /children/5/menu'] = (_) => {
        'weekStart': '2026-11-23',
        'published': false,
        'days': <Object>[],
      };
    await pumpLiveApp(
      tester,
      session,
      api: api,
      location: RoutePaths.withChild(RoutePaths.parentMenu, '5'),
    );
    expect(find.byType(AppComingSoon), findsNothing);
    expect(find.text('Thực đơn tuần này chưa công bố'), findsOneWidget);
  });

  testWidgets('live_myChildTab_showsBeProfile', (tester) async {
    final session = FakeLiveSession(['PARENT'], childIds: [5]);
    await pumpLiveApp(
      tester,
      session,
      api: parentApi(session),
      location: RoutePaths.parentChild,
    );
    expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
    // Năm học chỉ ở ô Năm học (từ BE); hồ sơ không tự ghi năm học như bản giả
    expect(find.textContaining('Năm học'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ParentYearChip),
        matching: find.text('Năm học 2026–2027'),
      ),
      findsOneWidget,
    );
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

  testWidgets('live_parentEvaluation_usesBe', (tester) async {
    final session = FakeLiveSession(['PARENT'], childIds: [5]);
    final api = parentApi(session);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eightWeeks = today.subtract(Duration(days: today.weekday - 1 + 49));
    final previousMonth = DateTime(today.year, today.month - 1);
    final from = previousMonth.isBefore(eightWeeks)
        ? previousMonth
        : eightWeeks;
    String day(DateTime d) => d.toIso8601String().substring(0, 10);
    api.routes['GET /children/5/daily-assessments'
        '?from=${day(from)}&to=${day(today)}'] = (_) =>
        <Object>[];
    api.routes['GET /children/5/weekly-comments?schoolYearId=3'] = (_) =>
        <Object>[];
    api.routes['GET /children/5/evaluations?schoolYearId=3'] = (_) => {
      'themes': <Object>[],
      'semesters': <Object>[],
      'yearEnd': null,
    };
    await pumpLiveApp(
      tester,
      session,
      api: api,
      location: RoutePaths.withChild(RoutePaths.parentEvaluation, '5'),
    );
    // Bản giả có đánh giá ngày; BE trả rỗng ⇒ trạng thái trống
    expect(find.text('Chưa có đánh giá ngày'), findsOneWidget);
  });

  testWidgets('live_parentRewards_usesBe', (tester) async {
    final session = FakeLiveSession(['PARENT'], childIds: [5]);
    final api = parentApi(session);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eightWeeks = today.subtract(Duration(days: today.weekday - 1 + 49));
    final previousMonth = DateTime(today.year, today.month - 1);
    final from = previousMonth.isBefore(eightWeeks)
        ? previousMonth
        : eightWeeks;
    String day(DateTime d) => d.toIso8601String().substring(0, 10);
    api.routes['GET /children/5/rewards?from=${day(from)}&to=${day(today)}'] =
        (_) => {
          'flags': <Object>[],
          'tickets': <Object>[],
          'yearEndTitles': <Object>[],
        };
    await pumpLiveApp(
      tester,
      session,
      api: api,
      location: RoutePaths.withChild(RoutePaths.parentRewards, '5'),
    );
    // Q2: BE chưa trả ngưỡng ⇒ không có nút giải thích (bản giả có)
    expect(find.text('Khen thưởng'), findsWidgets);
    expect(find.byTooltip('Cách bé nhận khen thưởng'), findsNothing);
  });

  testWidgets('live_parentHealthBook_usesBe', (tester) async {
    final session = FakeLiveSession(['PARENT'], childIds: [5]);
    final api = parentApi(session);
    api.routes['GET /children/5/health/published?schoolYearId=3'] = (_) => {
      'results': <Object>[],
      'growth': <Object>[],
      'interpretation': null,
    };
    await pumpLiveApp(
      tester,
      session,
      api: api,
      location: RoutePaths.withChild(RoutePaths.parentHealthBook, '5'),
    );
    expect(
      api.calls,
      contains('GET /children/5/health/published?schoolYearId=3'),
    );
  });

  testWidgets('live_kitchenHome_usesBeCounts', (tester) async {
    final session = FakeLiveSession(['KITCHEN_STAFF']);
    final api = ScriptedApi(session, {
      'GET /nutrition/kitchen/day': (_) => {
        'date': '2026-11-25',
        'dayOff': false,
        'countStatus': 'CONFIRMED',
        'confirmedAt': '2026-11-25T01:30:00Z',
        'menu': <Object>[],
        'servings': <Object>[],
        'foods': <Object>[],
      },
      'GET /meal-counts': (_) => {
        'today': '2026-11-25',
        'counts': [
          {
            'session': 'LUNCH',
            'status': 'CONFIRMED',
            'needsReconfirmation': false,
            'totals': {'normal': 139, 'substitute': 0},
          },
        ],
      },
      'GET /nutrition/meal-photo-windows': (_) => <Object>[],
      'GET /nutrition/meal-photos?date=2026-11-25': (_) => <Object>[],
      'GET /nutrition/food-samples?from=2026-10-26&to=2026-11-25': (_) =>
          <Object>[],
      'GET /me/notifications': (_) => {'unreadCount': 0, 'items': <Object>[]},
    });
    await pumpLiveApp(
      tester,
      session,
      api: api,
      location: RoutePaths.kitchenHome,
    );
    expect(api.calls, contains('GET /nutrition/kitchen/day'));
    // Bản giả có bữa trưa 182 suất; BE trả 139
    expect(find.text('139'), findsOneWidget);
    expect(find.text('182'), findsNothing);
  });

  testWidgets('live_kitchenMeals_forbidden_showsError', (tester) async {
    final session = FakeLiveSession(['KITCHEN_STAFF']);
    await pumpLiveApp(
      tester,
      session,
      api: ScriptedApi(session, {
        'GET /nutrition/kitchen/day': (_) =>
            throw ApiFailure(403, 'Tài khoản chưa được phân công bếp', 6063),
        'GET /meal-counts': (_) => const <String, Object?>{},
      }),
      location: RoutePaths.kitchenMeals,
    );
    expect(find.text('Tài khoản chưa được phân công bếp'), findsOneWidget);
  });

  testWidgets('live_accountProfile_readOnly_passwordIsRequestLater', (
    tester,
  ) async {
    final session = FakeLiveSession(['KITCHEN_STAFF']);
    await pumpLiveApp(tester, session, location: RoutePaths.kitchenAccount);
    expect(find.text('Yêu cầu cấp lại mật khẩu'), findsOneWidget);

    await tester.tap(find.text('Thông tin cá nhân'));
    await tester.pumpAndSettle();
    expect(find.text('Tên đăng nhập'), findsOneWidget);
    expect(find.text('Người Dùng Thử'), findsOneWidget);
    expect(find.text('Lưu thay đổi'), findsNothing);
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

  testWidgets('live_parentNotification_actionOpensChildScreen (PAR-07)', (
    tester,
  ) async {
    final session = FakeLiveSession(['PARENT'], childIds: [5]);
    final api = parentApi(session);
    api.routes['POST /me/notifications/7/read'] = (_) => null;
    api.routes['GET /me/notifications/7'] = (_) => {
      'id': 7,
      'type': 'HEALTH_RESULT_PUBLISHED',
      'typeLabel': 'Sức khỏe',
      'title': 'Có kết quả cân đo mới',
      'childId': 5,
      'createdAt': '2026-11-25T02:00:00Z',
      'readAt': '2026-11-25T02:00:00Z',
    };
    api.routes['GET /children/5/health/published?schoolYearId=3'] = (_) => {
      'results': <Object>[],
      'growth': <Object>[],
    };
    await pumpLiveApp(
      tester,
      session,
      api: api,
      location: '${RoutePaths.parentNotifications}/7',
    );
    expect(find.text('Xem sổ sức khỏe'), findsOneWidget);
    await tester.tap(find.text('Xem sổ sức khỏe'));
    await tester.pumpAndSettle();
    expect(
      api.calls,
      contains('GET /children/5/health/published?schoolYearId=3'),
    );
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
      location: RoutePaths.teacherToday,
    );
    // G94-385: nút đổi chế độ chỉ ở Trang chủ
    await tester.tap(find.text('Phụ huynh').first);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byType(ParentHomeScreen), findsOneWidget);
    expect(find.byType(TeacherHomeScreen), findsNothing);

    await tester.tap(find.text('Giáo viên').first);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(TeacherHomeScreen), findsOneWidget);
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

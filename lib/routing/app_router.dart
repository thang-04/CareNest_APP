import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/integration/mobile_session.dart';
import 'package:carenest_app/core/config/env.dart';
import 'package:carenest_app/core/storage/last_mode_store.dart';
import 'package:carenest_app/core/storage/secure_store.dart';
import 'package:carenest_app/features/auth/data/activation_api.dart';
import 'package:carenest_app/features/auth/data/live_mode_controller.dart';
import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/layouts/app_shell.dart';
import 'package:carenest_app/core/widgets/app_coming_soon.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/shared/account/data/fake_account_source.dart';
import 'package:carenest_app/features/shared/account/data/live_account_source.dart';
import 'package:carenest_app/features/auth/presentation/screens/live_login_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/unsupported_role_screen.dart';
import 'package:carenest_app/features/shared/notifications/data/fake_notification_source.dart';
import 'package:carenest_app/features/shared/notifications/data/live_notification_source.dart';
import 'package:carenest_app/features/shared/notifications/domain/app_notification.dart';
import 'package:carenest_app/features/shared/account/domain/account_profile.dart';
import 'package:carenest_app/features/shared/account/presentation/screens/account_screen.dart';
import 'package:carenest_app/features/shared/account/presentation/screens/personal_info_screen.dart';
import 'package:carenest_app/features/teacher/activity_schedule/presentation/screens/activity_schedule_screen.dart';
import 'package:carenest_app/features/management/approvals/presentation/screens/approvals_screen.dart';
import 'package:carenest_app/features/management/approvals/presentation/screens/meal_adjustment_screen.dart';
import 'package:carenest_app/features/management/approvals/presentation/screens/principal_approvals_screen.dart';
import 'package:carenest_app/features/teacher/attendance/data/fake_attendance_source.dart';
import 'package:carenest_app/features/teacher/attendance/presentation/screens/attendance_screen.dart';
import 'package:carenest_app/features/teacher/daily_health/presentation/screens/daily_health_screen.dart';
import 'package:carenest_app/features/auth/domain/entities/app_mode.dart';
import 'package:carenest_app/features/auth/presentation/screens/activation_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/login_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/new_password_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/otp_verify_screen.dart';
import 'package:carenest_app/features/management/campus_children/data/fake_campus_children_source.dart';
import 'package:carenest_app/features/management/campus_children/presentation/screens/campus_children_screen.dart';
import 'package:carenest_app/features/management/campuses/presentation/screens/campuses_screen.dart';
import 'package:carenest_app/features/teacher/class_leave_notices/presentation/screens/class_leave_screen.dart';
import 'package:carenest_app/features/teacher/class_roster/presentation/screens/class_roster_screen.dart';
import 'package:carenest_app/features/teacher/daily_review/presentation/screens/daily_review_detail_screen.dart';
import 'package:carenest_app/features/teacher/daily_review/presentation/screens/daily_review_list_screen.dart';
import 'package:carenest_app/features/shared/dev_preview/presentation/screens/role_preview_screen.dart';
import 'package:carenest_app/features/kitchen/food_quantities/presentation/screens/food_quantities_screen.dart';
import 'package:carenest_app/features/teacher/health_measure/presentation/screens/health_measure_detail_screen.dart';
import 'package:carenest_app/features/teacher/health_measure/presentation/screens/health_measure_list_screen.dart';
import 'package:carenest_app/features/kitchen/food_samples/presentation/screens/food_samples_screen.dart';
import 'package:carenest_app/features/kitchen/kitchen_home/presentation/screens/kitchen_home_screen.dart';
import 'package:carenest_app/features/kitchen/kitchen_meals/presentation/screens/kitchen_meals_screen.dart';
import 'package:carenest_app/features/kitchen/meal_photos/presentation/screens/meal_sample_photos_screen.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/screens/evaluation_screen.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/screens/theme_result_screen.dart';
import 'package:carenest_app/features/parent/rewards/presentation/screens/rewards_screen.dart';
import 'package:carenest_app/features/parent/health_book/presentation/screens/exam_detail_screen.dart';
import 'package:carenest_app/features/parent/health_book/presentation/screens/health_book_screen.dart';
import 'package:carenest_app/features/parent/leave_notice/presentation/screens/leave_notice_form_screen.dart';
import 'package:carenest_app/features/parent/leave_notice/presentation/screens/leave_notice_list_screen.dart';
import 'package:carenest_app/features/management/meal_count_confirm/presentation/screens/meal_count_confirm_screen.dart';
import 'package:carenest_app/features/parent/my_child/presentation/screens/child_activities_screen.dart';
import 'package:carenest_app/features/parent/my_child/presentation/screens/child_attendance_screen.dart';
import 'package:carenest_app/features/parent/my_child/presentation/screens/my_child_screen.dart';
import 'package:carenest_app/features/shared/notifications/presentation/screens/notification_detail_screen.dart';
import 'package:carenest_app/features/shared/notifications/presentation/screens/notifications_screen.dart';
import 'package:carenest_app/features/management/nutrition_balance/presentation/screens/nutrition_balance_screen.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/parent/parent_home/data/live_parent_home_source.dart';
import 'package:carenest_app/features/parent/parent_home/domain/parent_today.dart';
import 'package:carenest_app/features/parent/parent_home/presentation/screens/parent_home_screen.dart';
import 'package:carenest_app/features/parent/parent_home/presentation/selected_child.dart';
import 'package:carenest_app/features/parent/parent_menu/presentation/screens/weekly_menu_screen.dart';
import 'package:carenest_app/features/teacher/pickup/presentation/screens/pickup_list_screen.dart';
import 'package:carenest_app/features/teacher/pickup/presentation/screens/pickup_verify_screen.dart';
import 'package:carenest_app/features/management/principal_overview/presentation/screens/principal_overview_screen.dart';
import 'package:carenest_app/features/management/reward_proposals/presentation/screens/reward_batch_screen.dart';
import 'package:carenest_app/features/management/reward_proposals/presentation/screens/reward_proposals_screen.dart';
import 'package:carenest_app/features/management/school_children/presentation/screens/school_children_screen.dart';
import 'package:carenest_app/features/shared/school_menu/presentation/screens/school_menu_overview_screen.dart';
import 'package:carenest_app/features/shared/school_menu/presentation/screens/school_menu_screen.dart';
import 'package:carenest_app/features/teacher/teacher_home/presentation/screens/teacher_home_screen.dart';
import 'package:carenest_app/features/management/vice_principal_home/presentation/screens/campus_kitchen_screen.dart';
import 'package:carenest_app/features/management/vice_principal_home/presentation/screens/campus_menu_screen.dart';
import 'package:carenest_app/features/management/vice_principal_home/presentation/screens/vice_principal_home_screen.dart';
import 'package:carenest_app/routing/live_access.dart';
import 'package:carenest_app/routing/parent_sources.dart';
import 'package:carenest_app/routing/navigation_destinations.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// `enablePreview` mặc định theo debug: màn theo vai trò còn phụ thuộc PENDING và chưa có auth
/// ⇒ bản release chỉ có Đăng nhập và luồng quên mật khẩu (docs/architecture/NAVIGATION.md).
/// Có `session`, `api`, `signIn`, `signOut` (`app.dart`, PR #8) ⇒ router phiên thật [_buildLiveRouter].
GoRouter buildAppRouter({
  bool enablePreview = kDebugMode,
  MobileSession? session,
  MobileApi? api,
  Future<void> Function()? signIn,
  Future<void> Function()? signOut,
  Future<void> Function(String username)? signInAs,
  LastModeStore? modeStore,
}) {
  final rootKey = GlobalKey<NavigatorState>();
  // Debug chưa cấu hình BE ⇒ giữ Đăng nhập giả + Xem thử; release luôn dùng phiên thật
  final configured =
      session != null &&
      session.apiBaseUrl.isNotEmpty &&
      session.issuer.isNotEmpty;
  if (session != null &&
      api != null &&
      signIn != null &&
      signOut != null &&
      (!enablePreview || configured)) {
    return _buildLiveRouter(
      rootKey,
      session: session,
      api: api,
      signIn: signIn,
      signOut: signOut,
      signInAs: signInAs ?? (_) => signIn(),
      modeStore:
          modeStore ??
          LastModeStore(const FlutterSecureStore(), env: Env.appEnv),
    );
  }
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: RoutePaths.login,
    routes: [
      GoRoute(path: '/', redirect: (context, state) => RoutePaths.login),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => LoginScreen(
          onForgotPassword: () => context.push(RoutePaths.forgotPassword),
          onOpenPreview: enablePreview
              ? () => context.push(RoutePaths.preview)
              : null,
        ),
      ),
      _forgotPasswordRoute(enablePreview: enablePreview),
      if (enablePreview) ...[
        GoRoute(
          path: RoutePaths.preview,
          builder: (context, state) => const RolePreviewScreen(),
        ),
        ..._staffAndParentRoutes(rootKey),
        _roleShell(
          rootKey,
          AppRole.vicePrincipal,
          NavDestinations.vicePrincipal,
          {
            RoutePaths.vicePrincipalHome: (context, state) =>
                const VicePrincipalHomeScreen(),
            RoutePaths.vicePrincipalApprovals: (context, state) =>
                const ApprovalsScreen(),
          },
        ),
        ..._vicePrincipalRoutes(),
        _roleShell(rootKey, AppRole.principal, NavDestinations.principal, {
          RoutePaths.principalHome: (context, state) =>
              const PrincipalOverviewScreen(),
          RoutePaths.principalApprovals: (context, state) =>
              const PrincipalApprovalsScreen(),
        }),
        ..._principalRoutes(),
      ],
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
}

/// Tab Tài khoản: bản giả để mọi giá trị null (hồ sơ giả, Đăng xuất về Đăng nhập).
class _AccountTab {
  const _AccountTab({
    this.onLogout,
    this.source,
    this.modeSwitches,
    this.live = false,
  });

  final VoidCallback? onLogout;
  final AccountSource? source;
  final List<AccountModeSwitch> Function()? modeSwitches;

  /// Phiên thật của Tiền (PR #8): Thông tin cá nhân, Đổi mật khẩu chưa nối API ⇒ "Sắp có".
  final bool live;
}

String _modeLabel(AppMode mode) => switch (mode) {
  AppMode.teacher => 'giáo viên',
  AppMode.kitchen => 'bếp',
  AppMode.parent => 'phụ huynh',
};

/// Shell + màn con của phụ huynh, GV, bếp; dùng chung cho bản giả và bản thật.
List<RouteBase> _staffAndParentRoutes(
  GlobalKey<NavigatorState> rootKey, {
  _AccountTab account = const _AccountTab(),
  NotificationSource notifications = const FakeNotificationSource(),
  ParentSources parent = const ParentSources(),
}) => [
  _roleShell(
    rootKey,
    AppRole.parent,
    NavDestinations.parent,
    {
      RoutePaths.parentToday: (context, state) =>
          ParentHomeScreen(source: parent.home),
      RoutePaths.parentChild: (context, state) => const MyChildScreen(),
    },
    account: account,
    notifications: notifications,
  ),
  ..._parentChildRoutes(parent),
  _roleShell(
    rootKey,
    AppRole.teacher,
    NavDestinations.teacher,
    {
      RoutePaths.teacherToday: (context, state) => const TeacherHomeScreen(),
      RoutePaths.teacherClass: (context, state) => const ClassRosterScreen(),
    },
    account: account,
    notifications: notifications,
  ),
  ..._teacherRoutes(),
  GoRoute(
    path: RoutePaths.teacherAttendance,
    // Lớp đang chọn là state; bản dữ liệu giả chỉ có một lớp
    builder: (context, state) => AttendanceScreen(
      classId: FakeAttendanceSource.classId,
      // Lưu điểm danh xong đi thẳng sang Sức khỏe đầu ngày (HLT-07)
      onSaved: () => context.pushReplacement(RoutePaths.teacherDailyHealth),
    ),
  ),
  GoRoute(
    path: RoutePaths.teacherDailyHealth,
    builder: (context, state) =>
        const DailyHealthScreen(classId: FakeAttendanceSource.classId),
  ),
  _roleShell(
    rootKey,
    AppRole.kitchen,
    NavDestinations.kitchen,
    {
      RoutePaths.kitchenHome: (context, state) => const KitchenHomeScreen(),
      RoutePaths.kitchenMenu: (context, state) => SchoolMenuScreen(
        asTab: true,
        initialDay: FakeParentHomeSource.today,
        footerNote:
            'Chỉ xem. Thực đơn mẫu theo nhóm tuổi do Phó hiệu trưởng lập và công bố trên web.',
      ),
    },
    account: account,
    notifications: notifications,
  ),
  ..._kitchenRoutes(),
];

/// Màn con của Phụ huynh: route chỉ mang ID con; ID không thuộc danh sách con ⇒ 404.
List<GoRoute> _parentChildRoutes(ParentSources parent) {
  GoRoute route(
    String path,
    Widget Function(
      BuildContext context,
      GoRouterState state,
      ChildSummary child,
    )
    build,
  ) {
    return GoRoute(
      path: path,
      builder: (context, state) {
        final childId = state.uri.queryParameters['child'];
        final home = parent.home;
        if (home != null) {
          return ParentChildGate(
            childId: childId,
            loadChildren: home.loadChildren,
            builder: (child) => build(context, state, child),
            notFound: const NotFoundScreen(),
          );
        }
        final child = FakeParentHomeSource.children
            .where((item) => item.id == childId)
            .firstOrNull;
        if (child == null) return const NotFoundScreen();
        return build(context, state, child);
      },
    );
  }

  final today = FakeParentHomeSource.today;
  return [
    route(
      RoutePaths.parentLeaveNotices,
      (context, state, child) => LeaveNoticeListScreen(
        childId: child.id,
        onCreate: () => context.push<void>(
          RoutePaths.withChild(RoutePaths.parentLeaveNew, child.id),
          extra: true,
        ),
      ),
    ),
    route(RoutePaths.parentLeaveNew, (context, state, child) {
      // Mở từ danh sách ⇒ quay lại danh sách; mở từ chỗ khác ⇒ thay bằng danh sách
      final fromList = state.extra == true;
      void openList() => fromList
          ? context.pop()
          : context.pushReplacement(
              RoutePaths.withChild(RoutePaths.parentLeaveNotices, child.id),
            );
      return LeaveNoticeFormScreen(
        child: child,
        onOpenSent: openList,
        onSubmitted: openList,
      );
    }),
    route(
      RoutePaths.parentMenu,
      (context, state, child) =>
          WeeklyMenuScreen(childId: child.id, initialDay: today),
    ),
    route(
      RoutePaths.parentActivities,
      (context, state, child) => ChildActivitiesScreen(childId: child.id),
    ),
    route(
      RoutePaths.parentAttendance,
      (context, state, child) =>
          ChildAttendanceScreen(childId: child.id, initialDay: today),
    ),
    route(
      RoutePaths.parentHealthBook,
      (context, state, child) => HealthBookScreen(
        child: child,
        onOpenExam: (examId) => context.push<void>(
          RoutePaths.parentHealthExam(examId, childId: child.id),
        ),
      ),
    ),
    route(
      '${RoutePaths.parentHealthExams}/:examId',
      (context, state, child) => ExamDetailScreen(
        child: child,
        examId: state.pathParameters['examId']!,
      ),
    ),
    route(
      RoutePaths.parentEvaluation,
      (context, state, child) => EvaluationScreen(
        child: child,
        onOpenTheme: (themeId) => context.push<void>(
          RoutePaths.parentEvaluationTheme(themeId, childId: child.id),
        ),
      ),
    ),
    route(
      '${RoutePaths.parentEvaluationThemes}/:themeId',
      (context, state, child) => ThemeResultScreen(
        child: child,
        themeId: state.pathParameters['themeId']!,
      ),
    ),
    route(
      RoutePaths.parentRewards,
      (context, state, child) => RewardsScreen(
        child: child,
        onOpenDailyEvaluation: () => context.push<void>(
          RoutePaths.withChild(RoutePaths.parentEvaluation, child.id),
        ),
      ),
    ),
  ];
}

/// Màn con của Giáo viên; màn chi tiết theo trẻ mang ID trẻ trên đường dẫn.
List<GoRoute> _teacherRoutes() {
  GoRoute listWithDetail(
    String path,
    Widget Function(BuildContext context, Future<void> Function(String id) open)
    list,
    Widget Function(BuildContext context, String childId) detail,
  ) {
    return GoRoute(
      path: path,
      builder: (context, state) => list(
        context,
        (id) => context.push<void>(RoutePaths.kidDetail(path, id)),
      ),
      routes: [
        GoRoute(
          path: ':childId',
          builder: (context, state) =>
              detail(context, state.pathParameters['childId']!),
        ),
      ],
    );
  }

  return [
    GoRoute(
      path: RoutePaths.teacherLeaveNotices,
      builder: (context, state) => const ClassLeaveScreen(),
    ),
    listWithDetail(
      RoutePaths.teacherReviews,
      (context, open) => DailyReviewListScreen(onOpenKid: open),
      (context, id) => DailyReviewDetailScreen(childId: id),
    ),
    listWithDetail(
      RoutePaths.teacherPickup,
      (context, open) => PickupListScreen(onVerify: open),
      (context, id) =>
          PickupVerifyScreen(childId: id, onDone: () => context.pop()),
    ),
    listWithDetail(
      RoutePaths.teacherHealth,
      (context, open) => HealthMeasureListScreen(onOpenKid: open),
      (context, id) => HealthMeasureDetailScreen(childId: id),
    ),
    GoRoute(
      path: RoutePaths.teacherSchedule,
      builder: (context, state) =>
          ActivityScheduleScreen(initialDay: FakeParentHomeSource.today),
    ),
  ];
}

/// Màn con của Bếp.
List<GoRoute> _kitchenRoutes() => [
  GoRoute(
    path: RoutePaths.kitchenMeals,
    builder: (context, state) => const KitchenMealsScreen(),
  ),
  GoRoute(
    path: RoutePaths.kitchenQuantities,
    builder: (context, state) => const FoodQuantitiesScreen(),
  ),
  GoRoute(
    path: RoutePaths.kitchenPhotos,
    builder: (context, state) => const MealSamplePhotosScreen(),
  ),
  GoRoute(
    path: RoutePaths.kitchenSamples,
    builder: (context, state) => const FoodSamplesScreen(),
  ),
];

/// Màn con của Phó HT. Ngữ cảnh (nhóm tuổi, ngày) ở query; sai định dạng ⇒ về mặc định.
List<GoRoute> _vicePrincipalRoutes() => [
  GoRoute(
    path: '${RoutePaths.vicePrincipalAdjustments}/:id',
    builder: (context, state) => MealAdjustmentScreen(
      id: state.pathParameters['id']!,
      onDone: () => context.pop(),
    ),
  ),
  GoRoute(
    path: RoutePaths.vicePrincipalRewards,
    builder: (context, state) => const RewardProposalsScreen(),
  ),
  GoRoute(
    path: RoutePaths.vicePrincipalMealConfirm,
    builder: (context, state) => const MealCountConfirmScreen(),
  ),
  GoRoute(
    path: RoutePaths.vicePrincipalKitchen,
    builder: (context, state) => const CampusKitchenScreen(),
  ),
  GoRoute(
    path: RoutePaths.vicePrincipalMenu,
    builder: (context, state) => const CampusMenuScreen(),
  ),
  GoRoute(
    path: RoutePaths.vicePrincipalNutrition,
    builder: (context, state) => NutritionBalanceScreen(
      groupId: state.uri.queryParameters['group'] ?? 'mam',
      day:
          DateTime.tryParse(state.uri.queryParameters['day'] ?? '') ??
          FakeParentHomeSource.today,
    ),
  ),
  GoRoute(
    path: RoutePaths.vicePrincipalChildren,
    builder: (context, state) => const CampusChildrenScreen(),
  ),
];

/// Màn con của Hiệu trưởng. Cơ sở, lớp, nhóm tuổi, ngày là ngữ cảnh ở query.
List<GoRoute> _principalRoutes() => [
  GoRoute(
    path: '${RoutePaths.principalRewardBatches}/:id',
    builder: (context, state) => RewardBatchScreen(
      id: state.pathParameters['id']!,
      onDone: () => context.pop(),
    ),
  ),
  GoRoute(
    path: RoutePaths.principalChildren,
    builder: (context, state) => const SchoolChildrenScreen(),
  ),
  GoRoute(
    path: RoutePaths.principalClassChildren,
    builder: (context, state) => CampusChildrenScreen(
      title: 'Trẻ của lớp',
      campusId:
          state.uri.queryParameters['campus'] ??
          FakeCampusChildrenSource.mainCampusId,
      initialClassId: state.uri.queryParameters['class'],
    ),
  ),
  GoRoute(
    path: RoutePaths.principalMenu,
    builder: (context, state) => SchoolMenuOverviewScreen(
      initialDay: FakeParentHomeSource.today,
      campuses: const [
        (FakeCampusChildrenSource.mainCampusId, 'Cơ sở chính'),
        (FakeCampusChildrenSource.secondCampusId, 'Cơ sở 2'),
      ],
    ),
  ),
  GoRoute(
    path: RoutePaths.principalNutrition,
    builder: (context, state) => NutritionBalanceScreen(
      campusId:
          state.uri.queryParameters['campus'] ??
          FakeCampusChildrenSource.mainCampusId,
      groupId: state.uri.queryParameters['group'] ?? 'mam',
      day:
          DateTime.tryParse(state.uri.queryParameters['day'] ?? '') ??
          FakeParentHomeSource.today,
    ),
  ),
  GoRoute(
    path: RoutePaths.principalCampuses,
    builder: (context, state) => const CampusesScreen(),
  ),
];

/// Quên mật khẩu → OTP → đặt mật khẩu mới. Chưa có AUTH_CONTRACT: bản release để callback null
/// (màn báo chưa kết nối), bản debug cho đi hết luồng bằng dữ liệu giả.
GoRoute _forgotPasswordRoute({required bool enablePreview}) {
  return GoRoute(
    path: RoutePaths.forgotPassword,
    builder: (context, state) => ForgotPasswordScreen(
      onSendCode: enablePreview
          ? (phone) => context.push(
              RoutePaths.forgotPasswordOtp,
              extra: _maskPhone(phone),
            )
          : null,
    ),
    routes: [
      GoRoute(
        path: RoutePaths.otpSegment,
        builder: (context, state) => OtpVerifyScreen(
          maskedPhone: state.extra as String?,
          onVerify: enablePreview
              ? (_) => context.push(RoutePaths.forgotPasswordNew)
              : null,
        ),
      ),
      GoRoute(
        path: RoutePaths.newPasswordSegment,
        builder: (context, state) => NewPasswordScreen(
          onSave: enablePreview ? (_, _) => context.go(RoutePaths.login) : null,
        ),
      ),
    ],
  );
}

/// Chỉ giữ 3 số đầu và 3 số cuối, như BE sẽ trả khi gửi OTP.
String _maskPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 7) return 'số điện thoại của bạn';
  final hidden = '•' * (digits.length - 6);
  return '${digits.substring(0, 3)}$hidden${digits.substring(digits.length - 3)}';
}

/// Router khi chạy với BE thật (nền PR #8 của Tiền): shell và màn của từng vai trò,
/// tab Thông báo và Tài khoản đọc dữ liệu thật; lối vào `/live/...` giữ cho `app.dart` và push.
GoRouter _buildLiveRouter(
  GlobalKey<NavigatorState> rootKey, {
  required MobileSession session,
  required MobileApi api,
  required Future<void> Function() signIn,
  required Future<void> Function() signOut,
  required Future<void> Function(String username) signInAs,
  required LastModeStore modeStore,
}) {
  final modes = LiveModeController(session, modeStore);
  AppMode? readMode() => modes.mode;

  String notificationsPath(AppMode mode) => switch (mode) {
    AppMode.teacher => RoutePaths.teacherNotifications,
    AppMode.kitchen => RoutePaths.kitchenNotifications,
    AppMode.parent => RoutePaths.parentNotifications,
  };

  Future<void> logout() async {
    // AUTH-22: máy dùng chung ⇒ người sau không thấy con của người trước
    SelectedChild.reset();
    await signOut();
  }

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: RoutePaths.login,
    refreshListenable: Listenable.merge([session, modes]),
    // Chờ đọc chế độ cuối trước khi chọn màn (vd. mở từ push khi App đang tắt)
    redirect: (context, state) async {
      await modes.ready;
      return liveRedirect(
        signedIn: session.signedIn,
        mode: readMode(),
        location: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => RoutePaths.login),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => LiveLoginScreen(
          signIn: signIn,
          onActivate: () => context.push(RoutePaths.activate),
          notice: session.expired
              ? 'Phiên đăng nhập đã hết. Vui lòng đăng nhập lại.'
              : null,
        ),
      ),
      GoRoute(
        path: RoutePaths.activate,
        builder: (context, state) =>
            ActivationScreen(api: ActivationApi(api), signInAs: signInAs),
      ),
      GoRoute(
        path: RoutePaths.liveNotifications,
        redirect: (context, state) async {
          await modes.ready;
          return notificationsPath(readMode()!);
        },
      ),
      GoRoute(
        path: '${RoutePaths.liveNotifications}/:id',
        redirect: (context, state) async {
          await modes.ready;
          return '${notificationsPath(readMode()!)}/${state.pathParameters['id']}';
        },
      ),
      GoRoute(
        path: RoutePaths.liveUnsupported,
        builder: (context, state) => UnsupportedRoleScreen(onSignOut: logout),
      ),
      ..._staffAndParentRoutes(
        rootKey,
        account: _AccountTab(
          live: true,
          source: LiveAccountSource(session),
          onLogout: logout,
          modeSwitches: () => [
            for (final mode in modes.modes)
              if (mode != modes.mode)
                AccountModeSwitch(
                  label: 'Chuyển sang chế độ ${_modeLabel(mode)}',
                  onTap: () => modes.switchTo(mode),
                ),
          ],
        ),
        notifications: LiveNotificationSource(api),
        parent: ParentSources(
          live: true,
          home: LiveParentHomeSource(api, session),
        ),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
}

/// Một nhánh tab cho mỗi đích; Thông báo và Tài khoản dùng chung mọi vai trò,
/// đích chưa có màn thì hiện "Sắp có". Màn con mở trên navigator gốc (ẩn thanh đáy).
/// `account` mặc định (bản giả) ⇒ hồ sơ giả, Đăng xuất chỉ về màn Đăng nhập.
StatefulShellRoute _roleShell(
  GlobalKey<NavigatorState> rootKey,
  AppRole role,
  List<NavDestination> destinations,
  Map<String, GoRouterWidgetBuilder> screens, {
  _AccountTab account = const _AccountTab(),
  NotificationSource notifications = const FakeNotificationSource(),
  String? Function()? redirect,
}) {
  final live = account.live;
  return StatefulShellRoute.indexedStack(
    redirect: redirect == null ? null : (_, _) => redirect(),
    builder: (context, state, navigationShell) =>
        AppShell(navigationShell: navigationShell, destinations: destinations),
    branches: [
      for (final destination in destinations)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: destination.path,
              builder: (context, state) => switch (destination.tab) {
                NavTab.notifications => NotificationsScreen(
                  role: role,
                  source: notifications,
                  onOpen: (id) => context.push('${destination.path}/$id'),
                ),
                NavTab.account => AccountScreen(
                  role: role,
                  onOpenProfile: live
                      ? () => openComingSoon(context, 'Thông tin cá nhân')
                      : () => context.push(
                          '${destination.path}/${RoutePaths.profileSegment}',
                        ),
                  onChangePassword: live
                      ? () => openComingSoon(context, 'Đổi mật khẩu')
                      : () => context.push(
                          '${destination.path}/${RoutePaths.passwordSegment}',
                        ),
                  onOpenCampuses: role == AppRole.principal
                      ? () => context.push(RoutePaths.principalCampuses)
                      : null,
                  // Bản thật: thu hồi phiên, router tự về Đăng nhập theo phiên
                  onLogout:
                      account.onLogout ??
                      () {
                        SelectedChild.reset();
                        context.go(RoutePaths.login);
                      },
                  modeSwitches: account.modeSwitches?.call() ?? const [],
                  source: account.source ?? const FakeAccountSource(),
                ),
                _ =>
                  screens[destination.path]?.call(context, state) ??
                      SafeArea(child: AppComingSoon(title: destination.label)),
              },
              routes: switch (destination.tab) {
                NavTab.notifications => [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => NotificationDetailScreen(
                      role: role,
                      id: state.pathParameters['id']!,
                      source: notifications,
                    ),
                  ),
                ],
                NavTab.account when live => const <RouteBase>[],
                NavTab.account => [
                  GoRoute(
                    path: RoutePaths.profileSegment,
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => PersonalInfoScreen(
                      role: role,
                      source: account.source ?? const FakeAccountSource(),
                    ),
                  ),
                  GoRoute(
                    path: RoutePaths.passwordSegment,
                    parentNavigatorKey: rootKey,
                    builder: (context, state) =>
                        const NewPasswordScreen(requireCurrent: true),
                  ),
                ],
                _ => const <RouteBase>[],
              },
            ),
          ],
        ),
    ],
  );
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: AppEmptyState(
          icon: AppIcons.searchOff,
          title: 'Không tìm thấy trang',
          message: 'Trang bạn mở không tồn tại hoặc đã bị gỡ.',
          actionLabel: 'Về trang đăng nhập',
          onAction: () => context.go(RoutePaths.login),
        ),
      ),
    );
  }
}

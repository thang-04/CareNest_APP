import 'package:carenest_app/core/config/env.dart';
import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/integration/mobile_session.dart';
import 'package:carenest_app/core/layouts/app_shell.dart';
import 'package:carenest_app/core/storage/last_mode_store.dart';
import 'package:carenest_app/core/storage/secure_store.dart';
import 'package:carenest_app/core/widgets/app_coming_soon.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/auth/data/activation_api.dart';
import 'package:carenest_app/features/auth/data/live_mode_controller.dart';
import 'package:carenest_app/features/auth/domain/entities/app_mode.dart';
import 'package:carenest_app/features/auth/presentation/screens/activation_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/live_login_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/login_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/new_password_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/otp_verify_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/unsupported_role_screen.dart';
import 'package:carenest_app/features/kitchen/kitchen_menu/presentation/screens/kitchen_menu_screen.dart';
import 'package:carenest_app/features/kitchen/kitchen_menu/data/live_kitchen_menu_source.dart';
import 'package:carenest_app/features/kitchen/kitchen_menu/data/fake_kitchen_menu_source.dart';
import 'package:carenest_app/features/kitchen/food_samples/domain/food_samples.dart';
import 'package:carenest_app/features/kitchen/kitchen_home/domain/kitchen_tasks.dart';
import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';
import 'package:carenest_app/features/kitchen/meal_photos/data/live_kitchen_photo_source.dart';
import 'package:carenest_app/features/kitchen/food_quantities/data/live_food_quantity_source.dart';
import 'package:carenest_app/features/kitchen/food_samples/data/live_food_sample_source.dart';
import 'package:carenest_app/features/kitchen/kitchen_home/data/live_kitchen_home_source.dart';
import 'package:carenest_app/features/kitchen/kitchen_meals/data/live_kitchen_meals_source.dart';
import 'package:carenest_app/features/kitchen/food_quantities/presentation/screens/food_quantities_screen.dart';
import 'package:carenest_app/features/kitchen/food_samples/presentation/screens/food_samples_screen.dart';
import 'package:carenest_app/features/kitchen/kitchen_home/presentation/screens/kitchen_home_screen.dart';
import 'package:carenest_app/features/kitchen/kitchen_meals/presentation/screens/kitchen_meals_screen.dart';
import 'package:carenest_app/features/kitchen/meal_photos/presentation/screens/meal_sample_photos_screen.dart';
import 'package:carenest_app/features/management/approvals/presentation/screens/approvals_screen.dart';
import 'package:carenest_app/features/management/approvals/presentation/screens/meal_adjustment_screen.dart';
import 'package:carenest_app/features/management/approvals/presentation/screens/principal_approvals_screen.dart';
import 'package:carenest_app/features/management/campus_children/data/fake_campus_children_source.dart';
import 'package:carenest_app/features/management/campus_children/presentation/screens/campus_children_screen.dart';
import 'package:carenest_app/features/management/campuses/presentation/screens/campuses_screen.dart';
import 'package:carenest_app/features/management/meal_count_confirm/presentation/screens/meal_count_confirm_screen.dart';
import 'package:carenest_app/features/management/nutrition_balance/presentation/screens/nutrition_balance_screen.dart';
import 'package:carenest_app/features/management/principal_overview/presentation/screens/principal_overview_screen.dart';
import 'package:carenest_app/features/management/reward_proposals/presentation/screens/reward_batch_screen.dart';
import 'package:carenest_app/features/management/reward_proposals/presentation/screens/reward_proposals_screen.dart';
import 'package:carenest_app/features/management/school_children/presentation/screens/school_children_screen.dart';
import 'package:carenest_app/features/management/vice_principal_home/presentation/screens/campus_kitchen_screen.dart';
import 'package:carenest_app/features/management/vice_principal_home/presentation/screens/campus_menu_screen.dart';
import 'package:carenest_app/features/management/vice_principal_home/presentation/screens/vice_principal_home_screen.dart';
import 'package:carenest_app/features/parent/evaluation/data/fake_evaluation_source.dart';
import 'package:carenest_app/features/parent/evaluation/data/live_evaluation_source.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/screens/evaluation_screen.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/screens/theme_result_screen.dart';
import 'package:carenest_app/features/parent/health_book/data/fake_health_book_source.dart';
import 'package:carenest_app/features/parent/health_book/data/live_health_book_source.dart';
import 'package:carenest_app/features/parent/health_book/presentation/screens/exam_detail_screen.dart';
import 'package:carenest_app/features/parent/health_book/presentation/screens/health_book_screen.dart';
import 'package:carenest_app/features/parent/leave_notice/data/live_leave_notice_source.dart';
import 'package:carenest_app/features/parent/leave_notice/presentation/screens/leave_notice_form_screen.dart';
import 'package:carenest_app/features/parent/leave_notice/presentation/screens/leave_notice_list_screen.dart';
import 'package:carenest_app/features/parent/my_child/data/fake_my_child_source.dart';
import 'package:carenest_app/features/parent/my_child/data/live_my_child_source.dart';
import 'package:carenest_app/features/parent/my_child/presentation/screens/child_activities_screen.dart';
import 'package:carenest_app/features/parent/my_child/presentation/screens/child_attendance_screen.dart';
import 'package:carenest_app/features/parent/my_child/presentation/screens/my_child_screen.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/parent/parent_home/data/live_parent_home_source.dart';
import 'package:carenest_app/features/parent/parent_home/domain/parent_today.dart';
import 'package:carenest_app/features/parent/parent_home/presentation/screens/parent_home_screen.dart';
import 'package:carenest_app/features/parent/parent_home/presentation/selected_child.dart';
import 'package:carenest_app/features/parent/parent_menu/presentation/screens/weekly_menu_screen.dart';
import 'package:carenest_app/features/parent/school_year/data/fake_child_school_year_source.dart';
import 'package:carenest_app/features/parent/school_year/data/live_child_school_year_source.dart';
import 'package:carenest_app/features/parent/school_year/domain/child_school_year.dart';
import 'package:carenest_app/features/parent/school_year/presentation/parent_selected_year.dart';
import 'package:carenest_app/features/parent/rewards/data/fake_reward_source.dart';
import 'package:carenest_app/features/parent/rewards/data/live_reward_source.dart';
import 'package:carenest_app/features/parent/rewards/presentation/screens/rewards_screen.dart';
import 'package:carenest_app/features/shared/account/data/fake_account_source.dart';
import 'package:carenest_app/features/shared/account/data/live_account_source.dart';
import 'package:carenest_app/features/shared/account/domain/account_profile.dart';
import 'package:carenest_app/features/shared/account/presentation/screens/account_screen.dart';
import 'package:carenest_app/features/shared/account/presentation/screens/personal_info_screen.dart';
import 'package:carenest_app/features/shared/app_mode/app_mode.dart'
    as preview_mode;
import 'package:carenest_app/features/shared/dev_preview/presentation/screens/role_preview_screen.dart';
import 'package:carenest_app/features/shared/notifications/data/fake_notification_source.dart';
import 'package:carenest_app/features/shared/notifications/data/live_notification_source.dart';
import 'package:carenest_app/features/shared/notifications/domain/app_notification.dart';
import 'package:carenest_app/features/shared/notifications/presentation/screens/notification_detail_screen.dart';
import 'package:carenest_app/features/shared/notifications/presentation/screens/notifications_screen.dart';
import 'package:carenest_app/features/shared/school_menu/presentation/screens/school_menu_overview_screen.dart';
import 'package:carenest_app/features/shared/school_menu/presentation/screens/school_menu_screen.dart';
import 'package:carenest_app/features/teacher/activity_schedule/presentation/screens/activity_schedule_screen.dart';
import 'package:carenest_app/features/teacher/attendance/presentation/screens/attendance_screen.dart';
import 'package:carenest_app/features/teacher/class_leave_notices/presentation/screens/class_leave_screen.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/class_roster/domain/class_roster.dart';
import 'package:carenest_app/features/teacher/class_roster/presentation/screens/class_roster_screen.dart';
import 'package:carenest_app/features/teacher/daily_health/presentation/screens/daily_health_screen.dart';
import 'package:carenest_app/features/teacher/daily_review/presentation/screens/daily_review_list_screen.dart';
import 'package:carenest_app/features/teacher/daily_review/presentation/screens/kid_evaluation_screen.dart';
import 'package:carenest_app/features/teacher/health_measure/presentation/screens/health_measure_detail_screen.dart';
import 'package:carenest_app/features/teacher/health_measure/presentation/screens/health_measure_list_screen.dart';
import 'package:carenest_app/features/teacher/pickup/presentation/screens/pickup_list_screen.dart';
import 'package:carenest_app/features/teacher/pickup/presentation/screens/pickup_verify_screen.dart';
import 'package:carenest_app/features/teacher/rewards/presentation/screens/teacher_rewards_screen.dart';
import 'package:carenest_app/features/teacher/school_year/domain/school_year.dart';
import 'package:carenest_app/features/teacher/school_year/presentation/selected_school_year.dart';
import 'package:carenest_app/features/teacher/teacher_home/presentation/screens/teacher_home_screen.dart';
import 'package:carenest_app/routing/live_access.dart';
import 'package:carenest_app/routing/navigation_destinations.dart';
import 'package:carenest_app/routing/kitchen_sources.dart';
import 'package:carenest_app/routing/notification_targets.dart';
import 'package:carenest_app/routing/parent_sources.dart';
import 'package:carenest_app/core/integration/load_failure.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/integration/api_dates.dart';
import 'package:carenest_app/features/teacher/attendance/data/fake_attendance_summary_source.dart';
import 'package:carenest_app/features/teacher/attendance/data/live_attendance_summary_source.dart';
import 'package:carenest_app/features/teacher/attendance/presentation/screens/attendance_summary_screen.dart';
import 'package:carenest_app/features/teacher/class_roster/data/live_child_health_source.dart';
import 'package:carenest_app/features/teacher/pickup/presentation/screens/pickup_result_screen.dart';
import 'package:carenest_app/features/teacher/shared/class_option.dart';
import 'package:carenest_app/routing/teacher_sources.dart';
import 'package:carenest_app/features/teacher/attendance/data/live_attendance_source.dart';
import 'package:carenest_app/features/teacher/class_leave_notices/data/fake_class_leave_source.dart';
import 'package:carenest_app/features/teacher/class_leave_notices/data/live_class_leave_source.dart';
import 'package:carenest_app/features/teacher/class_roster/data/live_class_roster_source.dart';
import 'package:carenest_app/features/teacher/class_roster/data/live_teacher_classes.dart';
import 'package:carenest_app/features/teacher/daily_health/data/live_daily_health_source.dart';
import 'package:carenest_app/features/teacher/daily_review/data/live_daily_review_source.dart';
import 'package:carenest_app/features/teacher/daily_review/data/live_kid_evaluation_source.dart';
import 'package:carenest_app/features/teacher/health_measure/data/live_health_measure_source.dart';
import 'package:carenest_app/features/teacher/pickup/data/live_pickup_source.dart';
import 'package:carenest_app/features/teacher/rewards/data/live_teacher_reward_source.dart';
import 'package:carenest_app/features/teacher/school_year/data/live_school_year_source.dart';
import 'package:carenest_app/features/teacher/teacher_home/data/live_teacher_home_source.dart';
import 'package:carenest_app/routing/route_paths.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    this.switchMode,
    this.live = false,
  });

  final VoidCallback? onLogout;
  final AccountSource? source;

  /// Phiên thật: nút đổi chế độ ở Trang chủ (G94-385: chỉ ở Trang chủ) — callback khi tài khoản có
  /// chế độ [AppMode] đó và đang ở chế độ khác, null ⇒ ẩn nút.
  final VoidCallback? Function(AppMode target)? switchMode;

  /// Phiên thật của Tiền (PR #8): Thông tin cá nhân, Đổi mật khẩu chưa nối API ⇒ "Sắp có".
  final bool live;
}

/// Nút đổi chế độ GV ↔ phụ huynh ở Trang chủ (AUTH-21). Phiên thật theo [LiveModeController];
/// Xem thử: cô Hà kiêm phụ huynh, nút "Giáo viên" chỉ khi đến từ chế độ GV (G94-385).
VoidCallback? _homeSwitch(
  BuildContext context,
  _AccountTab account,
  AppMode target,
) {
  if (account.switchMode case final live?) return live(target);
  return switch (target) {
    AppMode.parent => () {
      preview_mode.AppMode.dualRole.value = true;
      context.go(RoutePaths.parentToday);
    },
    AppMode.teacher =>
      preview_mode.AppMode.dualRole.value
          ? () => context.go(RoutePaths.teacherToday)
          : null,
    AppMode.kitchen => null,
  };
}

/// Shell + màn con của phụ huynh, GV, bếp; dùng chung cho bản giả và bản thật.
List<RouteBase> _staffAndParentRoutes(
  GlobalKey<NavigatorState> rootKey, {
  _AccountTab account = const _AccountTab(),
  NotificationSource notifications = const FakeNotificationSource(),
  ParentSources parent = const ParentSources(),
  KitchenSources kitchen = const KitchenSources(),
  TeacherSources teacher = const TeacherSources(),
}) => [
  _roleShell(
    rootKey,
    AppRole.parent,
    NavDestinations.parent,
    {
      RoutePaths.parentToday: (context, state) => ParentHomeScreen(
        source: parent.home,
        live: parent.live,
        onSwitchToTeacher: _homeSwitch(context, account, AppMode.teacher),
      ),
      RoutePaths.parentChild: (context, state) => MyChildScreen(
        source: parent.myChild ?? const FakeMyChildSource(),
        yearSource: parent.schoolYears ?? const FakeChildSchoolYearSource(),
      ),
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
      RoutePaths.teacherToday: (context, state) => TeacherHomeScreen(
        source: teacher.home,
        onSwitchToParent: _homeSwitch(context, account, AppMode.parent),
      ),
      RoutePaths.teacherClass: (context, state) => TeacherClassGate(
        sources: teacher,
        builder: (classId, classes) => ClassRosterScreen(
          classId: classId,
          source: teacher.roster ?? const FakeClassRosterSource(),
          childHealthSource: teacher.childHealth,
        ),
      ),
    },
    account: account,
    notifications: notifications,
  ),
  ..._teacherRoutes(teacher),
  GoRoute(
    path: RoutePaths.teacherAttendance,
    // Phiên thật: lớp của giáo viên từ BE; bản giả chỉ có một lớp
    builder: (context, state) => TeacherClassGate(
      sources: teacher,
      builder: (classId, classes) => AttendanceScreen(
        classId: classId,
        classes: classes,
        source: teacher.attendance,
        // Sức khỏe đầu ngày (HLT-07) mở bằng nút riêng, cùng ngày đang xem
        onOpenHealth: (_, date) => context.push<void>(
          '${RoutePaths.teacherDailyHealth}?date=${apiDate(date)}',
        ),
        onOpenSummary: (_) =>
            context.push<void>(RoutePaths.teacherAttendanceSummary),
      ),
    ),
  ),
  GoRoute(
    path: RoutePaths.teacherAttendanceSummary,
    builder: (context, state) => TeacherClassGate(
      sources: teacher,
      builder: (classId, classes) => AttendanceSummaryScreen(
        classId: classId,
        source: teacher.attendanceSummary ?? FakeAttendanceSummarySource(),
      ),
    ),
  ),
  GoRoute(
    path: RoutePaths.teacherDailyHealth,
    builder: (context, state) => TeacherClassGate(
      sources: teacher,
      builder: (classId, classes) => DailyHealthScreen(
        classId: classId,
        classes: classes,
        source: teacher.dailyHealth,
        initialDate: DateTime.tryParse(state.uri.queryParameters['date'] ?? ''),
      ),
    ),
  ),
  _roleShell(
    rootKey,
    AppRole.kitchen,
    NavDestinations.kitchen,
    {
      RoutePaths.kitchenHome: (context, state) =>
          KitchenHomeScreen(source: kitchen.home),
      RoutePaths.kitchenMenu: (context, state) => KitchenMenuScreen(
        source: kitchen.menu ?? const FakeKitchenMenuSource(),
      ),
    },
    account: account,
    notifications: notifications,
  ),
  ..._kitchenRoutes(kitchen),
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

  // Ô Năm học (user 25/11): màn theo năm dựng sau khi tải năm học của bé; đổi năm ⇒ tải lại
  final yearSource = parent.schoolYears ?? const FakeChildSchoolYearSource();
  Widget inYear(
    ChildSummary child,
    String title,
    Widget Function(ChildSchoolYear year) build,
  ) => ParentYearGate(
    childId: child.id,
    source: yearSource,
    title: title,
    builder: build,
  );

  return [
    route(
      RoutePaths.parentLeaveNotices,
      (context, state, child) => inYear(
        child,
        'Đơn xin nghỉ',
        (year) => LeaveNoticeListScreen(
          childId: child.id,
          year: year,
          source: parent.leave,
          onCreate: () => context.push<void>(
            RoutePaths.withChild(RoutePaths.parentLeaveNew, child.id),
            extra: true,
          ),
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
        source: parent.leave,
        onOpenSent: openList,
        onSubmitted: openList,
      );
    }),
    // Q1 (user 25/11): BE chưa có API thực đơn tuần cho phụ huynh ⇒ phiên thật hiện "Sắp có"
    route(
      RoutePaths.parentMenu,
      (context, state, child) => parent.live
          ? const _ComingSoonPage('Thực đơn tuần')
          : WeeklyMenuScreen(childId: child.id, initialDay: parent.today),
    ),
    route(
      RoutePaths.parentActivities,
      (context, state, child) => ChildActivitiesScreen(
        childId: child.id,
        source: parent.myChild ?? const FakeMyChildSource(),
      ),
    ),
    route(
      RoutePaths.parentAttendance,
      (context, state, child) => inYear(
        child,
        'Điểm danh & bữa ăn',
        (year) => ChildAttendanceScreen(
          childId: child.id,
          year: year,
          // Đọc mỗi lần mở màn: router sống qua nửa đêm không giữ ngày cũ
          initialDay: parent.today,
          source: parent.myChild ?? const FakeMyChildSource(),
        ),
      ),
    ),
    route(
      RoutePaths.parentHealthBook,
      (context, state, child) => inYear(
        child,
        'Sổ sức khỏe',
        (year) => HealthBookScreen(
          child: child,
          year: year,
          source: parent.healthBook ?? const FakeHealthBookSource(),
          onOpenExam: (examId) => context.push<void>(
            RoutePaths.parentHealthExam(examId, childId: child.id),
          ),
        ),
      ),
    ),
    route(
      '${RoutePaths.parentHealthExams}/:examId',
      (context, state, child) => ExamDetailScreen(
        child: child,
        examId: state.pathParameters['examId']!,
        source: parent.healthBook ?? const FakeHealthBookSource(),
      ),
    ),
    route(
      RoutePaths.parentEvaluation,
      (context, state, child) => inYear(
        child,
        'Đánh giá',
        (year) => EvaluationScreen(
          child: child,
          year: year,
          source: parent.evaluation ?? const FakeEvaluationSource(),
          onOpenTheme: (themeId) => context.push<void>(
            RoutePaths.parentEvaluationTheme(themeId, childId: child.id),
          ),
        ),
      ),
    ),
    route(
      '${RoutePaths.parentEvaluationThemes}/:themeId',
      (context, state, child) => ThemeResultScreen(
        child: child,
        themeId: state.pathParameters['themeId']!,
        source: parent.evaluation ?? const FakeEvaluationSource(),
      ),
    ),
    route(
      RoutePaths.parentRewards,
      (context, state, child) => inYear(
        child,
        'Khen thưởng',
        (year) => RewardsScreen(
          child: child,
          year: year,
          source: parent.rewards ?? const FakeRewardSource(),
          onOpenDailyEvaluation: () => context.push<void>(
            RoutePaths.withChild(RoutePaths.parentEvaluation, child.id),
          ),
        ),
      ),
    ),
  ];
}

/// Màn con của Giáo viên; màn chi tiết theo trẻ mang ID trẻ trên đường dẫn.
/// Phiên thật lấy lớp từ BE ([TeacherClassGate]); màn chưa có API hiện "Sắp có".
List<GoRoute> _teacherRoutes(TeacherSources teacher) {
  Widget gated(
    Widget Function(String classId, List<ClassOption> classes) build,
  ) => TeacherClassGate(sources: teacher, builder: build);

  GoRoute listWithDetail(
    String path,
    Widget Function(
      BuildContext context,
      String classId,
      Future<void> Function(String id) open,
    )
    list,
    Widget Function(BuildContext context, String classId, String childId)
    detail,
  ) {
    return GoRoute(
      path: path,
      builder: (context, state) => gated(
        (classId, classes) => list(
          context,
          classId,
          (id) => context.push<void>(RoutePaths.kidDetail(path, id)),
        ),
      ),
      routes: [
        GoRoute(
          path: ':childId',
          builder: (context, state) => gated(
            (classId, classes) =>
                detail(context, classId, state.pathParameters['childId']!),
          ),
        ),
      ],
    );
  }

  return [
    GoRoute(
      path: RoutePaths.teacherLeaveNotices,
      builder: (context, state) => gated(
        (classId, classes) => ClassLeaveScreen(
          classId: classId,
          classes: classes,
          source: teacher.leave ?? const FakeClassLeaveSource(),
        ),
      ),
    ),
    GoRoute(
      path: RoutePaths.teacherReviews,
      builder: (context, state) => gated(
        (classId, classes) => DailyReviewListScreen(
          classId: classId,
          classes: classes,
          source: teacher.review,
          onOpenKid: (id) => context.push<void>(
            RoutePaths.kidDetail(RoutePaths.teacherReviews, id),
          ),
        ),
      ),
      routes: [
        GoRoute(
          path: ':childId',
          builder: (context, state) => gated(
            (classId, classes) => KidEvaluationScreen(
              childId: state.pathParameters['childId']!,
              classId: classId,
              rosterSource: teacher.roster,
              source: teacher.evaluation ?? const FakeEvaluationSource(),
              onOpenTheme: (childId, themeId) => context.push<void>(
                '${RoutePaths.kidDetail(RoutePaths.teacherReviews, childId)}/themes/$themeId',
              ),
            ),
          ),
          routes: [
            GoRoute(
              path: 'themes/:themeId',
              builder: (context, state) {
                final live = teacher.roster;
                if (teacher.live && live != null) {
                  // Phiên thật: bé lấy từ lớp của giáo viên, kết quả chủ đề từ BE
                  return gated(
                    (classId, classes) => FutureBuilder<ClassRoster>(
                      future: live.loadRoster(classId),
                      builder: (context, snapshot) {
                        final roster = snapshot.data;
                        if (roster == null) {
                          return Scaffold(
                            appBar: AppBar(),
                            body: snapshot.hasError
                                ? AppErrorState(
                                    title: 'Chưa tải được lớp',
                                    message: loadFailureMessage(snapshot.error),
                                  )
                                : const AppSkeletonList(rows: 3),
                          );
                        }
                        final kid = roster.kids
                            .where(
                              (k) => k.id == state.pathParameters['childId'],
                            )
                            .firstOrNull;
                        if (kid == null) return const NotFoundScreen();
                        return ThemeResultScreen(
                          child: KidEvaluationScreen.summaryOf(kid, roster),
                          themeId: state.pathParameters['themeId']!,
                          source: teacher.evaluation!,
                        );
                      },
                    ),
                  );
                }
                final kid = FakeClassRosterSource.kidById(
                  state.pathParameters['childId']!,
                );
                return ThemeResultScreen(
                  child: KidEvaluationScreen.summaryOf(
                    kid,
                    ClassRoster(
                      classId: FakeClassRosterSource.classId,
                      className: FakeClassRosterSource.className,
                      campusName: FakeClassRosterSource.campusName,
                      kids: const [],
                    ),
                  ),
                  themeId: state.pathParameters['themeId']!,
                );
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: RoutePaths.teacherMenu,
      builder: (context, state) => teacher.live
          ? const _ComingSoonPage('Thực đơn tuần')
          : SchoolMenuScreen(
              initialDay: FakeParentHomeSource.today,
              footerNote: 'Chỉ xem thực đơn đã công bố.',
            ),
    ),
    GoRoute(
      path: RoutePaths.teacherRewards,
      builder: (context, state) => gated(
        (classId, classes) => TeacherRewardsScreen(
          classId: classId,
          classes: classes,
          source: teacher.rewards,
        ),
      ),
    ),
    GoRoute(
      path: RoutePaths.teacherPickup,
      builder: (context, state) => gated(
        (classId, classes) => PickupListScreen(
          classId: classId,
          classes: classes,
          source: teacher.pickup,
          onVerify: (id) => context.push<void>(
            RoutePaths.kidDetail(RoutePaths.teacherPickup, id),
          ),
          onCall: (id) => context.push<void>(
            '${RoutePaths.kidDetail(RoutePaths.teacherPickup, id)}?mode=call',
          ),
          onOpenResults: () =>
              context.push<void>('${RoutePaths.teacherPickup}/result'),
          onOpenHealth: (_, date) => context.push<void>(
            '${RoutePaths.teacherDailyHealth}?date=${apiDate(date)}',
          ),
          onOpenAttendance: () =>
              context.push<void>(RoutePaths.teacherAttendance),
        ),
      ),
      routes: [
        GoRoute(
          path: 'result',
          builder: (context, state) =>
              PickupResultScreen(source: teacher.pickup),
        ),
        GoRoute(
          path: ':childId',
          builder: (context, state) => PickupVerifyScreen(
            childId: state.pathParameters['childId']!,
            source: teacher.pickup,
            callMode: state.uri.queryParameters['mode'] == 'call',
            onDone: () => context.pop(),
          ),
        ),
      ],
    ),
    listWithDetail(
      RoutePaths.teacherHealth,
      (context, classId, open) => HealthMeasureListScreen(
        classId: classId,
        source: teacher.measure,
        onOpenKid: open,
      ),
      (context, classId, id) => HealthMeasureDetailScreen(
        childId: id,
        classId: classId,
        source: teacher.measure,
      ),
    ),
    GoRoute(
      path: RoutePaths.teacherSchedule,
      builder: (context, state) => teacher.live
          ? const _ComingSoonPage('Lịch hoạt động')
          : ActivityScheduleScreen(initialDay: FakeParentHomeSource.today),
    ),
  ];
}

/// Màn con của Bếp.
List<GoRoute> _kitchenRoutes(KitchenSources kitchen) => [
  GoRoute(
    path: RoutePaths.kitchenMeals,
    builder: (context, state) => KitchenMealsScreen(source: kitchen.meals),
  ),
  GoRoute(
    path: RoutePaths.kitchenQuantities,
    builder: (context, state) =>
        FoodQuantitiesScreen(source: kitchen.quantities),
  ),
  GoRoute(
    path: RoutePaths.kitchenPhotos,
    builder: (context, state) => MealSamplePhotosScreen(source: kitchen.photos),
  ),
  GoRoute(
    path: RoutePaths.kitchenSamples,
    builder: (context, state) => FoodSamplesScreen(source: kitchen.samples),
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
    SelectedSchoolYear.reset();
    ParentSelectedYear.reset();
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
          switchMode: (target) =>
              modes.modes.contains(target) && modes.mode != target
              ? () => modes.switchTo(target)
              : null,
        ),
        notifications: LiveNotificationSource(api),
        parent: ParentSources(
          live: true,
          home: LiveParentHomeSource(api, session),
          leave: LiveLeaveNoticeSource(api),
          myChild: LiveMyChildSource(api),
          evaluation: LiveEvaluationSource(api),
          rewards: LiveRewardSource(api),
          healthBook: LiveHealthBookSource(api),
          schoolYears: LiveChildSchoolYearSource(api),
        ),
        kitchen: _liveKitchen(api),
        teacher: _liveTeacher(api),
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
                  onOpenProfile: () => context.push(
                    '${destination.path}/${RoutePaths.profileSegment}',
                  ),
                  // Mọi vai App không tự đổi mật khẩu: gửi yêu cầu lên HT/PHT (user 25/11) — chờ BE
                  onChangePassword: () =>
                      openComingSoon(context, 'Yêu cầu cấp lại mật khẩu'),
                  onOpenCampuses: role == AppRole.principal
                      ? () => context.push(RoutePaths.principalCampuses)
                      : null,
                  // Bản thật: thu hồi phiên, router tự về Đăng nhập theo phiên
                  onLogout:
                      account.onLogout ??
                      () {
                        SelectedChild.reset();
                        SelectedSchoolYear.reset();
                        ParentSelectedYear.reset();
                        preview_mode.AppMode.reset();
                        context.go(RoutePaths.login);
                      },
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
                      // Phụ huynh phiên thật: nút mở màn của bé theo loại thông báo (PAR-07)
                      actionFor: !live
                          ? null
                          : (item) {
                              final target = switch (role) {
                                AppRole.parent => parentNotificationTarget(
                                  item.type,
                                  item.childId,
                                ),
                                AppRole.kitchen => kitchenNotificationTarget(
                                  item.type,
                                ),
                                _ => null,
                              };
                              if (target == null) return null;
                              return (
                                label: target.label,
                                // Tab Thực đơn bếp là nhánh của thanh đáy ⇒ chuyển tab, không chồng màn
                                open: () =>
                                    target.path == RoutePaths.kitchenMenu
                                    ? context.go(target.path)
                                    : context.push(target.path),
                              );
                            },
                    ),
                  ),
                ],
                NavTab.account => [
                  GoRoute(
                    path: RoutePaths.profileSegment,
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => PersonalInfoScreen(
                      role: role,
                      source: account.source ?? const FakeAccountSource(),
                      readOnly: live,
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

/// Màn con chưa có API ở BE (phiên thật): thanh tiêu đề + "Sắp có".
class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: AppComingSoon(title: title),
  );
}

/// Nguồn bếp phiên thật; "Việc hôm nay" ghép từ ảnh mẫu + sổ lưu mẫu BE trả (user 25/11).
/// Nguồn giáo viên gọi BE. Lớp = lớp `teaches` đầu tiên; danh sách năm học lấy từ BE.
TeacherSources _liveTeacher(MobileApi api) {
  final years = LiveSchoolYearSource(api);
  SelectedSchoolYear.source = years;
  // Năm đang chọn mặc định = năm đang chạy của BE (không dùng năm giả)
  years
      .loadYears()
      .then((list) {
        final active = list
            .where((year) => year.status == SchoolYearStatus.active)
            .firstOrNull;
        if (active != null) SelectedSchoolYear.notifier.value = active;
      })
      .catchError((Object _) {});

  return TeacherSources(
    live: true,
    loadClasses: () => loadTeacherClasses(api),
    home: LiveTeacherHomeSource(api),
    roster: LiveClassRosterSource(api),
    attendance: LiveAttendanceSource(api),
    attendanceSummary: LiveAttendanceSummarySource(api),
    childHealth: LiveChildHealthSource(api),
    dailyHealth: LiveDailyHealthSource(api),
    pickup: LivePickupSource(api),
    leave: LiveClassLeaveSource(api),
    measure: LiveHealthMeasureSource(api),
    review: LiveDailyReviewSource(api),
    evaluation: LiveKidEvaluationSource(api),
    rewards: LiveTeacherRewardSource(api),
  );
}

KitchenSources _liveKitchen(MobileApi api) {
  final photos = LiveKitchenPhotoSource(api);
  final samples = LiveFoodSampleSource(api);
  return KitchenSources(
    home: LiveKitchenHomeSource(
      api,
      tasks: () async {
        final results = await Future.wait([
          photos.loadToday(),
          samples.loadToday(),
        ]);
        return kitchenTasks(
          results[0] as KitchenPhotoDay,
          results[1] as FoodSampleDay,
        );
      },
    ),
    meals: LiveKitchenMealsSource(api),
    quantities: LiveFoodQuantitySource(api),
    samples: samples,
    photos: photos,
    menu: LiveKitchenMenuSource(api),
  );
}

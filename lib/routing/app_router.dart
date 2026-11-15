import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/layouts/app_shell.dart';
import 'package:carenest_app/core/widgets/app_coming_soon.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/account/domain/account_profile.dart';
import 'package:carenest_app/features/account/presentation/screens/account_screen.dart';
import 'package:carenest_app/features/account/presentation/screens/personal_info_screen.dart';
import 'package:carenest_app/features/activity_schedule/presentation/screens/activity_schedule_screen.dart';
import 'package:carenest_app/features/approvals/presentation/screens/approvals_screen.dart';
import 'package:carenest_app/features/approvals/presentation/screens/meal_adjustment_screen.dart';
import 'package:carenest_app/features/approvals/presentation/screens/principal_approvals_screen.dart';
import 'package:carenest_app/features/attendance/data/fake_attendance_source.dart';
import 'package:carenest_app/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/login_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/new_password_screen.dart';
import 'package:carenest_app/features/auth/presentation/screens/otp_verify_screen.dart';
import 'package:carenest_app/features/campus_children/data/fake_campus_children_source.dart';
import 'package:carenest_app/features/campus_children/presentation/screens/campus_children_screen.dart';
import 'package:carenest_app/features/campuses/presentation/screens/campuses_screen.dart';
import 'package:carenest_app/features/class_leave_notices/presentation/screens/class_leave_screen.dart';
import 'package:carenest_app/features/class_roster/presentation/screens/class_roster_screen.dart';
import 'package:carenest_app/features/cooking_status/presentation/screens/cooking_status_screen.dart';
import 'package:carenest_app/features/daily_review/presentation/screens/daily_review_detail_screen.dart';
import 'package:carenest_app/features/daily_review/presentation/screens/daily_review_list_screen.dart';
import 'package:carenest_app/features/dev_preview/presentation/screens/role_preview_screen.dart';
import 'package:carenest_app/features/food_quantities/presentation/screens/food_quantities_screen.dart';
import 'package:carenest_app/features/health_measure/presentation/screens/health_measure_detail_screen.dart';
import 'package:carenest_app/features/health_measure/presentation/screens/health_measure_list_screen.dart';
import 'package:carenest_app/features/ingredient_receipt/presentation/screens/ingredient_receipt_screen.dart';
import 'package:carenest_app/features/ingredient_receipt/presentation/screens/shortage_report_screen.dart';
import 'package:carenest_app/features/kitchen_home/presentation/screens/kitchen_home_screen.dart';
import 'package:carenest_app/features/kitchen_meals/presentation/screens/kitchen_meals_screen.dart';
import 'package:carenest_app/features/leave_notice/presentation/screens/leave_notice_form_screen.dart';
import 'package:carenest_app/features/leave_notice/presentation/screens/leave_notice_list_screen.dart';
import 'package:carenest_app/features/meal_count_confirm/presentation/screens/meal_count_confirm_screen.dart';
import 'package:carenest_app/features/meal_photos/domain/meal_photos.dart';
import 'package:carenest_app/features/meal_photos/presentation/screens/meal_photo_capture_screen.dart';
import 'package:carenest_app/features/meal_photos/presentation/screens/meal_photo_send_screen.dart';
import 'package:carenest_app/features/my_child/presentation/screens/child_activities_screen.dart';
import 'package:carenest_app/features/my_child/presentation/screens/child_attendance_screen.dart';
import 'package:carenest_app/features/my_child/presentation/screens/child_profile_screen.dart';
import 'package:carenest_app/features/my_child/presentation/screens/my_child_screen.dart';
import 'package:carenest_app/features/notifications/presentation/screens/notification_detail_screen.dart';
import 'package:carenest_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:carenest_app/features/nutrition_balance/presentation/screens/nutrition_balance_screen.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/parent_home/domain/parent_today.dart';
import 'package:carenest_app/features/parent_home/presentation/screens/parent_home_screen.dart';
import 'package:carenest_app/features/parent_home/presentation/selected_child.dart';
import 'package:carenest_app/features/parent_menu/presentation/screens/weekly_menu_screen.dart';
import 'package:carenest_app/features/pickup/presentation/screens/pickup_list_screen.dart';
import 'package:carenest_app/features/pickup/presentation/screens/pickup_verify_screen.dart';
import 'package:carenest_app/features/principal_overview/presentation/screens/principal_overview_screen.dart';
import 'package:carenest_app/features/reward_proposals/presentation/screens/reward_batch_screen.dart';
import 'package:carenest_app/features/reward_proposals/presentation/screens/reward_proposals_screen.dart';
import 'package:carenest_app/features/school_children/presentation/screens/school_children_screen.dart';
import 'package:carenest_app/features/school_menu/presentation/screens/school_menu_overview_screen.dart';
import 'package:carenest_app/features/school_menu/presentation/screens/school_menu_screen.dart';
import 'package:carenest_app/features/teacher_home/presentation/screens/teacher_home_screen.dart';
import 'package:carenest_app/features/vice_principal_home/presentation/screens/campus_kitchen_screen.dart';
import 'package:carenest_app/features/vice_principal_home/presentation/screens/campus_menu_screen.dart';
import 'package:carenest_app/features/vice_principal_home/presentation/screens/vice_principal_home_screen.dart';
import 'package:carenest_app/routing/navigation_destinations.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// `enablePreview` mặc định theo debug: màn theo vai trò còn phụ thuộc PENDING và chưa có auth
/// ⇒ bản release chỉ có Đăng nhập và luồng quên mật khẩu (docs/architecture/NAVIGATION.md).
GoRouter buildAppRouter({bool enablePreview = kDebugMode}) {
  final rootKey = GlobalKey<NavigatorState>();
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
        _roleShell(rootKey, AppRole.parent, NavDestinations.parent, {
          RoutePaths.parentToday: (context, state) => const ParentHomeScreen(),
          RoutePaths.parentChild: (context, state) => MyChildScreen(
            initialTab: state.uri.queryParameters['tab'] == 'health'
                ? MyChildTab.health
                : MyChildTab.today,
          ),
        }),
        ..._parentChildRoutes(),
        _roleShell(rootKey, AppRole.teacher, NavDestinations.teacher, {
          RoutePaths.teacherToday: (context, state) =>
              const TeacherHomeScreen(),
          RoutePaths.teacherClass: (context, state) =>
              const ClassRosterScreen(),
        }),
        ..._teacherRoutes(),
        GoRoute(
          path: RoutePaths.teacherAttendance,
          // Lớp đang chọn là state; bản dữ liệu giả chỉ có một lớp
          builder: (context, state) =>
              const AttendanceScreen(classId: FakeAttendanceSource.classId),
        ),
        _roleShell(rootKey, AppRole.kitchen, NavDestinations.kitchen, {
          RoutePaths.kitchenHome: (context, state) => const KitchenHomeScreen(),
          RoutePaths.kitchenMenu: (context, state) => SchoolMenuScreen(
            asTab: true,
            initialDay: FakeParentHomeSource.today,
            footerNote:
                'Chỉ xem. Thực đơn mẫu theo nhóm tuổi do Phó hiệu trưởng lập và công bố trên web.',
          ),
        }),
        ..._kitchenRoutes(),
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

/// Màn con của Phụ huynh: route chỉ mang ID con; ID không thuộc danh sách con ⇒ 404.
List<GoRoute> _parentChildRoutes() {
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
      RoutePaths.parentChildProfile,
      (context, state, child) => ChildProfileScreen(childId: child.id),
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
      (context, id) =>
          DailyReviewDetailScreen(childId: id, onSaved: () => context.pop()),
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
      (context, id) =>
          HealthMeasureDetailScreen(childId: id, onSaved: () => context.pop()),
    ),
    GoRoute(
      path: RoutePaths.teacherSchedule,
      builder: (context, state) => ActivityScheduleScreen(
        initialDay: FakeParentHomeSource.today,
        onReviewToday: () => context.pushReplacement(RoutePaths.teacherReviews),
      ),
    ),
    GoRoute(
      path: RoutePaths.teacherMealPhotos,
      builder: (context, state) => MealPhotoCaptureScreen(
        onNext: (slot) => context.push(
          Uri(
            path: RoutePaths.teacherMealPhotosSend,
            queryParameters: {'slot': slot.name},
          ).toString(),
        ),
      ),
    ),
    GoRoute(
      path: RoutePaths.teacherMealPhotosSend,
      builder: (context, state) {
        final slot = MealSlot.values
            .where((item) => item.name == state.uri.queryParameters['slot'])
            .firstOrNull;
        if (slot == null) return const NotFoundScreen();
        // Gửi xong ⇒ về Trang chủ, bỏ hai màn chụp/gửi khỏi back stack
        return MealPhotoSendScreen(
          slot: slot,
          onSent: () => context.go(RoutePaths.teacherToday),
        );
      },
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
    path: RoutePaths.kitchenReceipts,
    builder: (context, state) => IngredientReceiptScreen(
      onReportShortage: () => context.push(RoutePaths.kitchenShortage),
      onConfirmed: () => context.pop(),
    ),
  ),
  GoRoute(
    path: RoutePaths.kitchenShortage,
    builder: (context, state) =>
        ShortageReportScreen(onSent: () => context.pop()),
  ),
  GoRoute(
    path: RoutePaths.kitchenCooking,
    builder: (context, state) => const CookingStatusScreen(),
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

/// Một nhánh tab cho mỗi đích; Thông báo và Tài khoản dùng chung mọi vai trò,
/// đích chưa có màn thì hiện "Sắp có". Màn con mở trên navigator gốc (ẩn thanh đáy).
StatefulShellRoute _roleShell(
  GlobalKey<NavigatorState> rootKey,
  AppRole role,
  List<NavDestination> destinations,
  Map<String, GoRouterWidgetBuilder> screens,
) {
  return StatefulShellRoute.indexedStack(
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
                  onOpen: (id) => context.push('${destination.path}/$id'),
                ),
                NavTab.account => AccountScreen(
                  role: role,
                  onOpenProfile: () => context.push(
                    '${destination.path}/${RoutePaths.profileSegment}',
                  ),
                  onChangePassword: () => context.push(
                    '${destination.path}/${RoutePaths.passwordSegment}',
                  ),
                  onOpenCampuses: role == AppRole.principal
                      ? () => context.push(RoutePaths.principalCampuses)
                      : null,
                  // Chưa có phiên thật ⇒ đăng xuất chỉ về Đăng nhập, xoá back stack
                  onLogout: () {
                    SelectedChild.reset();
                    context.go(RoutePaths.login);
                  },
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
                    ),
                  ),
                ],
                NavTab.account => [
                  GoRoute(
                    path: RoutePaths.profileSegment,
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => PersonalInfoScreen(role: role),
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

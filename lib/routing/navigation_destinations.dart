import 'package:flutter/widgets.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Vai trò của tab trong khung: thông báo và tài khoản dùng chung mọi nhóm.
enum NavTab { home, primary, notifications, account }

/// Đích thanh đáy theo nhóm người dùng, khai báo một lần (DESIGN.md §8.1, §8.4).
@immutable
class NavDestination {
  const NavDestination(this.label, this.icon, this.path, this.tab);

  final String label;
  final IconData icon;
  final String path;
  final NavTab tab;
}

/// Nhãn tab theo mockup `docs/design/figma/` (plan 2026-10-13-ui-mockup-redesign).
abstract final class NavDestinations {
  static const parent = [
    NavDestination(
      'Trang chủ',
      AppIcons.home,
      RoutePaths.parentToday,
      NavTab.home,
    ),
    NavDestination(
      'Bé của tôi',
      AppIcons.childFace,
      RoutePaths.parentChild,
      NavTab.primary,
    ),
    NavDestination(
      'Thông báo',
      AppIcons.bell,
      RoutePaths.parentNotifications,
      NavTab.notifications,
    ),
    NavDestination(
      'Tài khoản',
      AppIcons.account,
      RoutePaths.parentAccount,
      NavTab.account,
    ),
  ];

  static const teacher = [
    NavDestination(
      'Trang chủ',
      AppIcons.home,
      RoutePaths.teacherToday,
      NavTab.home,
    ),
    NavDestination(
      'Lớp học',
      AppIcons.classGroup,
      RoutePaths.teacherClass,
      NavTab.primary,
    ),
    NavDestination(
      'Thông báo',
      AppIcons.bell,
      RoutePaths.teacherNotifications,
      NavTab.notifications,
    ),
    NavDestination(
      'Tài khoản',
      AppIcons.account,
      RoutePaths.teacherAccount,
      NavTab.account,
    ),
  ];

  static const kitchen = [
    NavDestination(
      'Trang chủ',
      AppIcons.home,
      RoutePaths.kitchenHome,
      NavTab.home,
    ),
    NavDestination(
      'Thực đơn',
      AppIcons.kitchen,
      RoutePaths.kitchenMenu,
      NavTab.primary,
    ),
    NavDestination(
      'Thông báo',
      AppIcons.bell,
      RoutePaths.kitchenNotifications,
      NavTab.notifications,
    ),
    NavDestination(
      'Tài khoản',
      AppIcons.account,
      RoutePaths.kitchenAccount,
      NavTab.account,
    ),
  ];

  static const vicePrincipal = [
    NavDestination(
      'Trang chủ',
      AppIcons.home,
      RoutePaths.vicePrincipalHome,
      NavTab.home,
    ),
    NavDestination(
      'Duyệt',
      AppIcons.approval,
      RoutePaths.vicePrincipalApprovals,
      NavTab.primary,
    ),
    NavDestination(
      'Thông báo',
      AppIcons.bell,
      RoutePaths.vicePrincipalNotifications,
      NavTab.notifications,
    ),
    NavDestination(
      'Tài khoản',
      AppIcons.account,
      RoutePaths.vicePrincipalAccount,
      NavTab.account,
    ),
  ];

  static const principal = [
    NavDestination(
      'Tổng quan',
      AppIcons.home,
      RoutePaths.principalHome,
      NavTab.home,
    ),
    NavDestination(
      'Duyệt',
      AppIcons.approval,
      RoutePaths.principalApprovals,
      NavTab.primary,
    ),
    NavDestination(
      'Thông báo',
      AppIcons.bell,
      RoutePaths.principalNotifications,
      NavTab.notifications,
    ),
    NavDestination(
      'Tài khoản',
      AppIcons.account,
      RoutePaths.principalAccount,
      NavTab.account,
    ),
  ];
}

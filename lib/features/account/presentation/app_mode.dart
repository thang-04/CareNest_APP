import 'package:carenest_app/features/account/domain/account_profile.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Màn đầu của mỗi chế độ, dùng khi mở phiên hoặc chuyển chế độ.
String homePathOf(AppRole mode) => switch (mode) {
  AppRole.parent => RoutePaths.parentToday,
  AppRole.teacher => RoutePaths.teacherToday,
  AppRole.kitchen => RoutePaths.kitchenHome,
  AppRole.vicePrincipal => RoutePaths.vicePrincipalHome,
  AppRole.principal => RoutePaths.principalHome,
};

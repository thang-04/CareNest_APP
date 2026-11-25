import 'package:carenest_app/features/auth/domain/entities/app_mode.dart';
import 'package:carenest_app/features/shared/account/domain/account_profile.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Màn chính của từng chế độ.
String homePathFor(AppMode mode) => switch (mode) {
  AppMode.teacher => RoutePaths.teacherToday,
  AppMode.kitchen => RoutePaths.kitchenHome,
  AppMode.parent => RoutePaths.parentToday,
};

/// Shell (bộ tab) dùng cho chế độ.
AppRole shellRoleFor(AppMode mode) => switch (mode) {
  AppMode.teacher => AppRole.teacher,
  AppMode.kitchen => AppRole.kitchen,
  AppMode.parent => AppRole.parent,
};

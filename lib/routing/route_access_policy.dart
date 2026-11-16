import 'package:carenest_app/features/account/domain/account_profile.dart';
import 'package:carenest_app/features/auth/domain/entities/app_mode.dart';
import 'package:carenest_app/features/auth/presentation/controllers/auth_state.dart';
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

/// Chuyển màn theo phiên khi chạy với BE thật. Chỉ là UX: quyền thật do BE kiểm (AUTH-07).
/// `location` là path không query (`GoRouterState.matchedLocation`).
String? redirectFor(AuthState state, String location) {
  String? stayOr(String target, {Set<String> allowed = const {}}) =>
      location == target || allowed.contains(location) ? null : target;

  return switch (state) {
    AuthChecking() || AuthRetryNeeded() => stayOr(RoutePaths.splash),
    AuthSignedOut() || AuthSigningIn() => stayOr(
      RoutePaths.login,
      allowed: const {RoutePaths.activate},
    ),
    AuthBlocked() => stayOr(RoutePaths.blocked),
    AuthSignedIn(:final mode) =>
      _belongsTo(mode, location) ? null : homePathFor(mode),
  };
}

// Màn của chế độ khác (vd. đổi sang phụ huynh khi đang ở tab GV) ⇒ về màn chính của chế độ hiện tại
bool _belongsTo(AppMode mode, String location) {
  final home = homePathFor(mode);
  return location == home || location.startsWith('$home/');
}

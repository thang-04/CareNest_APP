import 'package:carenest_app/features/auth/domain/entities/app_mode.dart';
import 'package:carenest_app/routing/route_access_policy.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Chuyển màn của phiên thật (PR #8). Chỉ là UX: quyền thật do BE kiểm (AUTH-07).
/// `location` là path không query (`GoRouterState.matchedLocation`).
String? liveRedirect({
  required bool signedIn,
  required AppMode? mode,
  required String location,
}) {
  String? stayOr(String target) => location == target ? null : target;

  if (!signedIn) {
    return location == RoutePaths.activate ? null : stayOr(RoutePaths.login);
  }
  if (mode == null) return stayOr(RoutePaths.liveUnsupported);
  // Lối vào /live/... tự chuyển sang tab của chế độ ở route riêng
  if (location.startsWith('/live/') && location != RoutePaths.liveUnsupported) {
    return null;
  }
  final home = homePathFor(mode);
  return location == home || location.startsWith('$home/') ? null : home;
}

import 'package:carenest_app/core/integration/mobile_session.dart';
import 'package:carenest_app/features/shared/account/domain/account_profile.dart';

/// Hồ sơ của phiên đăng nhập thật, lấy từ `/accounts/me` đã tải khi đăng nhập.
class LiveAccountSource implements AccountSource {
  const LiveAccountSource(this.session);

  final MobileSession session;

  @override
  Future<AccountProfile> loadProfile(AppRole role) async {
    final account = session.account ?? const {};
    return AccountProfile(
      fullName: account['fullName']?.toString() ?? '',
      // BE chưa trả số điện thoại ở `/accounts/me`; hiện tên đăng nhập
      phone: account['username']?.toString() ?? '',
      email: account['email']?.toString(),
      role: role,
    );
  }
}

/// Vai trò App hỗ trợ theo DESIGN.md §B5.2; BGH, Admin dùng Web (AUTH-21) ⇒ null.
AppRole? liveRoleOf(MobileSession session) {
  final roles = session.account?['roles'] as List? ?? const [];
  for (final role in roles) {
    switch (role) {
      case 'PARENT':
        return AppRole.parent;
      case 'TEACHER':
        return AppRole.teacher;
      case 'KITCHEN_STAFF':
        return AppRole.kitchen;
    }
  }
  return null;
}

import 'package:carenest_app/core/integration/mobile_session.dart';
import 'package:carenest_app/features/shared/account/domain/account_profile.dart';
import 'package:carenest_app/features/shared/app_mode/app_mode.dart';

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
/// GV kiêm phụ huynh ⇒ theo chế độ đang chọn (`AppMode`), mặc định chế độ nhân sự.
AppRole? liveRoleOf(MobileSession session) {
  final roles = session.account?['roles'] as List? ?? const [];
  final childIds = session.account?['childIds'] as List? ?? const [];
  return AppMode.resolve(AppMode.appRolesOf(roles, childIds));
}

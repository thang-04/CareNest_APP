/// Scope xin Keycloak. Phiên thường (plan 2026-11-16 quyết định 9); đổi sang phiên dài thì thêm
/// `offline_access` và làm task BE cho client `carenest-mobile`.
const kOidcScopes = ['openid', 'profile'];

/// Token Keycloak trả sau đăng nhập hoặc refresh.
class OidcTokens {
  const OidcTokens({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    this.idToken,
  });

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final String? idToken;
}

sealed class OidcFailure implements Exception {
  const OidcFailure();
}

/// Người dùng đóng trang đăng nhập.
final class OidcCancelled extends OidcFailure {
  const OidcCancelled();
}

/// Refresh token hết hạn hoặc bị thu hồi ⇒ phải đăng nhập lại.
final class OidcInvalidGrant extends OidcFailure {
  const OidcInvalidGrant();
}

/// Không dùng được Keycloak lúc này ⇒ cho thử lại, không đăng xuất. `network` = lỗi mạng;
/// `false` = Keycloak từ chối vì cấu hình (vd. `unauthorized_client`) — báo lỗi chung, không bảo kiểm mạng.
final class OidcUnavailable extends OidcFailure {
  const OidcUnavailable(this.cause, {this.network = true});

  final Object cause;
  final bool network;

  @override
  String toString() => 'OidcUnavailable($cause)';
}

/// Đăng nhập Authorization Code + PKCE với Keycloak (BE AUTH_CONTRACT, client `carenest-mobile`).
abstract interface class OidcClient {
  Future<OidcTokens> signIn({String? loginHint});
  Future<OidcTokens> refresh(String refreshToken);

  /// Thu hồi phiên ở Keycloak; lỗi ⇒ [OidcUnavailable] (bên gọi vẫn xóa token trên máy).
  Future<void> revoke(String refreshToken);
}

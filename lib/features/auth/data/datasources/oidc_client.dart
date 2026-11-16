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

/// Không liên lạc được Keycloak hoặc kết quả không dùng được ⇒ cho thử lại, không đăng xuất.
final class OidcUnavailable extends OidcFailure {
  const OidcUnavailable(this.cause);

  final Object cause;

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

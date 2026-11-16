import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

import 'package:carenest_app/features/auth/data/datasources/oidc_client.dart';

/// [OidcClient] qua `flutter_appauth` (AppAuth Android/iOS mở trang Keycloak bằng trình duyệt hệ thống).
class AppAuthOidcClient implements OidcClient {
  AppAuthOidcClient({
    required this._appAuth,
    required this._plainDio,
    required this._issuer,
    required this._clientId,
    required this._redirectUri,
  });

  final FlutterAppAuth _appAuth;
  final Dio _plainDio;
  final String _issuer;
  final String _clientId;
  final String _redirectUri;

  // Keycloak local chạy http://localhost (adb reverse); chỉ bản debug được dùng HTTP
  bool get _allowInsecure => kDebugMode && _issuer.startsWith('http://');

  @override
  Future<OidcTokens> signIn({String? loginHint}) async {
    final TokenResponse response;
    try {
      response = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUri,
          issuer: _issuer,
          scopes: kOidcScopes,
          loginHint: loginHint,
          // Luôn hỏi mật khẩu: không tự đăng nhập lại bằng cookie Keycloak của người dùng trước (máy bếp dùng chung)
          promptValues: const ['login'],
          externalUserAgent:
              ExternalUserAgent.ephemeralAsWebAuthenticationSession,
          allowInsecureConnections: _allowInsecure,
        ),
      );
    } catch (error) {
      throw mapAppAuthError(error);
    }
    return _tokens(response);
  }

  @override
  Future<OidcTokens> refresh(String refreshToken) async {
    final TokenResponse response;
    try {
      response = await _appAuth.token(
        TokenRequest(
          _clientId,
          _redirectUri,
          issuer: _issuer,
          refreshToken: refreshToken,
          scopes: kOidcScopes,
          allowInsecureConnections: _allowInsecure,
        ),
      );
    } catch (error) {
      throw mapAppAuthError(error);
    }
    return _tokens(response, previousRefreshToken: refreshToken);
  }

  @override
  Future<void> revoke(String refreshToken) async {
    try {
      await _plainDio.post<Object?>(
        '$_issuer/protocol/openid-connect/logout',
        data: {'client_id': _clientId, 'refresh_token': refreshToken},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
    } on DioException catch (error) {
      throw OidcUnavailable(error);
    }
  }

  OidcTokens _tokens(TokenResponse response, {String? previousRefreshToken}) {
    final access = response.accessToken;
    final expiresAt = response.accessTokenExpirationDateTime;
    // Keycloak không đổi refresh token khi refresh ⇒ giữ token cũ
    final refresh = response.refreshToken ?? previousRefreshToken;
    if (access == null || expiresAt == null || refresh == null) {
      throw OidcUnavailable(StateError('token response is incomplete'));
    }
    return OidcTokens(
      accessToken: access,
      accessTokenExpiresAt: expiresAt,
      refreshToken: refresh,
      idToken: response.idToken,
    );
  }
}

/// Lỗi AppAuth ⇒ [OidcFailure]: đóng trang ⇒ hủy; `invalid_grant` ⇒ phiên hết; còn lại ⇒ thử lại được.
OidcFailure mapAppAuthError(Object error) {
  if (error is OidcFailure) return error;
  if (error is FlutterAppAuthUserCancelledException) {
    return const OidcCancelled();
  }
  if (error is FlutterAppAuthPlatformException) {
    final oauthError = error.platformErrorDetails.error;
    if (oauthError == 'invalid_grant') return const OidcInvalidGrant();
    // Có mã lỗi OAuth ⇒ Keycloak đã trả lời và từ chối, không phải mất mạng
    if (oauthError != null) return OidcUnavailable(oauthError, network: false);
  }
  if (error is PlatformException) return OidcUnavailable(error.code);
  return OidcUnavailable(error);
}

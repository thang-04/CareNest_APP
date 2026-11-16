/// Cấu hình môi trường đọc từ `--dart-define` (docs/architecture/CODING_GUIDE.md §1.2). Không chứa bí mật.
abstract final class Env {
  /// Base URL đã gồm tiền tố API, vd. `http://localhost:8080/api`.
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);
  static const appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  /// Issuer Keycloak, vd. `http://localhost:8180/realms/carenest` (BE AUTH_CONTRACT).
  static const oidcIssuer = String.fromEnvironment('OIDC_ISSUER');
  static const oidcClientId = String.fromEnvironment(
    'OIDC_CLIENT_ID',
    defaultValue: 'carenest-mobile',
  );
  static const oidcRedirectUri = String.fromEnvironment(
    'OIDC_REDIRECT_URI',
    defaultValue: 'carenest://oauth/callback',
  );

  /// Tên biến bắt buộc còn thiếu khi chạy với BE thật; bản giả không cần biến nào.
  static List<String> missingKeys({
    required bool useMock,
    required String apiBaseUrl,
    required String oidcIssuer,
  }) {
    if (useMock) return const [];
    return [
      if (apiBaseUrl.isEmpty) 'API_BASE_URL',
      if (oidcIssuer.isEmpty) 'OIDC_ISSUER',
    ];
  }
}

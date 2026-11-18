class MobileConfig {
  static const apiBaseUrl = String.fromEnvironment('CARENEST_API_BASE_URL');
  static const issuer = String.fromEnvironment('CARENEST_OIDC_ISSUER');
  static const clientId = 'carenest-mobile';
  static const redirectUri = 'carenest://oauth/callback';

  static bool get configured => apiBaseUrl.isNotEmpty && issuer.isNotEmpty;
}

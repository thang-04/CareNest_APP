/// Cấu hình môi trường đọc từ `--dart-define` (docs/architecture/CODING_GUIDE.md §1.2). Không chứa bí mật.
/// Địa chỉ BE và Keycloak: `MobileConfig` (`CARENEST_API_BASE_URL`, `CARENEST_OIDC_ISSUER`).
abstract final class Env {
  static const appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
}

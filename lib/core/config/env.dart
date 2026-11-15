/// Cấu hình môi trường đọc từ `--dart-define` (docs/architecture/CODING_GUIDE.md §1.2). Không chứa bí mật.
abstract final class Env {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);
  static const appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
}

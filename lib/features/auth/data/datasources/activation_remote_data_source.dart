import 'package:carenest_app/core/network/api_client.dart';

/// Kích hoạt tài khoản phụ huynh bằng mã SMS (BE AUTH-18, ADR-0026). API công khai: không Bearer.
class ActivationRemoteDataSource {
  ActivationRemoteDataSource(this._api);

  final ApiClient _api;

  /// Trả tên đăng nhập để mở trang Keycloak có sẵn tên.
  Future<String> activate({
    required String phone,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) => _api.post(
    '/parent-activation',
    skipAuth: true,
    body: {
      'phone': phone,
      'code': code,
      'newPassword': newPassword, // carenest:allow-secret — tên field API BE
      'confirmPassword':
          confirmPassword, // carenest:allow-secret — tên field API BE
    },
    decode: (data) => (data! as Map)['username'] as String,
  );
}

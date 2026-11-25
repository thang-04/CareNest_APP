import 'package:carenest_app/core/integration/mobile_api.dart';

/// Kích hoạt tài khoản phụ huynh bằng mã SMS (BE AUTH-18, ADR-0026); trả tên đăng nhập.
abstract interface class ActivationGateway {
  Future<String> activate({
    required String phone,
    required String code,
    required String newPassword,
    required String confirmPassword,
  });
}

/// `POST /parent-activation` là API công khai: không Bearer.
class ActivationApi implements ActivationGateway {
  const ActivationApi(this._api);

  final MobileApi _api;

  @override
  Future<String> activate({
    required String phone,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final data = await _api.publicJson(
      'POST',
      '/parent-activation',
      body: {
        'phone': phone,
        'code': code,
        'newPassword': newPassword, // carenest:allow-secret — tên field API BE
        'confirmPassword':
            confirmPassword, // carenest:allow-secret — tên field API BE
      },
    );
    return (data! as Map)['username'] as String;
  }
}

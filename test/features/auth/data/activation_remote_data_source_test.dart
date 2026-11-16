import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/errors/app_failure.dart';
import 'package:carenest_app/core/network/api_client.dart';
import 'package:carenest_app/features/auth/data/datasources/activation_remote_data_source.dart';

import '../../../helpers/fake_http_adapter.dart';

// Mật khẩu giả cho test
const _pw = 'MatKhau#2026'; // carenest:allow-secret — giá trị giả

void main() {
  late FakeHttpAdapter adapter;
  late ActivationRemoteDataSource source;

  setUp(() {
    adapter = FakeHttpAdapter();
    source = ActivationRemoteDataSource(
      ApiClient(
        Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
          ..httpClientAdapter = adapter,
      ),
    );
  });

  test('activate_postsPublicRequest_returnsUsername', () async {
    adapter.enqueue(FakeReply.envelope(200, data: {'username': '0900000001'}));

    final username = await source.activate(
      phone: '0900000001',
      code: '123456',
      newPassword: _pw,
      confirmPassword: _pw,
    );

    final request = adapter.requests.single;
    expect(username, '0900000001');
    expect(request.method, 'POST');
    expect(request.uri.path, '/api/parent-activation');
    expect(request.extra['skipAuth'], isTrue);
    expect(request.data, {
      'phone': '0900000001',
      'code': '123456',
      'newPassword': _pw,
      'confirmPassword': _pw,
    });
  });

  test('activate_wrongCode_throwsValidation1006', () async {
    adapter.enqueue(FakeReply.envelope(400, errorCode: 1006, desc: 'Mã sai'));

    await expectLater(
      source.activate(
        phone: '0900000001',
        code: '000000',
        newPassword: _pw,
        confirmPassword: _pw,
      ),
      throwsA(
        isA<ValidationFailure>().having((f) => f.errorCode, 'errorCode', 1006),
      ),
    );
  });
}

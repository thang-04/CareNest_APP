import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/integration/mobile_session.dart';
import 'package:carenest_app/features/auth/data/activation_api.dart';

class _NoSession implements MobileCredentials {
  @override
  int? get userId => null;
  @override
  int get generation => 0;
  @override
  Future<String> accessToken({bool force = false}) =>
      throw StateError('không có phiên');
}

// Mật khẩu giả cho test
const _pw = 'MatKhau#2026'; // carenest:allow-secret — giá trị giả

void main() {
  test('activate_postsFourFieldsWithoutAuth_returnsUsername', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    String? line;
    String? auth = 'unset';
    Object? body;
    server.listen((request) async {
      line = '${request.method} ${request.uri.path}';
      auth = request.headers.value(HttpHeaders.authorizationHeader);
      body = jsonDecode(await utf8.decoder.bind(request).join());
      request.response.write(
        jsonEncode({
          'code': 200,
          'data': {'username': '0900000001'},
        }),
      );
      await request.response.close();
    });
    final api = ActivationApi(
      MobileApi(_NoSession(), baseUrl: 'http://127.0.0.1:${server.port}/api'),
    );

    final username = await api.activate(
      phone: '0900000001',
      code: '123456',
      newPassword: _pw,
      confirmPassword: _pw,
    );

    expect(username, '0900000001');
    expect(line, 'POST /api/parent-activation');
    expect(auth, isNull);
    expect(body, {
      'phone': '0900000001',
      'code': '123456',
      'newPassword': _pw, // carenest:allow-secret — tên field API BE
      'confirmPassword': _pw, // carenest:allow-secret — tên field API BE
    });
  });
}

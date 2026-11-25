import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/integration/mobile_session.dart';

/// Chưa đăng nhập: không có người dùng, không lấy được token.
class _NoSession implements MobileCredentials {
  @override
  int? get userId => null;
  @override
  int get generation => 0;
  @override
  Future<String> accessToken({bool force = false}) =>
      throw StateError('không có phiên');
}

void main() {
  late HttpServer server;
  late MobileApi api;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    api = MobileApi(
      _NoSession(),
      baseUrl: 'http://127.0.0.1:${server.port}/api',
    );
  });
  tearDown(() => server.close(force: true));

  test('publicJson_sendsNoAuthorization', () async {
    String? auth = 'unset';
    Object? payload;
    server.listen((request) async {
      auth = request.headers.value(HttpHeaders.authorizationHeader);
      payload = jsonDecode(await utf8.decoder.bind(request).join());
      request.response.write(
        jsonEncode({
          'code': 200,
          'data': {'username': '0912345678'},
        }),
      );
      await request.response.close();
    });

    final data = await api.publicJson(
      'POST',
      '/parent-activation',
      body: {'phone': '0912345678'},
    );

    expect(auth, isNull);
    expect(payload, {'phone': '0912345678'});
    expect(data, {'username': '0912345678'});
  });

  test('publicJson_400_throwsApiFailureWithErrorCode', () async {
    var calls = 0;
    server.listen((request) async {
      calls++;
      request.response.statusCode = 400;
      request.response.write(
        jsonEncode({'code': 400, 'errorCode': 1006, 'desc': 'Mã sai'}),
      );
      await request.response.close();
    });

    await expectLater(
      api.publicJson('POST', '/parent-activation', body: const {}),
      throwsA(
        isA<ApiFailure>()
            .having((e) => e.status, 'status', 400)
            .having((e) => e.errorCode, 'errorCode', 1006)
            .having((e) => e.message, 'message', 'Mã sai'),
      ),
    );
    expect(calls, 1);
  });
}

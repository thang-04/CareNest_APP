import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/integration/mobile_session.dart';

class FakeCredentials implements MobileCredentials {
  @override
  int? userId = 5;
  @override
  int generation = 0;
  int refreshes = 0;
  @override
  Future<String> accessToken({bool force = false}) async {
    if (force) refreshes++;
    return force ? 'new-token' : 'old-token';
  }
}

void main() {
  late HttpServer server;
  late FakeCredentials credentials;
  late MobileApi api;
  setUp(() async {
    credentials = FakeCredentials();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    api = MobileApi(
      credentials,
      baseUrl: 'http://127.0.0.1:${server.port}/api',
    );
  });
  tearDown(() => server.close(force: true));

  test(
    'device registration refreshes once after 401 and sends backend DTO',
    () async {
      final methods = <String>[];
      server.listen((request) async {
        methods.add('${request.method} ${request.uri.path}');
        final payload = jsonDecode(await utf8.decoder.bind(request).join());
        expect(payload, {'token': 'fake-token', 'platform': 'ANDROID'});
        if (request.headers.value(HttpHeaders.authorizationHeader) ==
            'Bearer old-token') {
          request.response.statusCode = 401;
        } else {
          request.response.write(jsonEncode({'code': 200, 'data': null}));
        }
        await request.response.close();
      });
      await api.registerDevice('fake-token');
      expect(credentials.refreshes, 1);
      expect(methods, ['PUT /api/me/devices', 'PUT /api/me/devices']);
    },
  );

  test('403 giữ mã backend, không gửi lại và không lộ nội dung', () async {
    var calls = 0;
    server.listen((request) async {
      calls++;
      request.response.statusCode = 403;
      request.response.write(
        jsonEncode({'errorCode': 1203, 'desc': 'Không có quyền'}),
      );
      await request.response.close();
    });
    await expectLater(
      api.json('GET', '/me/notifications/1'),
      throwsA(
        isA<ApiFailure>()
            .having((e) => e.status, 'status', 403)
            .having((e) => e.errorCode, 'code', 1203),
      ),
    );
    expect(calls, 1);
  });

  test(
    'không trả nội dung cho phiên mới khi tài khoản đổi trong lúc chờ',
    () async {
      server.listen((request) async {
        credentials.generation++;
        request.response.write(
          jsonEncode({
            'code': 200,
            'data': {'title': 'Nội dung giả'},
          }),
        );
        await request.response.close();
      });
      await expectLater(
        api.json('GET', '/me/notifications/1'),
        throwsA(isA<ApiFailure>().having((e) => e.status, 'status', 401)),
      );
    },
  );
}

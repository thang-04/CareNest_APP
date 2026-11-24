import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/integration/mobile_session.dart';

class _Credentials implements MobileCredentials {
  int refreshes = 0;
  @override
  int? get userId => 5;
  @override
  int get generation => 0;
  @override
  Future<String> accessToken({bool force = false}) async {
    if (force) refreshes++;
    return force ? 'new-token' : 'old-token';
  }
}

void main() {
  late HttpServer server;
  late _Credentials credentials;
  late MobileApi api;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    credentials = _Credentials();
    api = MobileApi(
      credentials,
      baseUrl: 'http://127.0.0.1:${server.port}/api',
    );
  });
  tearDown(() => server.close(force: true));

  Future<Object?> upload() => api.multipart(
    'PUT',
    '/accounts/me/photo',
    field: 'file',
    bytes: Uint8List.fromList([1, 2, 3]),
    filename: 'chan-dung.jpg',
    contentType: 'image/jpeg',
  );

  test('multipart_sendsFilePartWithBearer', () async {
    String? type;
    String? auth;
    String? body;
    server.listen((request) async {
      type = request.headers.contentType?.mimeType;
      auth = request.headers.value(HttpHeaders.authorizationHeader);
      body = latin1.decode(
        await request.fold<List<int>>([], (all, chunk) => all..addAll(chunk)),
      );
      request.response.write(
        jsonEncode({
          'code': 200,
          'data': {'photoUploaded': true},
        }),
      );
      await request.response.close();
    });

    final data = await upload();

    expect(type, 'multipart/form-data');
    expect(auth, 'Bearer old-token');
    expect(body, contains('name="file"; filename="chan-dung.jpg"'));
    expect(body, contains('Content-Type: image/jpeg'));
    expect(body, contains(latin1.decode([1, 2, 3])));
    expect(data, {'photoUploaded': true});
  });

  test('multipart_401_refreshesOnceAndResendsFile', () async {
    final bodies = <int>[];
    server.listen((request) async {
      final bytes = await request.fold<List<int>>(
        [],
        (all, chunk) => all..addAll(chunk),
      );
      bodies.add(bytes.length);
      if (request.headers.value(HttpHeaders.authorizationHeader) ==
          'Bearer old-token') {
        request.response.statusCode = 401;
      } else {
        request.response.write(jsonEncode({'code': 200, 'data': null}));
      }
      await request.response.close();
    });

    await upload();

    expect(credentials.refreshes, 1);
    expect(bodies, hasLength(2));
    expect(bodies.first, bodies.last);
  });
}

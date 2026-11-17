import 'dart:convert';
import 'dart:io';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carenest_app/core/integration/mobile_session.dart';

class FakeAppAuth extends FlutterAppAuth {
  int refreshes = 0;
  AuthorizationTokenRequest? authorization;
  @override
  Future<AuthorizationTokenResponse> authorizeAndExchangeCode(
    AuthorizationTokenRequest request,
  ) async {
    authorization = request;
    return AuthorizationTokenResponse(
      'access-1',
      'refresh-1',
      DateTime.now().add(const Duration(minutes: 5)),
      null,
      'Bearer',
      null,
      null,
      null,
    );
  }

  @override
  Future<TokenResponse> token(TokenRequest request) async {
    refreshes++;
    return TokenResponse(
      'access-2',
      'refresh-2',
      DateTime.now().add(const Duration(minutes: 5)),
      null,
      'Bearer',
      null,
      null,
    );
  }
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'đăng nhập PKCE, xác minh tài khoản, refresh một lần và xóa phiên khi logout',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final base = 'http://127.0.0.1:${server.port}';
      final requests = <String>[];
      server.listen((request) async {
        requests.add('${request.method} ${request.uri.path}');
        if (request.uri.path == '/api/accounts/me') {
          expect(
            request.headers.value(HttpHeaders.authorizationHeader),
            'Bearer access-1',
          );
          request.response.write(
            jsonEncode({
              'code': 200,
              'data': {
                'userId': 7,
                'roles': ['PARENT'],
                'profileUpdateRequired': false,
              },
            }),
          );
        }
        await request.response.close();
      });
      final auth = FakeAppAuth();
      const storage = FlutterSecureStorage();
      final session = MobileSession(
        auth: auth,
        storage: storage,
        apiBaseUrl: '$base/api',
        issuer: base,
      );
      await session.signIn();
      expect(session.userId, 7);
      expect(auth.authorization?.clientId, 'carenest-mobile');
      expect(auth.authorization?.redirectUrl, 'carenest://oauth/callback');
      expect(await storage.read(key: 'auth.refresh'), 'refresh-1');
      final tokens = await Future.wait([
        session.accessToken(force: true),
        session.accessToken(force: true),
      ]);
      expect(tokens, ['access-2', 'access-2']);
      expect(auth.refreshes, 1);
      expect(await storage.read(key: 'auth.refresh'), 'refresh-2');
      await session.signOut();
      expect(session.signedIn, isFalse);
      expect(await storage.read(key: 'auth.refresh'), isNull);
      expect(requests, [
        'GET /api/accounts/me',
        'POST /protocol/openid-connect/logout',
      ]);
      await server.close(force: true);
      session.dispose();
    },
  );
}

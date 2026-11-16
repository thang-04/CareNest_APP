import 'package:dio/dio.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/auth/data/datasources/app_auth_oidc_client.dart';
import 'package:carenest_app/features/auth/data/datasources/oidc_client.dart';

import '../../../helpers/fake_http_adapter.dart';

const _issuer = 'http://localhost:8180/realms/carenest';

/// FlutterAppAuth giả: ghi request, trả response hoặc ném lỗi đã cấu hình.
class _RecordingAppAuth implements FlutterAppAuth {
  AuthorizationTokenRequest? lastAuthorize;
  TokenRequest? lastToken;
  Object? error;
  AuthorizationTokenResponse? authorizeResponse;
  TokenResponse? tokenResponse;

  @override
  Future<AuthorizationTokenResponse> authorizeAndExchangeCode(
    AuthorizationTokenRequest request,
  ) async {
    lastAuthorize = request;
    if (error != null) throw error!;
    return authorizeResponse!;
  }

  @override
  Future<TokenResponse> token(TokenRequest request) async {
    lastToken = request;
    if (error != null) throw error!;
    return tokenResponse!;
  }

  @override
  Future<AuthorizationResponse> authorize(AuthorizationRequest request) =>
      throw UnimplementedError();

  @override
  Future<EndSessionResponse> endSession(EndSessionRequest request) =>
      throw UnimplementedError();
}

AuthorizationTokenResponse _authorized({String? refreshToken = 'r1'}) =>
    AuthorizationTokenResponse(
      'a1',
      refreshToken,
      DateTime(2026, 11, 16, 9, 5),
      'i1',
      'Bearer',
      const ['openid', 'profile'],
      null,
      null,
    );

FlutterAppAuthPlatformException _platformError(String oauthError) =>
    FlutterAppAuthPlatformException(
      code: 'token_failed',
      message: oauthError,
      platformErrorDetails: FlutterAppAuthPlatformErrorDetails(
        error: oauthError,
      ),
    );

void main() {
  late _RecordingAppAuth appAuth;
  late FakeHttpAdapter http;
  late AppAuthOidcClient client;

  AppAuthOidcClient build({String issuer = _issuer}) => AppAuthOidcClient(
    appAuth: appAuth,
    plainDio: Dio()..httpClientAdapter = http,
    issuer: issuer,
    clientId: 'carenest-mobile',
    redirectUri: 'carenest://oauth/callback',
  );

  setUp(() {
    appAuth = _RecordingAppAuth();
    http = FakeHttpAdapter();
    client = build();
  });

  test('signIn_requestsPromptLoginAndPkceClient', () async {
    appAuth.authorizeResponse = _authorized();

    final tokens = await client.signIn(loginHint: '0900000001');

    final request = appAuth.lastAuthorize!;
    expect(request.promptValues, ['login']);
    expect(request.clientId, 'carenest-mobile');
    expect(request.redirectUrl, 'carenest://oauth/callback');
    expect(request.issuer, _issuer);
    expect(request.scopes, kOidcScopes);
    expect(request.loginHint, '0900000001');
    expect(tokens.accessToken, 'a1');
    expect(tokens.refreshToken, 'r1');
    expect(tokens.idToken, 'i1');
    expect(tokens.accessTokenExpiresAt, DateTime(2026, 11, 16, 9, 5));
  });

  test('signIn_httpIssuerInDebug_allowsInsecure', () async {
    appAuth.authorizeResponse = _authorized();

    await client.signIn();

    expect(appAuth.lastAuthorize!.allowInsecureConnections, isTrue);
  });

  test('signIn_httpsIssuer_staysSecure', () async {
    appAuth.authorizeResponse = _authorized();

    await build(issuer: 'https://auth.example/realms/carenest').signIn();

    expect(appAuth.lastAuthorize!.allowInsecureConnections, isFalse);
  });

  test('signIn_userCancelled_throwsOidcCancelled', () async {
    appAuth.error = FlutterAppAuthUserCancelledException(
      code: 'authorize_and_exchange_code_failed',
      platformErrorDetails: FlutterAppAuthPlatformErrorDetails(),
    );

    await expectLater(client.signIn(), throwsA(isA<OidcCancelled>()));
  });

  test('signIn_missingRefreshToken_throwsUnavailable', () async {
    appAuth.authorizeResponse = _authorized(refreshToken: null);

    await expectLater(client.signIn(), throwsA(isA<OidcUnavailable>()));
  });

  test('refresh_sendsRefreshToken_andKeepsOldWhenNotRotated', () async {
    appAuth.tokenResponse = TokenResponse(
      'a2',
      null,
      DateTime(2026, 11, 16, 9, 10),
      null,
      'Bearer',
      null,
      null,
    );

    final tokens = await client.refresh('r1');

    expect(appAuth.lastToken!.refreshToken, 'r1');
    expect(appAuth.lastToken!.scopes, kOidcScopes);
    expect(tokens.accessToken, 'a2');
    expect(tokens.refreshToken, 'r1');
  });

  test('refresh_invalidGrant_throwsOidcInvalidGrant', () async {
    appAuth.error = _platformError('invalid_grant');

    await expectLater(client.refresh('r1'), throwsA(isA<OidcInvalidGrant>()));
  });

  test('refresh_otherPlatformError_throwsUnavailable', () async {
    appAuth.error = _platformError('server_error');

    await expectLater(client.refresh('r1'), throwsA(isA<OidcUnavailable>()));
  });

  test('refresh_oauthRejection_isNotNetwork', () async {
    appAuth.error = _platformError('unauthorized_client');

    await expectLater(
      client.refresh('r1'),
      throwsA(
        isA<OidcUnavailable>().having((f) => f.network, 'network', isFalse),
      ),
    );
  });

  test('refresh_platformErrorWithoutOAuthCode_isNetwork', () async {
    appAuth.error = FlutterAppAuthPlatformException(
      code: 'token_failed',
      message: 'Network error',
      platformErrorDetails: FlutterAppAuthPlatformErrorDetails(),
    );

    await expectLater(
      client.refresh('r1'),
      throwsA(
        isA<OidcUnavailable>().having((f) => f.network, 'network', isTrue),
      ),
    );
  });

  test('revoke_postsFormToLogoutEndpoint', () async {
    http.enqueue(FakeReply.text(204, '', contentType: 'text/plain'));

    await client.revoke('r1');

    final request = http.requests.single;
    expect(request.method, 'POST');
    expect(request.uri.toString(), '$_issuer/protocol/openid-connect/logout');
    expect(request.contentType, Headers.formUrlEncodedContentType);
    expect(request.data, {
      'client_id': 'carenest-mobile',
      'refresh_token': 'r1',
    });
  });

  test('revoke_serverError_throwsUnavailable', () async {
    http.enqueue(FakeReply.text(500, 'boom', contentType: 'text/plain'));

    await expectLater(client.revoke('r1'), throwsA(isA<OidcUnavailable>()));
  });
}

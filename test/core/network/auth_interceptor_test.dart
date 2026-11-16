import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/errors/app_failure.dart';
import 'package:carenest_app/core/network/api_client.dart';
import 'package:carenest_app/core/network/auth_interceptor.dart';
import 'package:carenest_app/core/network/dio_client.dart';

import '../../helpers/fake_http_adapter.dart';

/// Nguồn token giả: trả token hiện tại, refresh theo kết quả xếp sẵn.
class _FakeTokens implements AccessTokenSource {
  _FakeTokens({this.token = 't1', this.refreshResults = const []});

  String? token;
  final List<Object> refreshResults; // bool hoặc AppFailure
  int refreshCalls = 0;
  AppFailure? accessFailure;

  @override
  Future<String?> validAccessToken() async {
    if (accessFailure != null) throw accessFailure!;
    return token;
  }

  @override
  Future<bool> refreshAfterUnauthorized() async {
    final result = refreshResults[refreshCalls++];
    if (result is AppFailure) throw result;
    if (result == true) token = 't2';
    return result as bool;
  }
}

ApiClient _client(FakeHttpAdapter adapter, _FakeTokens tokens) => ApiClient(
  createApiDio(
    baseUrl: 'http://localhost:8080/api',
    tokens: tokens,
    adapter: adapter,
    logSink: (_) {},
  ),
);

String? _auth(RequestOptions r) => r.headers['Authorization'] as String?;

void main() {
  test('get_addsBearerForApiHost', () async {
    final adapter = FakeHttpAdapter([FakeReply.envelope(200, data: null)]);

    await _client(adapter, _FakeTokens()).get('/accounts/me', decode: (d) => d);

    expect(_auth(adapter.requests.single), 'Bearer t1');
  });

  test('request_toOtherHost_hasNoBearer', () async {
    final adapter = FakeHttpAdapter([FakeReply.envelope(200, data: null)]);

    await _client(
      adapter,
      _FakeTokens(),
    ).get('https://other.example/x', decode: (d) => d);

    expect(_auth(adapter.requests.single), isNull);
  });

  test('skipAuth_hasNoBearer', () async {
    final adapter = FakeHttpAdapter([FakeReply.envelope(200, data: null)]);

    await _client(
      adapter,
      _FakeTokens(),
    ).post('/parent-activation', body: {}, decode: (d) => d, skipAuth: true);

    expect(_auth(adapter.requests.single), isNull);
  });

  test('noSession_sendsWithoutBearer', () async {
    final adapter = FakeHttpAdapter([FakeReply.envelope(200, data: null)]);

    await _client(
      adapter,
      _FakeTokens(token: null),
    ).get('/accounts/me', decode: (d) => d);

    expect(_auth(adapter.requests.single), isNull);
  });

  test('on401_refreshesOnceThenRetries', () async {
    final adapter = FakeHttpAdapter([
      FakeReply.envelope(401, errorCode: 1002, desc: 'Hết hạn'),
      FakeReply.envelope(200, data: 'ok'),
    ]);
    final tokens = _FakeTokens(refreshResults: [true]);

    final result = await _client(
      adapter,
      tokens,
    ).get('/accounts/me', decode: (d) => d as String);

    expect(result, 'ok');
    expect(tokens.refreshCalls, 1);
    expect(adapter.requests.map(_auth), ['Bearer t1', 'Bearer t2']);
  });

  test('on401_retriesPostWithSameBody', () async {
    final adapter = FakeHttpAdapter([
      FakeReply.envelope(401, errorCode: 1002),
      FakeReply.envelope(201, data: null),
    ]);

    await _client(
      adapter,
      _FakeTokens(refreshResults: [true]),
    ).post('/leave-requests', body: {'reason': 'Ốm'}, decode: (d) => d);

    expect(adapter.requests.last.data, {'reason': 'Ốm'});
    expect(adapter.requests, hasLength(2));
  });

  test('on401_refreshFails_throwsUnauthenticated', () async {
    final adapter = FakeHttpAdapter([FakeReply.envelope(401, errorCode: 1002)]);
    final tokens = _FakeTokens(refreshResults: [false]);

    await expectLater(
      _client(adapter, tokens).get('/accounts/me', decode: (d) => d),
      throwsA(isA<UnauthenticatedFailure>()),
    );
    expect(adapter.requests, hasLength(1));
  });

  test('on401_twice_noLoop', () async {
    final adapter = FakeHttpAdapter([
      FakeReply.envelope(401, errorCode: 1002),
      FakeReply.envelope(401, errorCode: 1002),
    ]);
    final tokens = _FakeTokens(refreshResults: [true]);

    await expectLater(
      _client(adapter, tokens).get('/accounts/me', decode: (d) => d),
      throwsA(isA<UnauthenticatedFailure>()),
    );
    expect(tokens.refreshCalls, 1);
  });

  test('on401_formData_notRetried', () async {
    final adapter = FakeHttpAdapter([FakeReply.envelope(401, errorCode: 1002)]);
    final tokens = _FakeTokens(refreshResults: [true]);

    await expectLater(
      _client(adapter, tokens).post(
        '/accounts/me/photo',
        body: FormData.fromMap({'note': 'x'}),
        decode: (d) => d,
      ),
      throwsA(isA<UnauthenticatedFailure>()),
    );
    expect(tokens.refreshCalls, 0);
  });

  test('on401_refreshNetworkError_isNetworkFailure', () async {
    final adapter = FakeHttpAdapter([FakeReply.envelope(401, errorCode: 1002)]);
    final tokens = _FakeTokens(refreshResults: [const NetworkFailure()]);

    await expectLater(
      _client(adapter, tokens).get('/accounts/me', decode: (d) => d),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('tokenSourceThrows_rejectsWithThatFailure', () async {
    final adapter = FakeHttpAdapter([FakeReply.envelope(200, data: null)]);
    final tokens = _FakeTokens()
      ..accessFailure = const ServiceUnavailableFailure(status: 503);

    await expectLater(
      _client(adapter, tokens).get('/accounts/me', decode: (d) => d),
      throwsA(isA<ServiceUnavailableFailure>()),
    );
    expect(adapter.requests, isEmpty);
  });

  test('on403_notRefreshed', () async {
    final adapter = FakeHttpAdapter([FakeReply.envelope(403, errorCode: 1101)]);
    final tokens = _FakeTokens(refreshResults: [true]);

    await expectLater(
      _client(adapter, tokens).get('/accounts/me', decode: (d) => d),
      throwsA(isA<ForbiddenFailure>()),
    );
    expect(tokens.refreshCalls, 0);
  });
}

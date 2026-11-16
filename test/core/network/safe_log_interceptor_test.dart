import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/network/api_client.dart';
import 'package:carenest_app/core/network/auth_interceptor.dart';
import 'package:carenest_app/core/network/dio_client.dart';

import '../../helpers/fake_http_adapter.dart';

class _Tokens implements AccessTokenSource {
  @override
  Future<String?> validAccessToken() async => 'secret-token';

  @override
  Future<bool> refreshAfterUnauthorized() async => false;
}

void main() {
  late List<String> lines;
  late FakeHttpAdapter adapter;
  late ApiClient client;

  setUp(() {
    lines = [];
    adapter = FakeHttpAdapter();
    client = ApiClient(
      createApiDio(
        baseUrl: 'http://localhost:8080/api',
        tokens: _Tokens(),
        adapter: adapter,
        logSink: lines.add,
      ),
    );
  });

  test('log_hasNoTokenOrBody', () async {
    adapter.enqueue(FakeReply.envelope(200, data: {'fullName': 'Bé Na'}));

    await client.post(
      '/accounts/me',
      body: {'password': 'p@ss'},
      decode: (d) => d,
    );

    expect(lines, hasLength(1));
    expect(lines.single, startsWith('POST /api/accounts/me 200 '));
    expect(lines.single, isNot(contains('secret-token')));
    expect(lines.single, isNot(contains('p@ss')));
    expect(lines.single, isNot(contains('Bé Na')));
  });

  test('log_masksNumericIdsAndDropsQuery', () async {
    adapter.enqueue(FakeReply.envelope(200, data: null));

    await client.get(
      '/children/12/health',
      query: {'from': '2026-11-01'},
      decode: (d) => d,
    );

    expect(lines.single, startsWith('GET /api/children/{id}/health 200 '));
    expect(lines.single, isNot(contains('2026-11-01')));
  });

  test('log_errorStatus', () async {
    adapter.enqueue(FakeReply.envelope(404, errorCode: 3001));

    await expectLater(
      client.get('/children/7', decode: (d) => d),
      throwsA(anything),
    );

    expect(lines.single, startsWith('GET /api/children/{id} 404 '));
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/errors/app_failure.dart';
import 'package:carenest_app/core/network/api_client.dart';

import '../../helpers/fake_http_adapter.dart';

ApiClient _client(FakeHttpAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
    ..httpClientAdapter = adapter;
  return ApiClient(dio);
}

void main() {
  test('get_decodesData', () async {
    final adapter = FakeHttpAdapter([
      FakeReply.envelope(200, data: {'fullName': 'Giáo viên A'}),
    ]);

    final name = await _client(adapter).get(
      '/accounts/me',
      decode: (data) => (data as Map)['fullName'] as String,
    );

    expect(name, 'Giáo viên A');
    expect(adapter.requests.single.uri.path, '/api/accounts/me');
  });

  test('get_passesQuery', () async {
    final adapter = FakeHttpAdapter([FakeReply.envelope(200, data: [])]);

    await _client(adapter).get(
      '/me/notifications',
      query: {'page': 0, 'size': 20},
      decode: (data) => data,
    );

    expect(adapter.requests.single.uri.queryParameters, {
      'page': '0',
      'size': '20',
    });
  });

  test('post_400_throwsValidation', () async {
    final adapter = FakeHttpAdapter([
      FakeReply.envelope(
        400,
        errorCode: 9001,
        desc: 'Dữ liệu không hợp lệ',
        data: [
          {'field': 'phone', 'message': 'Sai'},
        ],
      ),
    ]);

    await expectLater(
      _client(
        adapter,
      ).post('/parent-activation', body: {'phone': 'x'}, decode: (d) => d),
      throwsA(
        isA<ValidationFailure>().having(
          (f) => f.fieldErrors.single.field,
          'field',
          'phone',
        ),
      ),
    );
  });

  test('post_sendsJsonBody', () async {
    final adapter = FakeHttpAdapter([FakeReply.envelope(201, data: null)]);

    await _client(
      adapter,
    ).post('/leave-requests', body: {'reason': 'Ốm'}, decode: (d) => d);

    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.data, {'reason': 'Ốm'});
  });

  test('putPatchDelete_useMethod', () async {
    final adapter = FakeHttpAdapter([
      FakeReply.envelope(200, data: null),
      FakeReply.envelope(200, data: null),
      FakeReply.envelope(200, data: null),
    ]);
    final client = _client(adapter);

    await client.put('/a', body: {}, decode: (d) => d);
    await client.patch('/b', body: {}, decode: (d) => d);
    await client.delete('/c', decode: (d) => d);

    expect(adapter.requests.map((r) => r.method), ['PUT', 'PATCH', 'DELETE']);
  });

  test('get_decodeThrows_isContract', () async {
    final adapter = FakeHttpAdapter([
      FakeReply.envelope(200, data: {'fullName': 12}),
    ]);

    await expectLater(
      _client(adapter).get(
        '/accounts/me',
        decode: (data) => (data as Map)['fullName'] as String,
      ),
      throwsA(isA<ContractFailure>()),
    );
  });

  test('get_codeMismatch_isContract', () async {
    final adapter = FakeHttpAdapter([
      FakeReply.json(200, {
        'code': 500,
        'errorCode': null,
        'desc': 'x',
        'data': null,
      }),
    ]);

    await expectLater(
      _client(adapter).get('/accounts/me', decode: (d) => d),
      throwsA(isA<ContractFailure>()),
    );
  });

  test('post_skipAuth_marksRequest', () async {
    final adapter = FakeHttpAdapter([
      FakeReply.envelope(200, data: {'username': '0900000001'}),
    ]);

    await _client(
      adapter,
    ).post('/parent-activation', body: {}, decode: (d) => d, skipAuth: true);

    expect(adapter.requests.single.extra['skipAuth'], isTrue);
  });
}

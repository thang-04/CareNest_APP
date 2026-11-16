import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/errors/app_failure.dart';
import 'package:carenest_app/core/network/api_client.dart';
import 'package:carenest_app/features/auth/data/datasources/account_remote_data_source.dart';

import '../../../helpers/fake_http_adapter.dart';
import '../../../helpers/fake_me.dart';

void main() {
  late FakeHttpAdapter adapter;
  late AccountRemoteDataSource source;

  setUp(() {
    adapter = FakeHttpAdapter();
    source = AccountRemoteDataSource(
      ApiClient(
        Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
          ..httpClientAdapter = adapter,
      ),
    );
  });

  test('fetchMe_getsAccountsMe', () async {
    adapter.enqueue(FakeReply.envelope(200, data: fakeMe(roles: ['TEACHER'])));

    final user = await source.fetchMe();

    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.uri.path, '/api/accounts/me');
    expect(user.roles, {'TEACHER'});
  });

  test('fetchMe_inactive_throwsForbidden', () async {
    adapter.enqueue(FakeReply.envelope(403, errorCode: 1015));

    await expectLater(
      source.fetchMe(),
      throwsA(
        isA<ForbiddenFailure>().having((f) => f.errorCode, 'errorCode', 1015),
      ),
    );
  });
}

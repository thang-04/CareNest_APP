import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/errors/app_failure.dart';
import 'package:carenest_app/core/network/api_envelope.dart';

void main() {
  test('unwrapEnvelope_success_returnsData', () {
    final data = unwrapEnvelope({
      'code': 200,
      'errorCode': null,
      'desc': 'ok',
      'data': {'a': 1},
    }, 200);

    expect(data, {'a': 1});
  });

  test('unwrapEnvelope_nullData_returnsNull', () {
    expect(
      unwrapEnvelope({
        'code': 200,
        'errorCode': null,
        'desc': 'ok',
        'data': null,
      }, 200),
      isNull,
    );
  });

  test('unwrapEnvelope_codeMismatch_throwsContract', () {
    expect(
      () => unwrapEnvelope({
        'code': 201,
        'errorCode': null,
        'desc': 'ok',
        'data': null,
      }, 200),
      throwsA(isA<ContractFailure>()),
    );
  });

  test('unwrapEnvelope_notMap_throwsContract', () {
    expect(
      () => unwrapEnvelope('<html>', 200),
      throwsA(isA<ContractFailure>()),
    );
  });

  test('unwrapEnvelope_missingData_throwsContract', () {
    expect(
      () => unwrapEnvelope({'code': 200, 'desc': 'ok'}, 200),
      throwsA(isA<ContractFailure>()),
    );
  });
}

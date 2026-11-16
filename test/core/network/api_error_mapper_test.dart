import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/errors/app_failure.dart';
import 'package:carenest_app/core/network/api_error_mapper.dart';

final _options = RequestOptions(path: '/accounts/me');

DioException _bad(int status, Object? body) => DioException(
  requestOptions: _options,
  response: Response(requestOptions: _options, statusCode: status, data: body),
  type: DioExceptionType.badResponse,
);

Map<String, Object?> _envelope(
  int status,
  int? errorCode, {
  String desc = 'Lỗi',
  Object? data,
}) => {'code': status, 'errorCode': errorCode, 'desc': desc, 'data': data};

void main() {
  test('map400_withFieldErrors', () {
    final failure = mapDioException(
      _bad(
        400,
        _envelope(
          400,
          9001,
          desc: 'Dữ liệu không hợp lệ',
          data: [
            {'field': 'phone', 'message': 'Sai'},
          ],
        ),
      ),
    );

    expect(failure, isA<ValidationFailure>());
    final validation = failure as ValidationFailure;
    expect(validation.fieldErrors.single.field, 'phone');
    expect(validation.fieldErrors.single.message, 'Sai');
    expect(validation.errorCode, 9001);
    expect(validation.message, 'Dữ liệu không hợp lệ');
    expect(validation.status, 400);
  });

  test('map400_withoutFieldList_hasNoFieldErrors', () {
    final failure = mapDioException(_bad(400, _envelope(400, 9002)));

    expect(failure, isA<ValidationFailure>());
    expect((failure as ValidationFailure).fieldErrors, isEmpty);
  });

  test('map401', () {
    expect(
      mapDioException(_bad(401, _envelope(401, 1002))),
      isA<UnauthenticatedFailure>(),
    );
  });

  test('map403_keepsErrorCode', () {
    final failure = mapDioException(_bad(403, _envelope(403, 1015)));

    expect(failure, isA<ForbiddenFailure>());
    expect(failure.errorCode, 1015);
  });

  test('map404', () {
    expect(
      mapDioException(_bad(404, _envelope(404, null))),
      isA<NotFoundFailure>(),
    );
  });

  test('map409', () {
    expect(
      mapDioException(_bad(409, _envelope(409, 4007))),
      isA<ConflictFailure>(),
    );
  });

  test('map500', () {
    expect(
      mapDioException(_bad(500, _envelope(500, null))),
      isA<ServerFailure>(),
    );
  });

  test('map503_htmlBody_isServiceUnavailable', () {
    final failure = mapDioException(_bad(503, '<html>Bad gateway</html>'));

    expect(failure, isA<ServiceUnavailableFailure>());
    expect(failure.status, 503);
    expect(failure.errorCode, isNull);
    expect(failure.message, isNull);
  });

  test('map503_authServiceUnavailable_keepsErrorCode', () {
    final failure = mapDioException(_bad(503, _envelope(503, 1013)));

    expect(failure, isA<ServiceUnavailableFailure>());
    expect(failure.errorCode, 1013);
  });

  test('mapConnectionError_isNetwork', () {
    expect(
      mapDioException(
        DioException(
          requestOptions: _options,
          type: DioExceptionType.connectionError,
        ),
      ),
      isA<NetworkFailure>(),
    );
  });

  test('mapReceiveTimeout_isTimeout', () {
    expect(
      mapDioException(
        DioException(
          requestOptions: _options,
          type: DioExceptionType.receiveTimeout,
        ),
      ),
      isA<TimeoutFailure>(),
    );
  });

  test('mapCancel_isCancelled', () {
    expect(
      mapDioException(
        DioException(requestOptions: _options, type: DioExceptionType.cancel),
      ),
      isA<CancelledFailure>(),
    );
  });

  test('mapUnknownFormatException_isContract', () {
    expect(
      mapDioException(
        DioException(
          requestOptions: _options,
          type: DioExceptionType.unknown,
          error: const FormatException('bad json'),
        ),
      ),
      isA<ContractFailure>(),
    );
  });
}

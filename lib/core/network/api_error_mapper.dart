import 'package:dio/dio.dart';

import 'package:carenest_app/core/errors/app_failure.dart';

/// Chuyển lỗi Dio thành [AppFailure]. Response lỗi phân loại theo HTTP status; `errorCode`, `desc`
/// lấy từ envelope nếu có (body HTML của proxy vẫn phân loại theo status).
AppFailure mapDioException(DioException e) {
  // Interceptor đã chuẩn hóa sẵn (vd. refresh token mất mạng) ⇒ giữ nguyên
  final inner = e.error;
  if (inner is AppFailure) return inner;
  switch (e.type) {
    case DioExceptionType.cancel:
      return const CancelledFailure();
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const TimeoutFailure();
    case DioExceptionType.connectionError:
    case DioExceptionType.badCertificate:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      final response = e.response;
      final status = response?.statusCode;
      if (status == null) return const NetworkFailure();
      return failureFromResponse(status, response?.data);
    case DioExceptionType.unknown:
      // JSON hỏng ⇒ lỗi contract; còn lại thường là lỗi socket của nền tảng
      return e.error is FormatException
          ? const ContractFailure()
          : const NetworkFailure();
  }
}

/// Phân loại response lỗi theo status (BE: `code` == HTTP status).
AppFailure failureFromResponse(int status, Object? body) {
  final envelope = body is Map ? body : const {};
  final errorCode = envelope['errorCode'] is int
      ? envelope['errorCode'] as int
      : null;
  final message = envelope['desc'] is String
      ? envelope['desc'] as String
      : null;

  switch (status) {
    case 400:
      return ValidationFailure(
        status: status,
        errorCode: errorCode,
        message: message,
        fieldErrors: _fieldErrors(envelope['data']),
      );
    case 401:
      return UnauthenticatedFailure(
        status: status,
        errorCode: errorCode,
        message: message,
      );
    case 403:
      return ForbiddenFailure(
        status: status,
        errorCode: errorCode,
        message: message,
      );
    case 404:
      return NotFoundFailure(
        status: status,
        errorCode: errorCode,
        message: message,
      );
    case 409:
      return ConflictFailure(
        status: status,
        errorCode: errorCode,
        message: message,
      );
    case 502:
    case 503:
    case 504:
      return ServiceUnavailableFailure(
        status: status,
        errorCode: errorCode,
        message: message,
      );
    default:
      return ServerFailure(
        status: status,
        errorCode: errorCode,
        message: message,
      );
  }
}

List<FieldError> _fieldErrors(Object? data) {
  if (data is! List) return const [];
  return [
    for (final item in data)
      if (item is Map && item['field'] is String && item['message'] is String)
        FieldError(
          field: item['field'] as String,
          message: item['message'] as String,
        ),
  ];
}

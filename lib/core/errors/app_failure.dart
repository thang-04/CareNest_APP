/// Lỗi đã chuẩn hóa từ API và mạng. Màn hình phân nhánh theo lớp + `errorCode`, không so `desc`
/// (BE docs/contracts/ERROR_CONTRACT.md).
sealed class AppFailure implements Exception {
  const AppFailure({this.status, this.errorCode, this.message});

  /// HTTP status; `null` khi không có response (mất mạng, hết giờ, hủy).
  final int? status;

  /// Mã lỗi nghiệp vụ 4 số của BE; `null` khi BE không gửi.
  final int? errorCode;

  /// `desc` của BE: câu tiếng Việt hiển thị được; `null` khi không có envelope.
  final String? message;

  @override
  String toString() => '$runtimeType(status: $status, errorCode: $errorCode)';
}

/// 400: dữ liệu gửi lên sai; `fieldErrors` theo ô khi BE trả danh sách `{field, message}`.
final class ValidationFailure extends AppFailure {
  const ValidationFailure({
    super.status,
    super.errorCode,
    super.message,
    this.fieldErrors = const [],
  });

  final List<FieldError> fieldErrors;
}

/// 401: thiếu token, token hết hạn hoặc sai.
final class UnauthenticatedFailure extends AppFailure {
  const UnauthenticatedFailure({super.status, super.errorCode, super.message});
}

/// 403: không có quyền, ngoài phạm vi, tài khoản khóa (1015) hoặc chưa có hồ sơ (1014).
final class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure({super.status, super.errorCode, super.message});
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({super.status, super.errorCode, super.message});
}

/// 409: trạng thái đã đổi ở BE ⇒ tải lại rồi báo người dùng.
final class ConflictFailure extends AppFailure {
  const ConflictFailure({super.status, super.errorCode, super.message});
}

/// 502/503/504: BE hoặc dịch vụ phía sau tạm không dùng được ⇒ cho thử lại.
final class ServiceUnavailableFailure extends AppFailure {
  const ServiceUnavailableFailure({
    super.status,
    super.errorCode,
    super.message,
  });
}

/// Mọi status lỗi khác (4xx/5xx còn lại).
final class ServerFailure extends AppFailure {
  const ServerFailure({super.status, super.errorCode, super.message});
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure();
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure();
}

final class CancelledFailure extends AppFailure {
  const CancelledFailure();
}

/// Response không đúng envelope `{code, errorCode, desc, data}` hoặc `code` ≠ HTTP status.
final class ContractFailure extends AppFailure {
  const ContractFailure({super.status});
}

class FieldError {
  const FieldError({required this.field, required this.message});

  final String field;
  final String message;
}

/// Mã lỗi BE mà App phân nhánh (AUTH_CONTRACT, ERROR_CONTRACT).
abstract final class ApiErrorCodes {
  static const unauthenticated = 1002;
  static const otpInvalidOrExpired = 1006;
  static const passwordPolicyViolation = 1009;
  static const authServiceUnavailable = 1013;
  static const accountNotProvisioned = 1014;
  static const accountInactive = 1015;
  static const forbidden = 1101;
  static const invalidRequestData = 9001;
  static const malformedRequest = 9002;
}

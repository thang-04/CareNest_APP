import 'package:carenest_app/core/errors/app_failure.dart';

/// Lấy `data` từ envelope `{code, errorCode, desc, data}` của response thành công.
/// Sai dạng hoặc `code` ≠ HTTP status ⇒ [ContractFailure] (BE ERROR_CONTRACT: `code` luôn bằng status).
Object? unwrapEnvelope(Object? body, int httpStatus) {
  if (body is! Map || body['code'] != httpStatus || !body.containsKey('data')) {
    throw ContractFailure(status: httpStatus);
  }
  return body['data'];
}

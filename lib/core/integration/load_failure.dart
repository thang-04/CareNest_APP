import 'package:carenest_app/core/integration/mobile_api.dart';

/// Câu báo lỗi khi tải dữ liệu (`.claude/rules/api-client.md`): BE từ chối (403 con không thuộc tài
/// khoản, 404, 400 khoảng ngày…) ⇒ câu BE trả; lỗi mạng, máy chủ ⇒ nhắc kiểm tra mạng.
/// 401 do luồng đăng nhập xử lý, màn không nói thay.
String loadFailureMessage(Object? error) => switch (error) {
  ApiFailure(:final status, :final message)
      when status >= 400 && status < 500 && status != 401 =>
    message,
  _ => 'Kiểm tra kết nối mạng rồi thử lại.',
};

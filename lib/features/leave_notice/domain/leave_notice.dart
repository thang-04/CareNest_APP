import 'package:flutter/foundation.dart';

/// Vòng đời theo ATT-05 (CONFIRMED): `SUBMITTED → CANCELLED`, không có bước duyệt.
enum LeaveNoticeStatus { submitted, cancelled }

/// Buổi nghỉ theo mockup P03. Nghỉ nửa buổi xử lý suất ăn ra sao chưa có rule BE ⇒ APP không suy.
enum LeaveSession { fullDay, morning, afternoon }

@immutable
class LeaveNotice {
  const LeaveNotice({
    required this.id,
    required this.childId,
    required this.from,
    required this.to,
    required this.session,
    required this.reason,
    required this.status,
    this.seenByTeacher = false,
  });

  final String id;
  final String childId;
  final DateTime from;
  final DateTime to;
  final LeaveSession session;
  final String reason;
  final LeaveNoticeStatus status;

  /// Giáo viên đã xem/ghi nhận (ATT-05: GV chỉ xem, không duyệt) — BE trả.
  final bool seenByTeacher;
}

/// Dữ liệu phụ huynh nhập; BE kiểm tra lại mọi thứ (ngày qua cut-off, quyền — ATT-05b, AUTH-04).
@immutable
class LeaveNoticeDraft {
  const LeaveNoticeDraft({
    required this.childId,
    required this.from,
    required this.to,
    required this.session,
    required this.reason,
  });

  final String childId;
  final DateTime from;
  final DateTime to;
  final LeaveSession session;
  final String reason;
}

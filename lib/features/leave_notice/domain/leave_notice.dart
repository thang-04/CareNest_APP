import 'package:flutter/foundation.dart';

/// Vòng đời theo ATT-05 (CONFIRMED): `SUBMITTED → CANCELLED`, không có bước duyệt.
enum LeaveNoticeStatus { submitted, cancelled }

/// Đơn nghỉ theo ngày (ATT-05): BE chỉ nhận từ ngày, đến ngày, lý do.
@immutable
class LeaveNotice {
  const LeaveNotice({
    required this.id,
    required this.childId,
    required this.from,
    required this.to,
    required this.reason,
    required this.status,
    this.canCancel = false,
  });

  final String id;
  final String childId;
  final DateTime from;
  final DateTime to;
  final String reason;
  final LeaveNoticeStatus status;

  /// Còn hủy được (trước giờ chốt của ngày nghỉ) — BE quyết định, APP chỉ hiện nút.
  final bool canCancel;

  LeaveNotice copyWith({LeaveNoticeStatus? status, bool? canCancel}) =>
      LeaveNotice(
        id: id,
        childId: childId,
        from: from,
        to: to,
        reason: reason,
        status: status ?? this.status,
        canCancel: canCancel ?? this.canCancel,
      );
}

/// Dữ liệu phụ huynh nhập; BE kiểm tra lại mọi thứ (ngày qua cut-off, quyền — ATT-05b, AUTH-04).
@immutable
class LeaveNoticeDraft {
  const LeaveNoticeDraft({
    required this.childId,
    required this.from,
    required this.to,
    required this.reason,
  });

  /// Hỗ trợ nhập: tối đa 30 ngày mỗi đơn (ATT-05); BE vẫn kiểm tra.
  static const maxDays = 30;

  final String childId;
  final DateTime from;
  final DateTime to;
  final String reason;
}

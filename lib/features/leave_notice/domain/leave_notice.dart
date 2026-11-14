import 'package:flutter/foundation.dart';

/// Vòng đời theo ATT-05 (CONFIRMED): `SUBMITTED → CANCELLED`, không có bước duyệt.
/// `cancelled` = hủy hết (BE `CANCELLED`); hủy phần còn lại vẫn là `submitted` với [LeaveNotice.effectiveTo] sớm hơn.
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
    DateTime? effectiveTo,
    this.canCancel = false,
  }) : effectiveTo = effectiveTo ?? to;

  final String id;
  final String childId;
  final DateTime from;
  final DateTime to;
  final String reason;
  final LeaveNoticeStatus status;

  /// BE `effectiveTo`: ngày cuối còn Vắng có phép. Hủy phần còn lại (ATT-04) ⇒ sớm hơn [to].
  final DateTime effectiveTo;

  /// Hiện nút hủy khi đơn còn ngày từ hôm nay trở đi; BE quyết định ngày nào hủy được theo giờ chốt và trả
  /// `LEAVE_CANNOT_CANCEL` nếu mọi ngày đã qua giờ chốt (BE không có cờ riêng).
  final bool canCancel;

  /// Đã hủy các ngày cuối, các ngày đầu vẫn nghỉ có phép (ATT-04, user chốt 2026-11-14).
  bool get isPartlyCancelled =>
      status == LeaveNoticeStatus.submitted && effectiveTo.isBefore(to);

  LeaveNotice copyWith({
    LeaveNoticeStatus? status,
    DateTime? effectiveTo,
    bool? canCancel,
  }) => LeaveNotice(
    id: id,
    childId: childId,
    from: from,
    to: to,
    reason: reason,
    status: status ?? this.status,
    effectiveTo: effectiveTo ?? this.effectiveTo,
    canCancel: canCancel ?? this.canCancel,
  );
}

/// BE trả 409 `LEAVE_CANNOT_CANCEL`: các ngày của đơn đã qua giờ chốt.
class LeaveCannotCancelException implements Exception {
  const LeaveCannotCancelException();
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

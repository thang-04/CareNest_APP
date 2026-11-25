import 'package:flutter/foundation.dart';

/// Quan hệ với trẻ — khớp enum BE `GuardianRelationship`.
enum GuardianRelationship {
  father('FATHER', 'Bố'),
  mother('MOTHER', 'Mẹ'),
  grandfather('GRANDFATHER', 'Ông'),
  grandmother('GRANDMOTHER', 'Bà'),
  sibling('SIBLING', 'Anh/chị'),
  guardian('GUARDIAN', 'Người giám hộ'),
  other('OTHER', 'Khác');

  const GuardianRelationship(this.code, this.label);
  final String code;
  final String label;
}

/// Trạng thái đón trong ngày — khớp enum BE `PickupStatus`.
enum PickupStatus { waiting, pickedUp, absent, unmarked }

/// Cách GV xác minh — khớp enum BE `PickupVerification` (PCK-02).
enum PickupVerification {
  /// Khớp ảnh phụ huynh trên hồ sơ ⇒ bắt buộc guardianPosition + giờ trả.
  photoMatch('PHOTO_MATCH'),

  /// Gọi phụ huynh, đồng ý giao ⇒ bắt buộc giờ trả + ghi chú (nội dung cuộc gọi, người đón).
  phoneConfirmed('PHONE_CONFIRMED'),

  /// Gọi phụ huynh, không giao ⇒ bắt buộc ghi chú.
  phoneDeclined('PHONE_DECLINED');

  const PickupVerification(this.code);
  final String code;

  bool get handedOver => this != phoneDeclined;
}

/// Phụ huynh/người giám hộ trên hồ sơ trẻ — BE `PickupChildResponse.PickupGuardian`.
/// Không có người đón hộ đăng ký trước (PCK-03).
@immutable
class PickupGuardian {
  const PickupGuardian({
    required this.position,
    required this.fullName,
    required this.relationship,
    required this.phone,
    this.photoUrl,
  });

  final int position;
  final String fullName;
  final GuardianRelationship relationship;
  final String phone;

  /// URL có hạn, chỉ tải qua auth; null ⇒ chưa có ảnh (PCK-02: gọi phụ huynh).
  final String? photoUrl;
}

/// Kết quả ghi nhận — tập con field của BE `PickupRecordResponse` mà màn dùng.
@immutable
class PickupRecord {
  const PickupRecord({
    required this.verification,
    this.guardianPosition,
    this.pickupPersonName,
    this.pickupPersonRelationship,
    this.handedOverAt,
    this.note,
  });

  final PickupVerification verification;
  final int? guardianPosition;
  final String? pickupPersonName;
  final GuardianRelationship? pickupPersonRelationship;
  final DateTime? handedOverAt;
  final String? note;
}

/// Một dòng bảng đón — BE `PickupBoardResponse.PickupRow`.
@immutable
class PickupRow {
  const PickupRow({
    required this.childId,
    required this.fullName,
    required this.status,
    this.pickup,
  });

  final String childId;
  final String fullName;
  final PickupStatus status;

  /// Lần giao gần nhất (null khi chưa giao).
  final PickupRecord? pickup;
}

/// Màn trả một bé — BE `PickupChildResponse`.
@immutable
class PickupChild {
  const PickupChild({
    required this.row,
    required this.className,
    required this.guardians,
  });

  final PickupRow row;
  final String className;
  final List<PickupGuardian> guardians;
}

/// Thân request — BE `PickupRequest`. Giờ trả "HH:mm", không sau giờ hiện tại (BE kiểm tra).
@immutable
class PickupRequest {
  const PickupRequest({
    required this.childId,
    required this.verification,
    this.guardianPosition,
    this.handoverTime,
    this.note,
  });

  final String childId;
  final PickupVerification verification;
  final int? guardianPosition;
  final String? handoverTime;
  final String? note;
}

abstract interface class PickupSource {
  /// BE: `GET /classes/{classId}/pickups?date=`.
  Future<List<PickupRow>> loadBoard(String classId);

  /// BE: `GET /pickups/children/{childId}?date=`.
  Future<PickupChild> loadChild(String childId);

  /// BE: `POST /pickups` — BE ghi giờ, người đón và báo phụ huynh (PCK-04).
  Future<void> record(PickupRequest request);
}

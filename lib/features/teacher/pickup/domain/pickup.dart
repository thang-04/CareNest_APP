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
  phoneDeclined('PHONE_DECLINED'),

  /// Chỉ còn ở bản ghi cũ (Web: "Không liên lạc được phụ huynh"); App không tạo mới.
  phoneUnreachable('PHONE_UNREACHABLE');

  const PickupVerification(this.code);
  final String code;

  /// Chỉ khớp ảnh / phụ huynh xác nhận qua điện thoại mới cho trẻ ra về (BE `outcome` HANDED_OVER).
  bool get handedOver => this == photoMatch || this == phoneConfirmed;

  /// Nhãn như Web `VERIFICATION_LABELS`.
  String get label => switch (this) {
    photoMatch => 'Khớp ảnh đăng ký',
    phoneConfirmed => 'Phụ huynh xác nhận qua điện thoại',
    phoneDeclined => 'Gọi phụ huynh – không trả',
    phoneUnreachable => 'Không liên lạc được phụ huynh',
  };
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
    this.childName,
    this.className,
    this.recordedAt,
  });

  final PickupVerification verification;
  final int? guardianPosition;
  final String? pickupPersonName;
  final GuardianRelationship? pickupPersonRelationship;
  final DateTime? handedOverAt;
  final String? note;

  /// Chỉ có ở danh sách kết quả `GET /pickups` (BE `PickupRecordResponse`).
  final String? childName;
  final String? className;
  final DateTime? recordedAt;
}

/// Một dòng bảng đón — BE `PickupBoardResponse.PickupRow`.
@immutable
class PickupRow {
  const PickupRow({
    required this.childId,
    required this.fullName,
    required this.status,
    this.code = '',
    this.pickup,
    this.attempts = const [],
  });

  final String childId;
  final String fullName;
  final PickupStatus status;

  /// Mã trẻ (Web hiện dưới tên).
  final String code;

  /// Lần giao gần nhất (null khi chưa giao).
  final PickupRecord? pickup;

  /// Mọi lần xác minh trong ngày, cũ trước (BE `attempts`).
  final List<PickupRecord> attempts;

  /// Số lần gọi phụ huynh mà không trả trẻ trong ngày.
  int get failedAttempts =>
      attempts.where((attempt) => !attempt.verification.handedOver).length;
}

/// Bảng đón của lớp một ngày — BE `PickupBoardResponse`. `today` là hôm nay theo giờ trường;
/// chỉ ngày = hôm nay mới trả trẻ được.
@immutable
class PickupBoard {
  const PickupBoard({
    required this.rows,
    required this.date,
    required this.today,
    this.className = '',
  });

  final List<PickupRow> rows;
  final DateTime date;
  final DateTime today;
  final String className;

  bool get canRecord =>
      date.year == today.year &&
      date.month == today.month &&
      date.day == today.day;
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
  /// BE: `GET /classes/{classId}/pickups?date=` — [date] null = hôm nay theo giờ trường.
  Future<PickupBoard> loadBoard(String classId, {DateTime? date});

  /// BE: `GET /pickups?date=` — kết quả trả trẻ của các lớp giáo viên trong ngày (mới nhất trước).
  Future<List<PickupRecord>> loadResults({DateTime? date});

  /// BE: `GET /pickups/children/{childId}?date=`.
  Future<PickupChild> loadChild(String childId);

  /// BE: `POST /pickups` — BE ghi giờ, người đón và báo phụ huynh (PCK-04).
  Future<void> record(PickupRequest request);
}

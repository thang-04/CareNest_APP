import 'package:flutter/foundation.dart';

/// Đón trẻ chưa có rule BE (plan K4) — mô hình theo mockup T05/T06, chờ BE ghi nghiệp vụ.
@immutable
class RegisteredGuardian {
  const RegisteredGuardian({
    required this.id,
    required this.relation,
    required this.fullName,
    required this.phone,
  });

  final String id;

  /// "Mẹ"
  final String relation;
  final String fullName;
  final String phone;
}

@immutable
class PickupKid {
  const PickupKid({
    required this.childId,
    required this.fullName,
    required this.guardians,
    this.pickedUpAt,
    this.pickedUpBy,
  });

  final String childId;
  final String fullName;
  final List<RegisteredGuardian> guardians;
  final DateTime? pickedUpAt;

  /// "Mẹ" / "Ông nội"
  final String? pickedUpBy;

  bool get pickedUp => pickedUpAt != null;
}

/// Người đón không khớp ảnh: GV gọi phụ huynh, ghi nội dung cuộc gọi rồi trả hoặc không trả (PCK-02).
/// Trả bé ⇒ BE ghi người đón, giờ đón và báo phụ huynh (PCK-04); không trả ⇒ chỉ ghi lần đón, không giao bé.
@immutable
class PickupCall {
  const PickupCall({
    required this.childId,
    required this.callNote,
    required this.handedOver,
    this.pickupPerson,
  });

  final String childId;

  /// Nội dung cuộc gọi với phụ huynh — bắt buộc.
  final String callNote;
  final bool handedOver;

  /// Người thực tế đến đón; bắt buộc khi trả bé.
  final String? pickupPerson;
}

abstract interface class PickupSource {
  Future<List<PickupKid>> loadClass(String classId);

  /// GV xác nhận giao bé cho người đón đã đăng ký; BE ghi giờ, người đón và báo phụ huynh.
  Future<void> handOver(String childId, RegisteredGuardian guardian);

  /// Ghi cuộc gọi khi người đón không khớp, kèm quyết định trả / không trả bé.
  Future<void> recordCall(PickupCall call);
}

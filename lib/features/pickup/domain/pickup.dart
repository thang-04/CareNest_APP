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

abstract interface class PickupSource {
  Future<List<PickupKid>> loadClass(String classId);

  /// GV xác nhận giao bé cho người đón đã đăng ký; BE ghi giờ, người đón và báo phụ huynh.
  Future<void> handOver(String childId, RegisteredGuardian guardian);
}

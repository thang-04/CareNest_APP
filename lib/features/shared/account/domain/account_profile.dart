import 'package:flutter/foundation.dart';

/// Nhóm người dùng của app. Role thật do BE trả sau đăng nhập; ở bản xem thử lấy theo nhánh route.
enum AppRole {
  parent('Phụ huynh'),
  teacher('Giáo viên'),
  kitchen('Nhân viên bếp'),
  vicePrincipal('Phó Hiệu trưởng'),
  principal('Hiệu trưởng');

  const AppRole(this.label);

  final String label;
}

@immutable
class AccountProfile {
  const AccountProfile({
    required this.fullName,
    required this.phone,
    required this.role,
    this.email,
    this.contextLabel,
    this.contextValue,
  });

  final String fullName;
  final String phone;
  final AppRole role;
  final String? email;

  /// Dòng ngữ cảnh dưới thẻ tài khoản, vd. "Con của tôi" / "Nguyễn Minh Anh · Mầm 3A".
  final String? contextLabel;
  final String? contextValue;
}

abstract interface class AccountSource {
  Future<AccountProfile> loadProfile(AppRole role);
}

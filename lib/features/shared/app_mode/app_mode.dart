import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/shared/account/domain/account_profile.dart';

/// Chế độ App của tài khoản GV kiêm phụ huynh (AUTH-21, ADR-0022): App chuyển giao diện
/// GV / phụ huynh; BE không nhận vai trò đang chọn — mọi API vẫn lọc theo role trong token.
/// Chỉ có khi `/accounts/me` trả cả TEACHER và PARENT kèm `childIds` (AUTH_CONTRACT).
abstract final class AppMode {
  /// Chế độ đang dùng; null ⇒ theo vai trò mặc định (nhân sự trước — plan 16/11).
  static final active = ValueNotifier<AppRole?>(null);

  /// Tài khoản có cả hai vai ⇒ hiện nút chuyển.
  static final dualRole = ValueNotifier<bool>(false);

  /// Vai trò App từ `roles`, `childIds` của `/accounts/me`.
  static List<AppRole> appRolesOf(
    List<Object?> roles,
    List<Object?> childIds,
  ) => [
    if (roles.contains('TEACHER')) AppRole.teacher,
    if (roles.contains('KITCHEN_STAFF')) AppRole.kitchen,
    if (roles.contains('PARENT') && childIds.isNotEmpty) AppRole.parent,
  ];

  /// Đặt theo phiên mới đăng nhập; giữ chế độ đang chọn nếu vẫn hợp lệ.
  static AppRole? resolve(List<AppRole> available) {
    dualRole.value =
        available.contains(AppRole.teacher) &&
        available.contains(AppRole.parent);
    final current = active.value;
    if (current != null && available.contains(current)) return current;
    return available.isEmpty ? null : available.first;
  }

  static void reset() {
    active.value = null;
    dualRole.value = false;
  }
}

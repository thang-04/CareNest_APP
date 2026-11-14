import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/account/domain/account_profile.dart';

/// Chế độ có thể chuyển trên App: chỉ GV kiêm phụ huynh có hai chế độ (AUTH-21).
const switchableModes = {AppRole.teacher, AppRole.parent};

/// Chế độ mở sau đăng nhập (user chốt 2026-11-14): chế độ dùng lần cuối nếu tài khoản còn chế độ đó,
/// không thì mở chế độ nhân sự (GV) trước phụ huynh. BE không nhận chế độ từ client, chỉ lọc role theo token.
AppRole startMode(List<AppRole> modes, {AppRole? last}) {
  if (modes.isEmpty) throw ArgumentError('Tài khoản không có vai trò nào');
  if (last != null && modes.contains(last)) return last;
  if (modes.contains(AppRole.teacher)) return AppRole.teacher;
  return modes.first;
}

/// Chế độ của phiên trên App (GV kiêm phụ huynh — AUTH-21, user chốt 2026-11-14): mở chế độ GV, chuyển
/// chế độ ở màn Tài khoản, App nhớ chế độ dùng lần cuối.
abstract final class AppMode {
  /// Các chế độ của tài khoản đang đăng nhập (BE `/accounts/me`: roles + childIds); bản giả đặt ở màn xem thử.
  static final modes = ValueNotifier<List<AppRole>>(const []);

  /// Chế độ dùng lần cuối, giữ qua đăng xuất.
  // TODO(Giáp): lưu bền qua lần mở App sau khi plan nền App thêm storage (flutter_secure_storage)
  static AppRole? last;

  /// Bắt đầu phiên: trả chế độ cần mở.
  static AppRole start(List<AppRole> available) {
    modes.value = List.unmodifiable(available);
    final mode = startMode(available, last: last);
    last = mode;
    return mode;
  }

  static void switchTo(AppRole mode) => last = mode;

  static bool get isTeacherParent =>
      modes.value.toSet().containsAll(switchableModes);

  /// Chế độ còn lại khi tài khoản có cả GV và phụ huynh; null nếu không chuyển được.
  static AppRole? otherThan(AppRole current) {
    if (!isTeacherParent || !switchableModes.contains(current)) return null;
    return current == AppRole.teacher ? AppRole.parent : AppRole.teacher;
  }

  /// Đăng xuất: bỏ chế độ của phiên, giữ [last].
  static void endSession() => modes.value = const [];

  /// Chỉ cho test.
  @visibleForTesting
  static void resetForTest() {
    modes.value = const [];
    last = null;
  }
}

import 'package:flutter/services.dart';

import 'package:carenest_app/core/storage/secure_store.dart';

/// Chế độ dùng App lần cuối của từng tài khoản (GV / phụ huynh — user 14/11, BE ADR-0022).
/// Không nhạy cảm, giữ cả sau đăng xuất; chỉ để dựng giao diện, không gửi lên BE.
class LastModeStore {
  LastModeStore(this._store, {required String env})
    : _prefix = 'carenest.$env.last_mode.';

  final SecureStore _store;
  final String _prefix;

  Future<String?> read(int userId) async {
    try {
      return await _store.read('$_prefix$userId');
    } on PlatformException {
      return null;
    }
  }

  Future<void> write(int userId, String mode) =>
      _store.write('$_prefix$userId', mode);
}

import 'package:flutter/services.dart';

import 'package:carenest_app/core/storage/secure_store.dart';

/// Token cần giữ qua lần mở App sau. Access token không lưu: chỉ ở bộ nhớ (CODING_GUIDE §5.3).
class StoredTokens {
  const StoredTokens({required this.refreshToken, this.idToken});

  final String refreshToken;
  final String? idToken;
}

/// Refresh token + id token trong secure storage; khóa tách theo môi trường để không lẫn token
/// giữa local/staging/production.
class TokenStorage {
  TokenStorage(this._store, {required String env})
    : _refreshKey = 'carenest.$env.refresh_token',
      _idKey = 'carenest.$env.id_token';

  final SecureStore _store;
  final String _refreshKey;
  final String _idKey;

  /// Đọc lỗi (khóa Keystore hỏng sau khi khôi phục backup/đổi máy) ⇒ xóa khóa hỏng, coi như chưa đăng nhập.
  Future<StoredTokens?> read() async {
    try {
      final refreshToken = await _store.read(_refreshKey);
      if (refreshToken == null || refreshToken.isEmpty) return null;
      return StoredTokens(
        refreshToken: refreshToken,
        idToken: await _store.read(_idKey),
      );
    } on PlatformException {
      await _clearQuietly();
      return null;
    }
  }

  Future<void> write(StoredTokens tokens) async {
    await _store.write(_refreshKey, tokens.refreshToken);
    final idToken = tokens.idToken;
    if (idToken == null) {
      await _store.delete(_idKey);
    } else {
      await _store.write(_idKey, idToken);
    }
  }

  Future<void> clear() async {
    await _store.delete(_refreshKey);
    await _store.delete(_idKey);
  }

  Future<void> _clearQuietly() async {
    try {
      await clear();
    } on PlatformException {
      // Khóa đã hỏng thì xóa cũng có thể lỗi; lần ghi token mới sẽ đè lên
    }
  }
}

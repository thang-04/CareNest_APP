import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/storage/secure_store.dart';
import 'package:carenest_app/core/storage/token_storage.dart';

/// Store giả mô phỏng khóa Keystore hỏng (khôi phục backup sang máy khác).
class _BrokenStore implements SecureStore {
  final List<String> deleted = [];

  @override
  Future<String?> read(String key) async =>
      throw PlatformException(code: 'read_error');

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async => deleted.add(key);
}

void main() {
  group('TokenStorage', () {
    test('write_thenRead_roundTrip', () async {
      final storage = TokenStorage(MemorySecureStore(), env: 'development');

      await storage.write(
        const StoredTokens(refreshToken: 'r1', idToken: 'i1'),
      );
      final tokens = await storage.read();

      expect(tokens?.refreshToken, 'r1');
      expect(tokens?.idToken, 'i1');
    });

    test('read_empty_returnsNull', () async {
      expect(
        await TokenStorage(MemorySecureStore(), env: 'development').read(),
        isNull,
      );
    });

    test('write_withoutIdToken_dropsOldIdToken', () async {
      final storage = TokenStorage(MemorySecureStore(), env: 'development');

      await storage.write(
        const StoredTokens(refreshToken: 'r1', idToken: 'i1'),
      );
      await storage.write(const StoredTokens(refreshToken: 'r2'));

      final tokens = await storage.read();
      expect(tokens?.refreshToken, 'r2');
      expect(tokens?.idToken, isNull);
    });

    test('clear_removesBothKeys', () async {
      final store = MemorySecureStore();
      final storage = TokenStorage(store, env: 'development');
      await storage.write(
        const StoredTokens(refreshToken: 'r1', idToken: 'i1'),
      );

      await storage.clear();

      expect(await storage.read(), isNull);
      expect(store.values, isEmpty);
    });

    test('keys_includeEnv', () async {
      final store = MemorySecureStore();

      await TokenStorage(
        store,
        env: 'development',
      ).write(const StoredTokens(refreshToken: 'r1', idToken: 'i1'));

      expect(store.values.keys, {
        'carenest.development.refresh_token',
        'carenest.development.id_token',
      });
    });

    test('read_platformError_returnsNullAndClears', () async {
      final store = _BrokenStore();

      final tokens = await TokenStorage(store, env: 'development').read();

      expect(tokens, isNull);
      expect(store.deleted, {
        'carenest.development.refresh_token',
        'carenest.development.id_token',
      });
    });
  });
}

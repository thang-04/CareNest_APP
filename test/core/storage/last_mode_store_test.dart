import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/storage/last_mode_store.dart';
import 'package:carenest_app/core/storage/secure_store.dart';

class _BrokenStore implements SecureStore {
  @override
  Future<String?> read(String key) async =>
      throw PlatformException(code: 'read_error');

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async {}
}

void main() {
  test('lastMode_perUser', () async {
    final store = MemorySecureStore();
    final modes = LastModeStore(store, env: 'development');

    await modes.write(1, 'parent');

    expect(await modes.read(1), 'parent');
    expect(await modes.read(2), isNull);
    expect(store.values.keys, {'carenest.development.last_mode.1'});
  });

  test('lastMode_readError_returnsNull', () async {
    expect(
      await LastModeStore(_BrokenStore(), env: 'development').read(1),
      isNull,
    );
  });
}

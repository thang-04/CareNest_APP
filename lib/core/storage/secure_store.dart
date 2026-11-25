import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Kho khóa–giá trị mã hóa của hệ điều hành (Keychain iOS, Keystore Android).
/// Chỉ lớp storage/auth dùng; màn hình không gọi trực tiếp (CODING_GUIDE §5.3).
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureStore implements SecureStore {
  const FlutterSecureStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Bản trong bộ nhớ cho test và chạy dữ liệu giả; mất khi tắt App.
class MemorySecureStore implements SecureStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

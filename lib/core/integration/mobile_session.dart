import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'mobile_config.dart';

abstract interface class MobileCredentials {
  int? get userId;
  int get generation;
  Future<String> accessToken({bool force = false});
}

class MobileSession extends ChangeNotifier implements MobileCredentials {
  MobileSession({
    FlutterAppAuth? auth,
    FlutterSecureStorage? storage,
    this.apiBaseUrl = MobileConfig.apiBaseUrl,
    this.issuer = MobileConfig.issuer,
  }) : _auth = auth ?? const FlutterAppAuth(),
       _storage = storage ?? const FlutterSecureStorage();

  final FlutterAppAuth _auth;
  final FlutterSecureStorage _storage;
  final String apiBaseUrl;
  final String issuer;
  String? _access;
  String? _refresh;
  DateTime? _expires;
  Future<String>? _refreshing;
  Map<String, dynamic>? account;
  int _generation = 0;
  @override
  int get generation => _generation;
  bool get signedIn => account != null && _access != null;
  @override
  int? get userId => account?['userId'] as int?;

  Future<void> signIn() async {
    if (apiBaseUrl.isEmpty || issuer.isEmpty) {
      throw StateError('Chưa cấu hình địa chỉ API và Keycloak cho App.');
    }
    final generation = ++_generation;
    final result = await _auth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        MobileConfig.clientId,
        MobileConfig.redirectUri,
        issuer: issuer,
        scopes: ['openid', 'profile'],
        // Chỉ bản debug cho Keycloak local qua http; release vẫn bắt buộc https.
        allowInsecureConnections: kDebugMode,
      ),
    );
    if (generation != _generation) {
      throw StateError('Phiên đăng nhập đã thay đổi.');
    }
    _access = result.accessToken;
    _refresh = result.refreshToken;
    _expires = result.accessTokenExpirationDateTime;
    if (_access == null || _refresh == null) {
      throw StateError('Phiên đăng nhập không đầy đủ.');
    }
    await _storage.write(key: 'auth.refresh', value: _refresh);
    try {
      final response = await _accountRequest(_access!);
      if (response['profileUpdateRequired'] == true) {
        throw StateError(
          'Bạn cần cập nhật hồ sơ theo yêu cầu của nhà trường trước khi sử dụng.',
        );
      }
      account = response;
      notifyListeners();
    } catch (_) {
      await clear();
      rethrow;
    }
  }

  @override
  Future<String> accessToken({bool force = false}) async {
    if (!force &&
        _access != null &&
        _expires != null &&
        _expires!.isAfter(DateTime.now().add(const Duration(seconds: 30)))) {
      return _access!;
    }
    _refresh ??= await _storage.read(key: 'auth.refresh');
    if (_refresh == null) throw StateError('Phiên đăng nhập đã hết hạn.');
    return _refreshing ??= _renew().whenComplete(() => _refreshing = null);
  }

  Future<String> _renew() async {
    final generation = _generation;
    final result = await _auth.token(
      TokenRequest(
        MobileConfig.clientId,
        MobileConfig.redirectUri,
        issuer: issuer,
        refreshToken: _refresh,
        allowInsecureConnections: kDebugMode,
      ),
    );
    if (generation != _generation || result.accessToken == null) {
      throw StateError('Phiên đăng nhập đã thay đổi.');
    }
    _access = result.accessToken;
    _refresh = result.refreshToken ?? _refresh;
    _expires = result.accessTokenExpirationDateTime;
    await _storage.write(key: 'auth.refresh', value: _refresh);
    return _access!;
  }

  Future<void> restore() async {
    if (apiBaseUrl.isEmpty ||
        issuer.isEmpty ||
        await _storage.read(key: 'auth.refresh') == null) {
      return;
    }
    try {
      final token = await accessToken();
      final response = await _accountRequest(token);
      if (response['profileUpdateRequired'] == true) {
        await clear();
        return;
      }
      account = response;
      notifyListeners();
    } catch (_) {
      _access = null;
      account = null;
    }
  }

  Future<Map<String, dynamic>> _accountRequest(String token) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('$apiBaseUrl/accounts/me'));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final body =
          jsonDecode(await utf8.decoder.bind(response).join())
              as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw HttpException(
          'Không thể xác minh tài khoản (${response.statusCode}).',
        );
      }
      return body['data'] as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }

  Future<void> clear() async {
    _generation++;
    _access = null;
    _refresh = null;
    _expires = null;
    account = null;
    await _storage.delete(key: 'auth.refresh');
    notifyListeners();
  }

  Future<void> signOut() async {
    final refresh = _refresh ?? await _storage.read(key: 'auth.refresh');
    if (refresh != null && issuer.isNotEmpty) {
      final client = HttpClient();
      try {
        final request = await client.postUrl(
          Uri.parse('$issuer/protocol/openid-connect/logout'),
        );
        request.headers.contentType = ContentType(
          'application',
          'x-www-form-urlencoded',
          charset: 'utf-8',
        );
        request.write(
          'client_id=${Uri.encodeQueryComponent(MobileConfig.clientId)}&refresh_token=${Uri.encodeQueryComponent(refresh)}',
        );
        await request.close().timeout(const Duration(seconds: 10));
      } catch (_) {
        /* Vẫn xóa phiên cục bộ khi ngoại tuyến. */
      } finally {
        client.close();
      }
    }
    await clear();
  }
}

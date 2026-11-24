import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'mobile_config.dart';
import 'mobile_session.dart';

class ApiFailure implements Exception {
  ApiFailure(this.status, this.message, [this.errorCode]);
  final int status;
  final String message;
  final Object? errorCode;
  @override
  String toString() => message;
}

class MobileApi {
  MobileApi(this.session, {this.baseUrl = MobileConfig.apiBaseUrl});
  final MobileCredentials session;
  final String baseUrl;

  Future<Object?> json(String method, String path, {Object? body}) async {
    final bytes = await _request(method, path, body: body);
    final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return decoded['data'];
  }

  Future<Uint8List> binary(String path) => _request('GET', path);

  /// API công khai (vd. `POST /parent-activation`, AUTH-18): không gửi Bearer, không cần phiên.
  Future<Object?> publicJson(String method, String path, {Object? body}) async {
    final bytes = await _request(method, path, body: body, auth: false);
    final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return decoded['data'];
  }

  Future<Uint8List> _request(
    String method,
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    final owner = session.userId;
    final generation = session.generation;
    if (auth && owner == null) {
      throw ApiFailure(401, 'Bạn cần đăng nhập.');
    }
    for (var attempt = 0; attempt < 2; attempt++) {
      final token = auth
          ? await session.accessToken(force: attempt == 1)
          : null;
      if (session.userId != owner || session.generation != generation) {
        throw ApiFailure(401, 'Phiên đăng nhập đã thay đổi.');
      }
      final client = HttpClient();
      try {
        final request = await client.openUrl(
          method,
          Uri.parse('$baseUrl$path'),
        );
        if (token != null) {
          request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        }
        if (body != null) {
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode(body));
        }
        final response = await request.close().timeout(
          const Duration(seconds: 15),
        );
        final bytes = await response.fold<BytesBuilder>(
          BytesBuilder(),
          (builder, chunk) => builder..add(chunk),
        );
        if (auth &&
            (session.userId != owner || session.generation != generation)) {
          throw ApiFailure(401, 'Phiên đăng nhập đã thay đổi.');
        }
        if (auth && response.statusCode == 401 && attempt == 0) continue;
        if (response.statusCode >= 400) {
          Map<String, dynamic> error = {};
          try {
            error =
                jsonDecode(utf8.decode(bytes.toBytes()))
                    as Map<String, dynamic>;
          } catch (_) {
            /* Lỗi không phải JSON. */
          }
          throw ApiFailure(
            response.statusCode,
            error['desc'] as String? ?? 'Không thể tải dữ liệu.',
            error['errorCode'],
          );
        }
        return bytes.toBytes();
      } finally {
        client.close();
      }
    }
    throw ApiFailure(401, 'Phiên đăng nhập đã hết hạn.');
  }

  Future<void> registerDevice(String token) async =>
      json('PUT', '/me/devices', body: {'token': token, 'platform': 'ANDROID'});
  Future<void> unregisterDevice(String token) async => json(
    'DELETE',
    '/me/devices',
    body: {'token': token, 'platform': 'ANDROID'},
  );
}

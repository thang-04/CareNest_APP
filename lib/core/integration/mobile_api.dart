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

  /// Gửi một tệp dạng `multipart/form-data` (vd. ảnh chân dung, ảnh bữa); Bearer và refresh như [json].
  Future<Object?> multipart(
    String method,
    String path, {
    required String field,
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    final boundary = 'carenest-${DateTime.now().microsecondsSinceEpoch}';
    final head = utf8.encode(
      '--$boundary\r\n'
      'Content-Disposition: form-data; name="$field"; filename="$filename"\r\n'
      'Content-Type: $contentType\r\n\r\n',
    );
    final tail = utf8.encode('\r\n--$boundary--\r\n');
    final raw = await _request(
      method,
      path,
      form: (
        type: ContentType(
          'multipart',
          'form-data',
          parameters: {'boundary': boundary},
        ),
        bytes: Uint8List.fromList([...head, ...bytes, ...tail]),
      ),
    );
    final decoded = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
    return decoded['data'];
  }

  Future<Uint8List> _request(
    String method,
    String path, {
    Object? body,
    bool auth = true,
    ({ContentType type, Uint8List bytes})? form,
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
        } else if (form != null) {
          request.headers.contentType = form.type;
          request.contentLength = form.bytes.length;
          request.add(form.bytes);
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

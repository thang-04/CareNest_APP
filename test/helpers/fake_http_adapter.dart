import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Một response giả xếp hàng sẵn cho [FakeHttpAdapter].
class FakeReply {
  FakeReply.json(this.status, Object? body)
    : text = jsonEncode(body),
      contentType = Headers.jsonContentType;

  FakeReply.text(this.status, this.text, {this.contentType = 'text/html'});

  /// Envelope BE `{code, errorCode, desc, data}` với dữ liệu giả.
  factory FakeReply.envelope(
    int status, {
    int? errorCode,
    String desc = 'ok',
    Object? data,
  }) => FakeReply.json(status, {
    'code': status,
    'errorCode': errorCode,
    'desc': desc,
    'data': data,
  });

  final int status;
  final String text;
  final String contentType;
}

/// Adapter HTTP giả: trả lần lượt các [FakeReply], ghi lại request đã nhận.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter([List<FakeReply>? replies]) : _replies = [...?replies];

  final List<FakeReply> _replies;
  final List<RequestOptions> requests = [];

  void enqueue(FakeReply reply) => _replies.add(reply);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (_replies.isEmpty) {
      throw StateError('FakeHttpAdapter: no reply for ${options.uri}');
    }
    final reply = _replies.removeAt(0);
    return ResponseBody.fromString(
      reply.text,
      reply.status,
      headers: {
        Headers.contentTypeHeader: [reply.contentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

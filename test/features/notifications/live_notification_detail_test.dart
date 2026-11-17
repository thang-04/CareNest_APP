import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/integration/mobile_session.dart';
import 'package:carenest_app/features/notifications/presentation/screens/live_notifications_screen.dart';

class FakeCredentials implements MobileCredentials {
  @override
  int get generation => 1;
  @override
  int? get userId => 1;
  @override
  Future<String> accessToken({bool force = false}) async => 'fake';
}

class DetailApi extends MobileApi {
  DetailApi() : super(FakeCredentials());
  final calls = <String>[];
  bool forbidden = false;
  @override
  Future<Object?> json(String method, String path, {Object? body}) async {
    calls.add('$method $path');
    if (forbidden) throw ApiFailure(403, 'forbidden');
    if (path == '/me/notifications/77') {
      return {
        'id': 77,
        'title': 'Bản tóm tắt',
        'body': 'ngắn',
        'announcementId': 88,
      };
    }
    if (path == '/me/announcements/88') {
      return {
        'id': 88,
        'title': 'Bản đầy đủ',
        'body': 'D' * 700,
        'senderName': 'Người gửi mẫu',
        'attachments': [
          {'id': 9, 'fileName': 'demo.pdf', 'contentType': 'application/pdf'},
        ],
      };
    }
    return {};
  }

  @override
  Future<Uint8List> binary(String path) async {
    calls.add('GET $path');
    return Uint8List.fromList([1, 2, 3]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('mở A20 rồi A07 để hiện toàn văn và tải tệp A08 có xác thực', (
    tester,
  ) async {
    final api = DetailApi();
    Map<Object?, Object?>? saved;
    const channel = MethodChannel('carenest/files');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          saved = call.arguments as Map<Object?, Object?>;
          return null;
        });
    await tester.pumpWidget(
      MaterialApp(home: LiveNotificationDetailScreen(api: api, id: 77)),
    );
    await tester.pumpAndSettle();
    expect(find.text('D' * 700), findsOneWidget);
    expect(find.text('Người gửi: Người gửi mẫu'), findsOneWidget);
    await tester.ensureVisible(find.text('demo.pdf'));
    await tester.tap(find.text('demo.pdf'));
    await tester.pumpAndSettle();
    expect(saved?['name'], 'demo.pdf');
    expect(api.calls, [
      'GET /me/notifications/77',
      'GET /me/announcements/88',
      'POST /me/notifications/77/read',
      'GET /announcement-attachments/9/content',
    ]);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('403 hiển thị an toàn và không gọi nội dung tin trường', (
    tester,
  ) async {
    final api = DetailApi()..forbidden = true;
    await tester.pumpWidget(
      MaterialApp(home: LiveNotificationDetailScreen(api: api, id: 77)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('không có quyền'), findsOneWidget);
    expect(api.calls, ['GET /me/notifications/77']);
  });
}

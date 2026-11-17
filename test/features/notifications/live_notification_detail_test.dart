import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/integration/mobile_session.dart';
import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/account/domain/account_profile.dart';
import 'package:carenest_app/features/notifications/data/live_notification_source.dart';
import 'package:carenest_app/features/notifications/presentation/screens/notification_detail_screen.dart';
import 'package:carenest_app/features/notifications/presentation/screens/notifications_screen.dart';

import '../../helpers/pump_app.dart';

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
    if (path == '/me/notifications') {
      return {
        'unreadCount': 1,
        'items': [
          {
            'id': 77,
            'type': 'SCHOOL_ANNOUNCEMENT',
            'typeLabel': 'Thông báo của trường',
            'title': 'Họp phụ huynh',
            'body': 'Tóm tắt',
            'createdAt': '2026-11-18T01:00:00Z',
            'readAt': null,
          },
          {
            'id': 76,
            'type': 'MENU_PUBLISHED',
            'typeLabel': 'Thực đơn',
            'title': 'Thực đơn tuần mới',
            'createdAt': '2026-11-10T01:00:00Z',
            'readAt': '2026-11-10T02:00:00Z',
          },
        ],
      };
    }
    if (path == '/me/notifications/77') {
      return {
        'id': 77,
        'title': 'Bản tóm tắt',
        'body': 'ngắn',
        'typeLabel': 'Thông báo của trường',
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

Future<void> pumpDetail(WidgetTester tester, DetailApi api) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: NotificationDetailScreen(
        role: AppRole.parent,
        id: '77',
        source: LiveNotificationSource(api),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('mở A20 rồi A07 để hiện toàn văn và tải tệp A08 có xác thực', (
    tester,
  ) async {
    usePhoneSize(tester);
    final api = DetailApi();
    Map<Object?, Object?>? saved;
    const channel = MethodChannel('carenest/files');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          saved = call.arguments as Map<Object?, Object?>;
          return null;
        });
    await pumpDetail(tester, api);
    expect(find.text('Bản đầy đủ'), findsOneWidget);
    expect(find.text('Thông báo của trường'), findsOneWidget);
    expect(find.text('D' * 700), findsOneWidget);
    expect(find.textContaining('Người gửi mẫu'), findsOneWidget);
    // Toàn văn dài đẩy tệp xuống dưới; ListView chỉ dựng phần đang hiện
    await tester.scrollUntilVisible(find.text('demo.pdf'), 300);
    await tester.ensureVisible(find.text('demo.pdf'));
    await tester.pumpAndSettle();
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
    usePhoneSize(tester);
    final api = DetailApi()..forbidden = true;
    await pumpDetail(tester, api);
    expect(find.text('Không tìm thấy thông báo'), findsOneWidget);
    expect(api.calls, ['GET /me/notifications/77']);
  });

  testWidgets(
    'danh sách thật: nhóm theo ngày, nhãn loại, đánh dấu đã đọc gọi BE',
    (tester) async {
      usePhoneSize(tester);
      final api = DetailApi();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(
            body: NotificationsScreen(
              role: AppRole.parent,
              source: LiveNotificationSource(api),
              today: DateTime(2026, 11, 18, 12),
              onOpen: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hôm nay'), findsOneWidget);
      expect(find.text('Trước đó'), findsOneWidget);
      expect(find.text('Thông báo của trường'), findsOneWidget);
      expect(find.text('Chưa đọc (1)'), findsOneWidget);

      await tester.tap(find.text('Đánh dấu đã đọc'));
      await tester.pumpAndSettle();
      expect(api.calls, contains('POST /me/notifications/read-all'));
      expect(find.text('Chưa đọc (0)'), findsOneWidget);
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/account/domain/account_profile.dart';
import 'package:carenest_app/features/notifications/domain/app_notification.dart';
import 'package:carenest_app/features/notifications/presentation/screens/notification_detail_screen.dart';
import 'package:carenest_app/features/notifications/presentation/screens/notifications_screen.dart';

import '../../helpers/pump_app.dart';

Future<void> pumpList(
  WidgetTester tester, {
  ValueChanged<String>? onOpen,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: NotificationsScreen(
          role: AppRole.parent,
          onOpen: onOpen ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('P06: lọc Chưa đọc, Đánh dấu đã đọc làm số về 0', (tester) async {
    usePhoneSize(tester);
    await pumpList(tester);
    expect(find.text('Chưa đọc (2)'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Chưa đọc, ')), findsNWidgets(2));

    await tester.tap(find.text('Chưa đọc (2)'));
    await tester.pump();
    expect(find.text('Bé Minh Anh đã được đón'), findsNothing);

    await tester.tap(find.text('Đánh dấu đã đọc'));
    await tester.pump();
    expect(find.text('Chưa đọc (0)'), findsOneWidget);
    expect(find.text('Không có thông báo chưa đọc'), findsOneWidget);
  });

  testWidgets('Figma audit: P06 kết quả cân đo ghi ngày công bố 05/10', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpList(tester);
    expect(find.text('Kết quả cân đo tháng 10 đã công bố'), findsOneWidget);
    expect(find.text('05/10/2026 · 15:20'), findsOneWidget);
  });

  testWidgets(
    'Plan 14/11 (PAR-07): phụ huynh nhận các loại BE gửi; không có thông báo tự chế',
    (tester) async {
      usePhoneSize(tester);
      await pumpList(tester);
      for (final title in [
        'Sức khỏe của bé cần lưu ý',
        'Nhận xét tuần 05/10 – 09/10 của bé',
        'Bé Minh Anh đã được đón',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
      expect(find.textContaining('Thực đơn tuần'), findsNothing);
      expect(find.textContaining('điểm danh: Có mặt'), findsNothing);
      expect(find.textContaining('huỷ tự động'), findsNothing);
    },
  );

  test('Plan 14/11 (PAR-07): loại BE chưa biết ⇒ unknown, không lỗi', () {
    expect(
      NotificationType.fromCode('DAILY_HEALTH_NOTED'),
      NotificationType.dailyHealthNoted,
    );
    expect(
      NotificationType.fromCode('SOMETHING_NEW'),
      NotificationType.unknown,
    );
    expect(NotificationType.fromCode(''), NotificationType.unknown);
  });

  testWidgets('P06: mở một thông báo ⇒ trả ID và đánh dấu đã đọc', (
    tester,
  ) async {
    usePhoneSize(tester);
    String? opened;
    await pumpList(tester, onOpen: (id) => opened = id);
    await tester.tap(find.text('Sức khỏe của bé cần lưu ý'));
    await tester.pump();
    expect(opened, 'p1');
    expect(find.text('Chưa đọc (1)'), findsOneWidget);
  });

  testWidgets('P07 (PAR-07): chi tiết không có ảnh, có lối mở màn theo loại', (
    tester,
  ) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: const NotificationDetailScreen(role: AppRole.parent, id: 'p1'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bé Nguyễn Minh Anh · Mầm 3A'), findsOneWidget);
    expect(find.bySemanticsLabel('Ảnh đính kèm'), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(find.text('Xem hôm nay của bé'), findsOneWidget);
    expect(find.textContaining('Sốt'), findsNothing);
  });

  testWidgets('P07: ID không có ⇒ báo không tìm thấy', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: const NotificationDetailScreen(role: AppRole.parent, id: 'x'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy thông báo'), findsOneWidget);
  });

  testWidgets('AC-10: danh sách và chi tiết chữ 2.0 không tràn', (
    tester,
  ) async {
    usePhoneSize(tester, textScale: 2);
    await pumpList(tester);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: const NotificationDetailScreen(role: AppRole.parent, id: 'p1'),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

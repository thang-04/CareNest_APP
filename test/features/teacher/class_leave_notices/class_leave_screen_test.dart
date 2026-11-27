import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/features/teacher/class_leave_notices/presentation/screens/class_leave_screen.dart';

import '../../../helpers/pump_app.dart';

Future<void> pump(WidgetTester tester, DateTime today) async {
  usePhoneSize(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: ClassLeaveScreen(today: today),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Đơn xin nghỉ của lớp: trường như Web, chỉ xem, khoảng mặc định',
    (tester) async {
      await pump(tester, DateTime(2026, 10, 12));
      expect(find.text('Đơn xin nghỉ của lớp'), findsOneWidget);
      expect(find.text('Hôm nay & sắp tới'), findsOneWidget);
      expect(
        find.textContaining('Buổi chiều · Không ăn (Bữa trưa)'),
        findsOneWidget,
      );
      expect(
        find.text('Báo nghỉ chiều sau giờ chốt · không đổi điểm danh/suất ăn'),
        findsOneWidget,
      );
      expect(find.byType(AppButton), findsNothing);
      // Tất cả: hiện khoảng ngày mặc định; đơn 29/9 vẫn ngoài khoảng
      await tester.tap(find.text('Tất cả'));
      await tester.pumpAndSettle();
      expect(find.text('Từ 01/10/2026'), findsOneWidget);
      expect(find.text('Đến 11/12/2026'), findsOneWidget);
      expect(find.text('Lê Hoàng Nam'), findsNothing);
    },
  );

  testWidgets('khoảng ngày không có đơn ⇒ Không có đơn xin nghỉ', (
    tester,
  ) async {
    await pump(tester, DateTime(2027, 6, 1));
    expect(find.text('Không có đơn xin nghỉ'), findsOneWidget);
  });
}

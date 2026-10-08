import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/ui_kit/presentation/screens/ui_kit_screen.dart';

void main() {
  testWidgets(
    'AC-8: UiKitScreen dựng đủ section, không overflow ở 360 rộng + chữ 1.3x',
    (tester) async {
      // Cao đủ lớn để ListView dựng hết mọi section trong một lần
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 8000);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        MaterialApp(theme: buildLightTheme(), home: const UiKitScreen()),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      for (final title in [
        'Màu',
        'Chữ',
        'Nút',
        'Ô nhập',
        'Card',
        'Badge',
        'Tải, rỗng, lỗi',
        'Xác nhận và thông báo',
      ]) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
      expect(
        find.byType(AppStatusBadge),
        findsNWidgets(AppStatusTone.values.length),
      );
    },
  );
}

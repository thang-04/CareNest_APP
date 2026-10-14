import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';

import '../../helpers/pump_app.dart';

List<BoxShadow>? _buttonShadows(WidgetTester tester) {
  final boxes = tester.widgetList<DecoratedBox>(
    find.ancestor(
      of: find.byType(FilledButton),
      matching: find.byType(DecoratedBox),
    ),
  );
  for (final box in boxes) {
    final decoration = box.decoration;
    if (decoration is ShapeDecoration) return decoration.shadows;
  }
  return null;
}

void main() {
  testWidgets('Nút chính bấm được có gờ đáy clay', (tester) async {
    await pumpWithTheme(tester, AppButton(label: 'Gửi', onPressed: () {}));
    expect(_buttonShadows(tester), AppShadows.buttonPrimary);
  });

  testWidgets('Nút khoá và nút đang gửi không có bóng', (tester) async {
    await pumpWithTheme(
      tester,
      const Column(
        children: [
          AppButton(label: 'Lưu', onPressed: null),
          AppButton(label: 'Gửi', onPressed: null, isLoading: true),
        ],
      ),
    );
    expect(_buttonShadows(tester), isNull);
  });

  testWidgets('Badge clay không viền, có quầng màu tông', (tester) async {
    await pumpWithTheme(
      tester,
      const AppStatusBadge(label: 'Có mặt', tone: AppStatusTone.green),
    );
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(AppStatusBadge),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.border, isNull);
    expect(decoration.boxShadow, isNotEmpty);
  });

  testWidgets('Vùng nút đáy nổi không tràn ở khổ 320, chữ x2', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: AppCard(
              child: AppCardHeader(
                title: 'Điểm danh & báo ăn hôm nay',
                trailing: AppStatusBadge(
                  label: 'Cần làm',
                  tone: AppStatusTone.orange,
                ),
              ),
            ),
          ),
          bottomNavigationBar: AppBottomDock(
            children: [
              AppButton(
                label: 'Lưu điểm danh (27/28)',
                onPressed: () {},
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Lưu điểm danh (27/28)'), findsOneWidget);
  });
}

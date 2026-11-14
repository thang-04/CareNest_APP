import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('Nút chính phẳng: nền brand, chữ trắng, bo 8', (tester) async {
    await pumpWithTheme(tester, AppButton(label: 'Gửi', onPressed: () {}));
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, AppColors.brand);
    expect(material.elevation, 0);
    final shape = material.shape! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(8));
    expect(
      tester.widget<Text>(find.text('Gửi')).style?.color ??
          DefaultTextStyle.of(tester.element(find.text('Gửi'))).style.color,
      AppColors.onBrand,
    );
  });

  testWidgets('Card phẳng có viền mảnh', (tester) async {
    await pumpWithTheme(tester, const AppCard(child: Text('Nội dung')));
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(AppCard),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.border, Border.all(color: AppColors.border));
  });

  testWidgets('Badge phẳng không viền, không quầng màu', (tester) async {
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
    expect(decoration.boxShadow, isNull);
  });

  testWidgets('Vùng nút đáy không tràn ở khổ 320, chữ x2', (tester) async {
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

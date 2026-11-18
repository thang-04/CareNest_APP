import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/kitchen/kitchen_day/data/fake_kitchen_day_source.dart';
import 'package:carenest_app/features/kitchen/kitchen_day/presentation/screens/food_needs_screen.dart';
import 'package:carenest_app/features/kitchen/kitchen_day/presentation/screens/kitchen_menu_screen.dart';
import 'package:carenest_app/features/kitchen/kitchen_day/presentation/screens/kitchen_servings_screen.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

import '../../../helpers/pump_app.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  double textScale = 1,
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(MaterialApp(theme: buildLightTheme(), home: screen));
  await tester.pumpAndSettle();
}

void main() {
  group('Suất ăn theo lớp', () {
    testWidgets('mặc định bữa đầu, đổi bữa thì đổi số thay thế', (
      tester,
    ) async {
      await _pump(
        tester,
        KitchenServingsScreen(
          source: FakeKitchenDaySource(delay: Duration.zero),
        ),
      );

      expect(find.text('Mầm 3A'), findsOneWidget);
      expect(find.text('Đã xác nhận lúc 08:30'), findsOneWidget);
      // Bữa phụ sáng: không có suất thay thế
      expect(find.text('127'), findsNWidgets(2));
      expect(find.text('Lá 1'), findsNothing);

      await tester.tap(find.text('Trưa'));
      await tester.pumpAndSettle();
      expect(find.text('200'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Lá · 69 suất'), 200);
      expect(find.text('Lá · 69 suất'), findsOneWidget);
    });

    testWidgets('chưa xác nhận thì không hiện số', (tester) async {
      await _pump(
        tester,
        KitchenServingsScreen(
          source: FakeKitchenDaySource(
            mode: FakeMode.empty,
            delay: Duration.zero,
          ),
        ),
      );
      expect(find.text('Chưa có suất đã xác nhận'), findsOneWidget);
      expect(find.text('Mầm 3A'), findsNothing);
    });

    testWidgets('chữ phóng to 200% không tràn', (tester) async {
      await _pump(
        tester,
        KitchenServingsScreen(
          source: FakeKitchenDaySource(delay: Duration.zero),
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Thực phẩm cần', () {
    testWidgets('chia hàng tươi, hàng khô, giữ đơn vị BE', (tester) async {
      await _pump(
        tester,
        FoodNeedsScreen(source: FakeKitchenDaySource(delay: Duration.zero)),
      );
      expect(find.text('Hàng tươi'), findsOneWidget);
      expect(find.text('Hàng khô'), findsOneWidget);
      expect(find.text('18,2 kg'), findsOneWidget);
      expect(find.text('109 hộp'), findsOneWidget);
    });

    testWidgets('lỗi tải thì có nút thử lại', (tester) async {
      await _pump(
        tester,
        FoodNeedsScreen(
          source: FakeKitchenDaySource(
            mode: FakeMode.error,
            delay: Duration.zero,
          ),
        ),
      );
      expect(find.text('Chưa tải được thực phẩm cần'), findsOneWidget);
    });
  });

  group('Thực đơn hôm nay', () {
    testWidgets('nhóm tuổi + bữa ⇒ món và gam/trẻ của nhóm đó', (tester) async {
      await _pump(
        tester,
        Scaffold(
          body: KitchenMenuScreen(
            source: FakeKitchenDaySource(delay: Duration.zero),
          ),
        ),
      );
      // Mặc định Nhà trẻ · bữa phụ sáng: món khối Nhà trẻ
      expect(find.text('Sữa công thức'), findsOneWidget);
      expect(find.text('Sữa tươi'), findsNothing);

      await tester.tap(find.text('Lá'));
      await tester.pumpAndSettle();
      // Lá không ăn bữa phụ sáng ⇒ chỉ Trưa, Chiều
      expect(find.text('Sáng'), findsNothing);
      expect(find.text('Lá · Bữa trưa · 69 suất'), findsOneWidget);
      expect(find.text('Cơm tẻ'), findsOneWidget);
      expect(find.text('60 g'), findsWidgets);

      await tester.tap(find.text('Mầm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trưa'));
      await tester.pumpAndSettle();
      expect(find.text('Mầm · Bữa trưa · 51 suất'), findsOneWidget);
      expect(find.text('Gạo tẻ'), findsOneWidget);
      expect(find.text('50 g'), findsWidgets);
    });

    testWidgets('chữ phóng to 200% không tràn', (tester) async {
      await _pump(
        tester,
        Scaffold(
          body: KitchenMenuScreen(
            source: FakeKitchenDaySource(delay: Duration.zero),
          ),
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

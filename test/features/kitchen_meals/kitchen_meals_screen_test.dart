import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/cooking_status/data/fake_cooking_status_source.dart';
import 'package:carenest_app/features/cooking_status/presentation/screens/cooking_status_screen.dart';
import 'package:carenest_app/features/food_quantities/presentation/screens/food_quantities_screen.dart';
import 'package:carenest_app/features/ingredient_receipt/data/fake_ingredient_receipt_source.dart';
import 'package:carenest_app/features/ingredient_receipt/presentation/screens/ingredient_receipt_screen.dart';
import 'package:carenest_app/features/ingredient_receipt/presentation/screens/shortage_report_screen.dart';
import 'package:carenest_app/features/kitchen_home/data/fake_kitchen_home_source.dart';
import 'package:carenest_app/features/kitchen_home/presentation/screens/kitchen_home_screen.dart';
import 'package:carenest_app/features/kitchen_meals/data/fake_kitchen_meals_source.dart';
import 'package:carenest_app/features/kitchen_meals/presentation/screens/kitchen_meals_screen.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/school_menu/presentation/screens/school_menu_screen.dart';

import '../../helpers/pump_app.dart';

final today = DateTime(2026, 10, 12);

Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  double textScale = 1,
  bool inScaffold = false,
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: inScaffold ? Scaffold(body: screen) : screen,
    ),
  );
  await tester.pumpAndSettle();
}

String? labelOf(String prefix) => find
    .bySemanticsLabel(RegExp('^$prefix'))
    .evaluate()
    .firstOrNull
    ?.renderObject
    ?.debugSemantics
    ?.label;

void main() {
  testWidgets('K01: thẻ bếp có trạng thái nấu, suất đã chốt, việc của bếp', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      KitchenHomeScreen(
        source: FakeKitchenHomeSource(delay: Duration.zero),
        cookingSource: FakeCookingStatusSource(),
      ),
      inScaffold: true,
    );
    expect(find.text('Nguyễn Thị Mai'), findsOneWidget);
    expect(find.text('Đang nấu'), findsOneWidget);
    expect(labelOf('Suất ăn đã chốt lúc 08:30'), contains('182 suất'));
    await tester.scrollUntilVisible(find.text('Nhận nguyên liệu'), 200);
    expect(find.text('Cần làm'), findsOneWidget);
  });

  testWidgets('K01: lỗi tải ⇒ Thử lại, không để khung chờ chạy mãi', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      KitchenHomeScreen(
        source: FakeKitchenHomeSource(
          mode: FakeMode.error,
          delay: Duration.zero,
        ),
        cookingSource: FakeCookingStatusSource(),
      ),
      inScaffold: true,
    );
    await tester.scrollUntilVisible(find.text('Thử lại'), 200);
  });

  testWidgets('K02 (NUT-08): thực đơn theo nhóm tuổi, thay thế không tên trẻ', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      SchoolMenuScreen(asTab: true, initialDay: today, footerNote: 'Chỉ xem.'),
      inScaffold: true,
    );
    expect(find.textContaining('Nhóm Mầm (3–4 tuổi) · 51 bé'), findsOneWidget);
    expect(find.textContaining('Cá basa sốt cà 45 g'), findsOneWidget);
    await tester.tap(find.text('Chồi'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Ăn chay · 2 bé'), 200);
    expect(find.textContaining('Nguyễn'), findsNothing);
  });

  testWidgets('K03 / AC-6 (AUTH-05, NUT-02): suất theo lớp, không tên trẻ', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      KitchenMealsScreen(source: FakeKitchenMealsSource(delay: Duration.zero)),
    );
    expect(find.bySemanticsLabel('Tổng suất: 182'), findsOneWidget);
    expect(find.textContaining('chờ Phó HT duyệt'), findsOneWidget);
    expect(
      labelOf('Mầm 3A'),
      'Mầm 3A, 24 suất thường, 1 suất thay thế, dị ứng hải sản, có điều chỉnh chờ duyệt',
    );
    expect(find.textContaining('Nguyễn'), findsNothing);
    expect(find.textContaining('Hoàng Nam'), findsNothing);
  });

  testWidgets('K03 (NUT-02): chưa xác nhận ⇒ không có số để nấu', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      KitchenMealsScreen(
        source: FakeKitchenMealsSource(
          mode: FakeMode.empty,
          delay: Duration.zero,
        ),
      ),
    );
    expect(find.text('Chưa có số suất đã chốt'), findsOneWidget);
  });

  testWidgets('K04 (NUT-07): định lượng 182 suất, phiếu xuất kho đã duyệt', (
    tester,
  ) async {
    await pumpScreen(tester, const FoodQuantitiesScreen());
    expect(find.text('Phiếu xuất kho PXK-1012 · Đã duyệt'), findsOneWidget);
    expect(find.textContaining('(182 SUẤT)'), findsOneWidget);
    expect(find.text('10,5 kg'), findsOneWidget);
  });

  testWidgets('K05: số nhận thiếu báo chênh lệch, sửa đủ thì hết', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      IngredientReceiptScreen(
        source: FakeIngredientReceiptSource(),
        onReportShortage: () {},
        onConfirmed: () {},
      ),
    );
    expect(find.text('Theo phiếu: 10,5 kg · Thiếu 0,7 kg'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Có 1 chênh lệch'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.scrollUntilVisible(
      find.text('Cá basa phi lê'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField).at(1), '10,5');
    await tester.pump();
    expect(find.textContaining('chênh lệch'), findsNothing);
  });

  testWidgets('K06: báo thiếu điền sẵn món thiếu, gửi cho Phó HT', (
    tester,
  ) async {
    final source = FakeIngredientReceiptSource();
    var sent = false;
    await pumpScreen(
      tester,
      ShortageReportScreen(source: source, onSent: () => sent = true),
    );
    expect(find.text('Cá basa phi lê'), findsOneWidget);
    expect(find.text('0,7 kg'), findsOneWidget);
    await tester.tap(find.text('Gửi báo thiếu cho Phó HT'));
    await tester.pumpAndSettle();
    expect(sent, isTrue);
    expect(source.reports.single.food, 'Cá basa phi lê');
  });

  testWidgets('K07 (NUT-14): chuyển bước nấu; Phó HT chỉ xem', (tester) async {
    final source = FakeCookingStatusSource();
    await pumpScreen(tester, CookingStatusScreen(source: source));
    expect(labelOf('Đang nấu'), startsWith('Đang nấu, đang ở bước này'));
    await tester.tap(find.text('Chuyển sang “Đã nấu xong”'));
    await tester.pumpAndSettle();
    expect(labelOf('Đã nấu xong'), startsWith('Đã nấu xong, đang ở bước này'));

    await pumpScreen(
      tester,
      CookingStatusScreen(source: source, readOnly: true),
    );
    expect(find.textContaining('Chuyển sang'), findsNothing);
  });

  for (final (name, screen, scaffold) in <(String, Widget, bool)>[
    (
      'Trang chủ bếp',
      KitchenHomeScreen(source: FakeKitchenHomeSource(delay: Duration.zero)),
      true,
    ),
    (
      'Thực đơn',
      SchoolMenuScreen(asTab: true, initialDay: today, footerNote: 'Chỉ xem.'),
      true,
    ),
    (
      'Suất ăn',
      KitchenMealsScreen(source: FakeKitchenMealsSource(delay: Duration.zero)),
      false,
    ),
    ('Định lượng', const FoodQuantitiesScreen(), false),
    (
      'Nhận nguyên liệu',
      IngredientReceiptScreen(onReportShortage: () {}, onConfirmed: () {}),
      false,
    ),
    ('Báo thiếu', ShortageReportScreen(onSent: () {}), false),
    ('Trạng thái nấu', const CookingStatusScreen(), false),
  ]) {
    testWidgets('AC-10: $name chữ 2.0 không tràn', (tester) async {
      await pumpScreen(tester, screen, textScale: 2, inScaffold: scaffold);
      expect(tester.takeException(), isNull);
    });
  }
}

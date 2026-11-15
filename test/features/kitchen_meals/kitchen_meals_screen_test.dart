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
import 'package:carenest_app/features/kitchen_meal_samples/data/fake_meal_sample_source.dart';
import 'package:carenest_app/features/kitchen_meal_samples/domain/meal_samples.dart';
import 'package:carenest_app/features/kitchen_meal_samples/presentation/screens/meal_sample_screen.dart';
import 'package:carenest_app/features/kitchen_meals/data/fake_kitchen_meals_source.dart';
import 'package:carenest_app/features/kitchen_meals/presentation/screens/kitchen_meals_screen.dart';
import 'package:carenest_app/features/kitchen_sample_log/data/fake_sample_log_source.dart';
import 'package:carenest_app/features/kitchen_sample_log/presentation/screens/sample_log_screen.dart';
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
  testWidgets('K01 bố cục D: số suất chữ lớn, việc của bếp', (tester) async {
    await pumpScreen(
      tester,
      KitchenHomeScreen(source: FakeKitchenHomeSource(delay: Duration.zero)),
      inScaffold: true,
    );
    expect(find.text('Bếp cơ sở chính'), findsOneWidget);
    expect(labelOf('Bữa trưa đã chốt lúc 08:30'), contains('182 suất'));
    expect(labelOf('Bữa trưa đã chốt lúc 08:30'), contains('7 thay thế'));
  });

  testWidgets(
    'Redraw AC-15 (NUT-07, AUTH-05, NUT-14): việc bếp theo bản sửa, không trạng thái nấu, nhận nguyên liệu, phiếu xuất kho',
    (tester) async {
      await pumpScreen(
        tester,
        KitchenHomeScreen(source: FakeKitchenHomeSource(delay: Duration.zero)),
        inScaffold: true,
      );
      await tester.scrollUntilVisible(find.text('Sổ lưu mẫu'), 200);
      for (final (title, subtitle) in [
        ('Định lượng thực phẩm', 'Theo 182 suất đã xác nhận'),
        ('Ảnh mẫu bữa', 'Bữa trưa · chụp 10:30–11:30'),
        ('Sổ lưu mẫu', 'Bữa trưa chưa ghi mẫu'),
      ]) {
        expect(find.text(title), findsOneWidget, reason: title);
        expect(find.text(subtitle), findsOneWidget, reason: subtitle);
      }
      expect(find.text('Ghi'), findsOneWidget);
      expect(find.text('Xem'), findsNWidgets(2));
      // Figma Bếp 01: số đổi do GV sửa điểm danh, không còn chờ duyệt (NUT-04)
      expect(find.text('6 lớp · cập nhật 09:05'), findsOneWidget);
      expect(find.text('+1 suất'), findsOneWidget);
      expect(find.textContaining('Chờ duyệt'), findsNothing);
      for (final gone in [
        'Đang nấu',
        'Cập nhật trạng thái',
        'Cập nhật trạng thái nấu',
        'Nhận nguyên liệu',
        'Định lượng & phiếu xuất kho',
        'Đã duyệt',
      ]) {
        expect(find.text(gone), findsNothing, reason: gone);
      }
      expect(find.textContaining('PXK'), findsNothing);
      expect(find.textContaining('Tiến độ'), findsNothing);
    },
  );

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
    await tester.scrollUntilVisible(find.text('Dị ứng hải sản · 1 bé'), 200);
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
    expect(
      find.text('09:05 · Mầm 3A +1 suất (giáo viên sửa điểm danh)'),
      findsOneWidget,
    );
    expect(
      labelOf('Mầm 3A'),
      'Mầm 3A, 24 suất thường, 1 suất thay thế, dị ứng hải sản, có điều chỉnh',
    );
    expect(find.textContaining('Nguyễn'), findsNothing);
    expect(find.textContaining('Hoàng Nam'), findsNothing);
  });

  testWidgets('Figma audit: K03 sửa điểm danh không còn "chờ duyệt" (NUT-04)', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      KitchenMealsScreen(source: FakeKitchenMealsSource(delay: Duration.zero)),
    );
    expect(find.textContaining('duyệt', skipOffstage: false), findsNothing);
    expect(find.textContaining(' xin ', skipOffstage: false), findsNothing);
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

  testWidgets(
    'Redraw AC-16 (NUT-07, NUT-11): định lượng theo 182 suất đã xác nhận, không phiếu xuất kho',
    (tester) async {
      await pumpScreen(tester, const FoodQuantitiesScreen());
      expect(find.text('Bữa trưa · 182 suất đã xác nhận'), findsOneWidget);
      expect(
        find.text('Định lượng hệ thống tính theo số suất'),
        findsOneWidget,
      );
      expect(find.textContaining('(182 suất)'), findsOneWidget);
      expect(find.text('10,5 kg'), findsOneWidget);
      expect(find.text('Xem cách chế biến'), findsOneWidget);
      expect(find.textContaining('phiếu xuất kho'), findsNothing);
      expect(find.textContaining('Phiếu xuất kho'), findsNothing);
      expect(find.textContaining('duyệt'), findsNothing);
    },
  );

  testWidgets(
    'Redraw AC-17 (NUT-16, PAR-01): ảnh mẫu suất thường + thay thế trong khung giờ, không tên trẻ',
    (tester) async {
      final source = FakeMealSampleSource();
      var saved = false;
      await pumpScreen(
        tester,
        MealSampleScreen(source: source, onSaved: () => saved = true),
      );
      expect(find.text('Ảnh mẫu bữa'), findsOneWidget);
      expect(find.text('Bếp cơ sở chính · Thứ Hai, 12/10'), findsOneWidget);
      expect(find.text('Chụp trong 10:30–11:30'), findsOneWidget);
      expect(find.text('Đã chụp (1/2)'), findsOneWidget);
      expect(find.bySemanticsLabel('Mẫu suất thường, đã chụp'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Mẫu suất thay thế, chưa chụp'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Theo món thay thế, không tên trẻ'),
        200,
      );
      expect(find.text('Theo món thay thế, không tên trẻ'), findsOneWidget);
      expect(find.textContaining('Hoàng Nam'), findsNothing);

      final shutter = find.bySemanticsLabel('Chụp Mẫu suất thay thế');
      await tester.ensureVisible(shutter);
      await tester.tap(shutter);
      await tester.pump();
      expect(find.text('Đã chụp (2/2)'), findsOneWidget);

      await tester.tap(find.text('Lưu ảnh mẫu'));
      await tester.pumpAndSettle();
      expect(saved, isTrue);
      expect(source.saved, [MealSlot.lunch]);
    },
  );

  testWidgets(
    'Redraw AC-18 (NUT-21): sổ lưu mẫu bữa · món, khối lượng, nhiệt độ, giờ lấy mẫu; PHT duyệt',
    (tester) async {
      final source = FakeSampleLogSource();
      var saved = false;
      await pumpScreen(
        tester,
        SampleLogScreen(source: source, onSaved: () => saved = true),
      );
      expect(find.text('Sổ lưu mẫu'), findsOneWidget);
      expect(find.text('Bữa trưa · Cá basa sốt cà'), findsOneWidget);
      for (final label in [
        'Bữa · món lưu mẫu',
        'Khối lượng · dụng cụ chứa',
        'Nhiệt độ bảo quản',
        'Giờ lấy mẫu',
      ]) {
        expect(find.textContaining(label), findsOneWidget, reason: label);
      }
      expect(find.text('11:05 · hủy sau ít nhất 24 giờ'), findsOneWidget);
      expect(find.text('Mẫu đủ món theo thực đơn đã công bố.'), findsOneWidget);
      expect(
        find.text('PHT dinh dưỡng duyệt; sau ít nhất 24 giờ bếp ghi hủy mẫu.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Ghi lưu mẫu'));
      await tester.pump();
      expect(find.text('Nhập khối lượng và dụng cụ chứa.'), findsOneWidget);
      expect(find.text('Nhập nhiệt độ bảo quản.'), findsOneWidget);
      expect(saved, isFalse);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '150 g · hộp inox có nắp');
      await tester.enterText(fields.at(1), '0–5 °C');
      await tester.tap(find.text('Ghi lưu mẫu'));
      await tester.pumpAndSettle();
      expect(saved, isTrue);
      final entry = source.entries.single;
      expect(entry.dishId, 'l-ca');
      expect(entry.amountAndContainer, '150 g · hộp inox có nắp');
      expect(entry.storageTemperature, '0–5 °C');
    },
  );

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
      'Ảnh mẫu bữa',
      MealSampleScreen(source: FakeMealSampleSource(), onSaved: () {}),
      false,
    ),
    (
      'Sổ lưu mẫu',
      SampleLogScreen(source: FakeSampleLogSource(), onSaved: () {}),
      false,
    ),
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

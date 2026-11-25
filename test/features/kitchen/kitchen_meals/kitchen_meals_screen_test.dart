import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/kitchen/cooking_status/data/fake_cooking_status_source.dart';
import 'package:carenest_app/features/kitchen/cooking_status/presentation/screens/cooking_status_screen.dart';
import 'package:carenest_app/features/kitchen/food_quantities/data/fake_food_quantity_source.dart';
import 'package:carenest_app/features/kitchen/food_quantities/presentation/screens/food_quantities_screen.dart';
import 'package:carenest_app/features/kitchen/food_samples/data/fake_food_sample_source.dart';
import 'package:carenest_app/features/kitchen/kitchen_home/data/fake_kitchen_home_source.dart';
import 'package:carenest_app/features/kitchen/kitchen_home/domain/kitchen_today.dart';
import 'package:carenest_app/features/kitchen/kitchen_home/presentation/screens/kitchen_home_screen.dart';
import 'package:carenest_app/features/kitchen/kitchen_meals/data/fake_kitchen_meals_source.dart';
import 'package:carenest_app/features/kitchen/kitchen_meals/domain/kitchen_meals.dart';
import 'package:carenest_app/features/kitchen/kitchen_meals/presentation/screens/kitchen_meals_screen.dart';
import 'package:carenest_app/features/kitchen/meal_photos/data/fake_kitchen_photo_source.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/shared/school_menu/presentation/screens/school_menu_screen.dart';

import '../../../helpers/pump_app.dart';

final today = DateTime(2026, 10, 12);

/// Lần tải đầu lỗi, các lần sau trả số suất giả.
class _RetrySource implements KitchenMealsSource {
  final _data = FakeKitchenMealsSource(delay: Duration.zero);
  var _calls = 0;

  @override
  Future<MealCountSheet?> loadSheet() {
    _calls++;
    if (_calls == 1) {
      return Future.error(StateError('Không tải được dữ liệu giả'));
    }
    return _data.loadSheet();
  }
}

/// Trả đúng một Trang chủ dựng sẵn (trạng thái khó có trong dữ liệu giả).
class _TodaySource implements KitchenHomeSource {
  _TodaySource(this.today);

  final KitchenToday today;

  @override
  Future<KitchenToday> loadToday() async => today;
}

FakeKitchenHomeSource homeSource({
  FakeMode mode = FakeMode.data,
  FakeFoodSampleSource? samples,
}) => FakeKitchenHomeSource(
  mode: mode,
  delay: Duration.zero,
  photos: FakeKitchenPhotoSource(delay: Duration.zero),
  samples: samples ?? FakeFoodSampleSource(delay: Duration.zero),
);

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
  testWidgets('K01 (NUT-02): số suất đã chốt từng bữa, giờ PHT xác nhận', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      KitchenHomeScreen(source: homeSource()),
      inScaffold: true,
    );
    expect(find.text('Bếp hôm nay'), findsOneWidget);
    expect(find.text('Thứ Hai, 12/10 · Cơ sở chính'), findsOneWidget);
    expect(find.text('PHT xác nhận 08:30'), findsOneWidget);
    expect(
      labelOf('Bữa phụ sáng'),
      'Bữa phụ sáng, Nhà trẻ, 46 suất, 1 thay thế',
    );
    expect(labelOf('Bữa trưa'), 'Bữa trưa, 182 suất, 7 thay thế');
    expect(labelOf('Bữa chiều'), 'Bữa chiều, 182 suất, 7 thay thế');
    expect(find.text('Xem theo lớp'), findsOneWidget);
  });

  testWidgets('K01 (NUT-16, NUT-21): việc hôm nay từ ảnh mẫu và sổ lưu mẫu', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      KitchenHomeScreen(source: homeSource()),
      inScaffold: true,
    );
    await tester.scrollUntilVisible(find.text('Hủy mẫu'), 200);
    expect(find.text('1/3 bữa có ảnh · bữa trưa cần chụp'), findsOneWidget);
    expect(find.text('Cần chụp'), findsOneWidget);
    expect(
      find.text('Bữa trưa chưa ghi · bữa phụ sáng chờ PHT duyệt'),
      findsOneWidget,
    );
    expect(find.text('Cần ghi'), findsOneWidget);
    expect(find.text('Mẫu bữa trưa 11/10 hủy được từ 10:40'), findsOneWidget);
    expect(find.text('Đến hạn'), findsOneWidget);
    // Màn BE đã bỏ không còn lối vào (NUT-11, NUT-12, NUT-14, NUT-22)
    expect(find.text('Nhận nguyên liệu'), findsNothing);
    expect(find.text('Cập nhật trạng thái nấu'), findsNothing);
    await tester.scrollUntilVisible(find.text('Thực đơn tuần'), 200);
    expect(find.text('Suất ăn theo lớp'), findsOneWidget);
    expect(find.text('Lượng thực phẩm'), findsOneWidget);
  });

  testWidgets('K01: ghi lưu mẫu bữa trưa ⇒ việc Sổ lưu mẫu chuyển chờ duyệt', (
    tester,
  ) async {
    final samples = FakeFoodSampleSource(delay: Duration.zero);
    await tester.runAsync(
      () => samples.saveSample(session: 'LUNCH', dishes: const []),
    );
    await pumpScreen(
      tester,
      KitchenHomeScreen(source: homeSource(samples: samples)),
      inScaffold: true,
    );
    await tester.scrollUntilVisible(find.text('Sổ lưu mẫu'), 200);
    expect(find.text('Bữa phụ sáng và bữa trưa chờ PHT duyệt'), findsOneWidget);
    expect(find.text('Chờ duyệt'), findsOneWidget);
    expect(find.text('Cần ghi'), findsNothing);
  });

  testWidgets('K01 (NUT-02): chưa xác nhận ⇒ chưa có số để nấu', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      KitchenHomeScreen(
        source: _TodaySource(
          KitchenToday(
            date: today,
            campusLabel: 'Cơ sở chính',
            countStatus: KitchenCountStatus.none,
            servings: const [],
            tasks: const [],
          ),
        ),
      ),
      inScaffold: true,
    );
    expect(
      find.textContaining('Chưa có số suất đã chốt hôm nay'),
      findsOneWidget,
    );
    expect(find.text('Xem theo lớp'), findsNothing);
    expect(find.text('PHT xác nhận 08:30'), findsNothing);
  });

  testWidgets('K01: ngày nghỉ ⇒ không có việc bếp', (tester) async {
    await pumpScreen(
      tester,
      KitchenHomeScreen(source: homeSource(mode: FakeMode.empty)),
      inScaffold: true,
    );
    expect(find.text('Hôm nay trường nghỉ'), findsOneWidget);
    expect(find.text('Số suất đã chốt'), findsNothing);
  });

  testWidgets('K01: lỗi tải ⇒ Thử lại, không để khung chờ chạy mãi', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      KitchenHomeScreen(source: homeSource(mode: FakeMode.error)),
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

  testWidgets('K03 / AC-6 (AUTH-05, NUT-02): suất theo lớp từng bữa', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      KitchenMealsScreen(source: FakeKitchenMealsSource(delay: Duration.zero)),
    );
    expect(find.text('PHT xác nhận 08:30 · chỉ xem'), findsOneWidget);
    expect(find.text('Bữa phụ sáng · Nhà trẻ'), findsOneWidget);
    expect(find.bySemanticsLabel('Tổng suất: 46'), findsOneWidget);
    expect(labelOf('Nhà trẻ 1'), 'Nhà trẻ 1, 23 suất thường, 1 suất thay thế');
    expect(find.text('Mầm 3A'), findsNothing);

    await tester.tap(find.text('Trưa'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Tổng suất: 182'), findsOneWidget);
    expect(labelOf('Mầm 3A'), 'Mầm 3A, 24 suất thường, 1 suất thay thế');
    // Không còn banner điều chỉnh chờ duyệt (NUT-03, NUT-04), không tên trẻ (AUTH-05)
    expect(find.textContaining('chờ'), findsNothing);
    expect(find.textContaining('Nguyễn'), findsNothing);
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

  // APP-BUG-261118-setstate-future-retry: closure trả Future vào setState làm "Thử lại" hỏng
  testWidgets('K03: lỗi tải ⇒ "Thử lại" tải lại số suất', (tester) async {
    await pumpScreen(tester, KitchenMealsScreen(source: _RetrySource()));
    expect(find.text('Thử lại'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Tổng suất: 46'), findsOneWidget);
  });

  testWidgets('K04 (NUT-07, NUT-10): lượng cả ngày theo hàng tươi, hàng khô', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      FoodQuantitiesScreen(
        source: FakeFoodQuantitySource(delay: Duration.zero),
      ),
    );
    expect(find.text('Hàng tươi · 8 thực phẩm'), findsOneWidget);
    expect(labelOf('Cá basa phi lê'), 'Cá basa phi lê: 10,5 kg');
    await tester.scrollUntilVisible(find.text('Hàng khô · 3 thực phẩm'), 200);
    expect(labelOf('Gạo tẻ'), 'Gạo tẻ: 19,6 kg');
    // Không còn phiếu xuất kho (NUT-11)
    expect(find.textContaining('Phiếu xuất kho'), findsNothing);
  });

  testWidgets('K04: chưa có lượng ⇒ báo rõ khi nào có', (tester) async {
    await pumpScreen(
      tester,
      FoodQuantitiesScreen(
        source: FakeFoodQuantitySource(
          mode: FakeMode.empty,
          delay: Duration.zero,
        ),
      ),
    );
    expect(find.text('Chưa có lượng thực phẩm'), findsOneWidget);
  });

  // Trạng thái nấu đã bỏ khỏi App bếp (NUT-14 REMOVED); màn còn ở bản debug của Phó HT (V05)
  testWidgets(
    'V05 (debug): trạng thái nấu chuyển bước; chỉ xem thì không có nút',
    (tester) async {
      final source = FakeCookingStatusSource();
      await pumpScreen(tester, CookingStatusScreen(source: source));
      expect(labelOf('Đang nấu'), startsWith('Đang nấu, đang ở bước này'));
      await tester.tap(find.text('Chuyển sang “Đã nấu xong”'));
      await tester.pumpAndSettle();
      expect(
        labelOf('Đã nấu xong'),
        startsWith('Đã nấu xong, đang ở bước này'),
      );

      await pumpScreen(
        tester,
        CookingStatusScreen(source: source, readOnly: true),
      );
      expect(find.textContaining('Chuyển sang'), findsNothing);
    },
  );

  for (final (name, screen, scaffold) in <(String, Widget, bool)>[
    ('Trang chủ bếp', KitchenHomeScreen(source: homeSource()), true),
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
    (
      'Lượng thực phẩm',
      FoodQuantitiesScreen(
        source: FakeFoodQuantitySource(delay: Duration.zero),
      ),
      false,
    ),
  ]) {
    testWidgets('AC-10: $name chữ 2.0 không tràn', (tester) async {
      await pumpScreen(tester, screen, textScale: 2, inScaffold: scaffold);
      expect(tester.takeException(), isNull);
    });
  }
}

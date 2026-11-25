import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/parent/parent_menu/domain/weekly_menu.dart';
import 'package:carenest_app/features/parent/parent_menu/presentation/screens/weekly_menu_screen.dart';

import '../../../helpers/pump_app.dart';

final _monday = DateTime(2026, 10, 12);

/// Một ngày với đúng các bữa test cần (ảnh theo bữa chưa có API — đề xuất A, user 17/11).
class _OneDaySource implements WeeklyMenuSource {
  const _OneDaySource(this.meals);

  final List<MenuMeal> meals;

  @override
  Future<WeeklyMenu> loadWeek(String childId) async => WeeklyMenu(
    weekStart: _monday,
    days: [MenuDay(date: _monday, meals: meals)],
  );
}

MealPhotos _posted(int count, {int hour = 7, int minute = 50}) =>
    MealPhotos.posted(
      ageGroup: 'Mầm',
      postedAt: DateTime(2026, 10, 12, hour, minute),
      photoIds: [for (var i = 1; i <= count; i++) 'p$i'],
    );

Future<void> pumpMenu(WidgetTester tester, List<MenuMeal> meals) async {
  usePhoneSize(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: WeeklyMenuScreen(
        childId: 'child-1',
        initialDay: _monday,
        source: _OneDaySource(meals),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Nhóm Lá ăn 2 bữa ⇒ bé lớp Lá không có bữa sáng, khớp màn bếp', (
    tester,
  ) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: WeeklyMenuScreen(childId: 'child-2', initialDay: _monday),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Bữa sáng'), findsNothing);
    expect(find.textContaining('Bữa trưa'), findsWidgets);
    // Bếp chưa đăng ảnh bữa trưa cho nhóm Lá (dữ liệu giả màn Ảnh mẫu bữa ăn)
    expect(find.text('Bếp chưa đăng ảnh bữa trưa'), findsOneWidget);
    expect(find.textContaining('Ảnh mẫu nhóm'), findsNothing);
  });

  testWidgets('Đề xuất A: mỗi bữa có ô ảnh theo đúng số ảnh của bữa đó', (
    tester,
  ) async {
    await pumpMenu(tester, [
      MenuMeal(
        name: 'Bữa sáng',
        time: '07:45',
        dishes: 'Cháo thịt bằm · Sữa tươi',
        photos: _posted(3),
      ),
      MenuMeal(
        name: 'Bữa trưa',
        time: '10:45',
        dishes: 'Cơm trắng · Canh bí đỏ nấu thịt',
        photos: _posted(2, hour: 10, minute: 52),
      ),
    ]);
    for (final label in [
      'Xem ảnh 1 trong 3 của bữa sáng',
      'Xem ảnh 2 trong 3 của bữa sáng',
      'Xem ảnh 3 trong 3 của bữa sáng',
      'Xem ảnh 1 trong 2 của bữa trưa',
      'Xem ảnh 2 trong 2 của bữa trưa',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    expect(
      find.bySemanticsLabel('Xem ảnh 3 trong 2 của bữa trưa'),
      findsNothing,
    );
    expect(find.text('Ảnh mẫu nhóm Mầm · Bếp đăng 07:50'), findsOneWidget);
    expect(find.text('Ảnh mẫu nhóm Mầm · Bếp đăng 10:52'), findsOneWidget);
    // Không còn thẻ "Ảnh bữa ăn" chung ở cuối ngày
    expect(find.textContaining('Ảnh bữa ăn'), findsNothing);
  });

  testWidgets('Đề xuất A: bữa một ảnh là một ô, nhãn không đánh số', (
    tester,
  ) async {
    await pumpMenu(tester, [
      MenuMeal(
        name: 'Bữa chiều',
        time: '14:30',
        dishes: 'Bánh flan · Nước cam',
        photos: _posted(1, hour: 14, minute: 41),
      ),
    ]);
    expect(find.bySemanticsLabel('Xem ảnh bữa chiều'), findsOneWidget);
    expect(find.text('Ảnh mẫu nhóm Mầm · Bếp đăng 14:41'), findsOneWidget);
  });

  testWidgets('Đề xuất A: qua giờ ăn mà bếp chưa đăng ⇒ báo chưa có ảnh', (
    tester,
  ) async {
    await pumpMenu(tester, [
      const MenuMeal(
        name: 'Bữa trưa',
        time: '10:45',
        dishes: 'Cơm trắng · Canh rau ngót',
        photos: MealPhotos.missing(),
      ),
    ]);
    expect(find.text('Bếp chưa đăng ảnh bữa trưa'), findsOneWidget);
    expect(find.textContaining('Ảnh mẫu nhóm'), findsNothing);
  });

  testWidgets('Đề xuất A: chưa tới giờ ăn ⇒ chỉ ghi lúc nào có ảnh', (
    tester,
  ) async {
    await pumpMenu(tester, [
      const MenuMeal(
        name: 'Bữa chiều',
        time: '14:30',
        dishes: 'Chè đậu xanh',
        photos: MealPhotos.upcoming(),
      ),
    ]);
    expect(find.text('Có ảnh sau 14:30'), findsOneWidget);
    expect(find.bySemanticsLabel('Xem ảnh bữa chiều'), findsNothing);
    expect(find.textContaining('Bếp chưa đăng'), findsNothing);
  });

  testWidgets('Đề xuất A: từ 4 ảnh thì ô thứ ba ghi số ảnh còn lại', (
    tester,
  ) async {
    await pumpMenu(tester, [
      MenuMeal(
        name: 'Bữa sáng',
        time: '07:45',
        dishes: 'Cháo thịt bằm · Sữa tươi',
        photos: _posted(5),
      ),
    ]);
    expect(find.text('+3'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Xem ảnh 1 trong 5 của bữa sáng'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Xem ảnh 2 trong 5 của bữa sáng'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Xem ảnh 3 trong 5 của bữa sáng'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Xem ảnh 4 trong 5 của bữa sáng'),
      findsNothing,
    );
  });

  final breakfast = MenuMeal(
    name: 'Bữa sáng',
    time: '07:45',
    dishes: 'Cháo thịt bằm · Sữa tươi',
    photos: _posted(3),
  );

  testWidgets('Xem ảnh: chạm ô thứ hai mở toàn màn đúng ảnh đó', (
    tester,
  ) async {
    await pumpMenu(tester, [breakfast]);
    await tester.tap(find.bySemanticsLabel('Xem ảnh 2 trong 3 của bữa sáng'));
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    expect(find.text('Bữa sáng'), findsOneWidget);
    expect(
      find.text('Thứ Hai, 12/10 · Cháo thịt bằm · Sữa tươi'),
      findsOneWidget,
    );
    expect(find.text('Ảnh mẫu nhóm Mầm · Bếp đăng lúc 07:50'), findsOneWidget);
  });

  testWidgets('Xem ảnh: nút Ảnh sau, Ảnh trước và vuốt đổi ảnh trong bữa', (
    tester,
  ) async {
    await pumpMenu(tester, [breakfast]);
    await tester.tap(find.bySemanticsLabel('Xem ảnh 2 trong 3 của bữa sáng'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ảnh sau'));
    await tester.pumpAndSettle();
    expect(find.text('3/3'), findsOneWidget);
    // Ảnh cuối: không qua tiếp được
    await tester.tap(find.byTooltip('Ảnh sau'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('3/3'), findsOneWidget);
    await tester.tap(find.byTooltip('Ảnh trước'));
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('3/3'), findsOneWidget);
  });

  testWidgets('AC-10: thẻ bữa có ảnh và màn xem ảnh chữ 2.0 không tràn', (
    tester,
  ) async {
    usePhoneSize(tester, textScale: 2);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: WeeklyMenuScreen(
          childId: 'child-1',
          initialDay: _monday,
          source: _OneDaySource([breakfast]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.bySemanticsLabel('Xem ảnh 1 trong 3 của bữa sáng'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Xem ảnh: nút Đóng về lại thực đơn', (tester) async {
    await pumpMenu(tester, [breakfast]);
    await tester.tap(find.bySemanticsLabel('Xem ảnh 1 trong 3 của bữa sáng'));
    await tester.pumpAndSettle();
    expect(find.text('1/3'), findsOneWidget);
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(find.text('1/3'), findsNothing);
    expect(find.text('Thực đơn tuần'), findsOneWidget);
  });
}

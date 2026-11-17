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
      'Ảnh 1 trong 3 của bữa sáng',
      'Ảnh 2 trong 3 của bữa sáng',
      'Ảnh 3 trong 3 của bữa sáng',
      'Ảnh 1 trong 2 của bữa trưa',
      'Ảnh 2 trong 2 của bữa trưa',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    expect(find.bySemanticsLabel('Ảnh 3 trong 2 của bữa trưa'), findsNothing);
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
    expect(find.bySemanticsLabel('Ảnh bữa chiều'), findsOneWidget);
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
    expect(find.bySemanticsLabel('Ảnh bữa chiều'), findsNothing);
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
    expect(find.bySemanticsLabel('Ảnh 1 trong 5 của bữa sáng'), findsOneWidget);
    expect(find.bySemanticsLabel('Ảnh 2 trong 5 của bữa sáng'), findsOneWidget);
    expect(find.bySemanticsLabel('Ảnh 3 trong 5 của bữa sáng'), findsOneWidget);
    expect(find.bySemanticsLabel('Ảnh 4 trong 5 của bữa sáng'), findsNothing);
  });
}

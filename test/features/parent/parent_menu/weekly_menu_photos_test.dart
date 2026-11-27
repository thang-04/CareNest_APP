import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/parent/parent_menu/domain/weekly_menu.dart';
import 'package:carenest_app/features/parent/parent_menu/presentation/screens/weekly_menu_screen.dart';

import '../../../helpers/pump_app.dart';

final _monday = DateTime(2026, 11, 23);

/// Nguồn giả một tuần, ghi lại tuần đã yêu cầu.
class _Source implements WeeklyMenuSource {
  _Source(this.week);

  WeeklyMenu week;
  final requested = <DateTime?>[];

  @override
  Future<WeeklyMenu> loadWeek(String childId, {DateTime? weekStart}) async {
    requested.add(weekStart);
    return week;
  }

  @override
  Future<Uint8List?> loadPhoto(String childId, String photoId) async => null;
}

WeeklyMenu _week({
  List<MenuMealEntry> meals = const [],
  bool published = true,
  bool mealsHidden = false,
  bool dayOff = false,
  bool enrolled = true,
  List<String> unmatched = const [],
}) => WeeklyMenu(
  weekStart: _monday,
  published: published,
  mealsHidden: mealsHidden,
  unmatchedAllergies: unmatched,
  days: [
    MenuDay(date: _monday, meals: meals, dayOff: dayOff, enrolled: enrolled),
  ],
);

final _lunch = MenuMealEntry(
  session: MenuSession.lunch,
  dishes: const [
    MenuDish(name: 'Cơm tẻ'),
    MenuDish(
      name: 'Cá sốt cà chua',
      allergens: ['Cá', 'Đậu nành'],
      childAllergens: ['Cá'],
    ),
    MenuDish(name: 'Canh rau', allergens: ['Đậu nành']),
  ],
  photo: MenuPhoto(photoId: '10', uploadedAt: DateTime(2026, 11, 23, 11, 5)),
);

const _snack = MenuMealEntry(
  session: MenuSession.afternoon,
  dishes: [MenuDish(name: 'Sữa chua')],
);

Future<_Source> _pumpMenu(WidgetTester tester, WeeklyMenu week) async {
  final source = _Source(week);
  usePhoneSize(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: WeeklyMenuScreen(childId: '5', initialDay: _monday, source: source),
    ),
  );
  await tester.pumpAndSettle();
  return source;
}

void main() {
  testWidgets('món theo bữa; món có chất bé dị ứng có cảnh báo chữ', (
    tester,
  ) async {
    await _pumpMenu(tester, _week(meals: [_lunch, _snack]));
    expect(find.text('Bữa trưa'), findsOneWidget);
    expect(find.text('Bữa chiều'), findsOneWidget);
    expect(find.text('Cá sốt cà chua'), findsOneWidget);
    expect(find.text('Có Cá — bé đã khai dị ứng'), findsOneWidget);
    // Món có chất nhưng bé không dị ứng: chỉ ghi chất, không cảnh báo
    expect(find.text('Có Đậu nành'), findsOneWidget);
  });

  testWidgets('bữa có ảnh hiện giờ bếp đăng; bữa chưa có ảnh ghi rõ', (
    tester,
  ) async {
    await _pumpMenu(tester, _week(meals: [_lunch, _snack]));
    expect(find.text('Bếp đăng 11:05'), findsOneWidget);
    expect(find.text('Chưa có ảnh bữa ăn'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Xem ảnh bữa trưa'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Đóng'), findsOneWidget);
    expect(find.text('Bếp đăng lúc 11:05'), findsOneWidget);
  });

  testWidgets('dị ứng chưa khớp danh mục ⇒ banner cảnh báo', (tester) async {
    await _pumpMenu(tester, _week(meals: [_snack], unmatched: ['Dâu tây']));
    expect(
      find.textContaining('Dị ứng đã khai chưa khớp danh mục chất: Dâu tây'),
      findsOneWidget,
    );
  });

  testWidgets('ngày trống hiện lý do theo cờ BE', (tester) async {
    await _pumpMenu(tester, _week(published: false));
    expect(find.text('Thực đơn tuần này chưa công bố'), findsOneWidget);
  });

  testWidgets('bé không báo ăn ⇒ không hiện món', (tester) async {
    await _pumpMenu(tester, _week(mealsHidden: true));
    expect(find.text('Bé không báo ăn ở trường'), findsOneWidget);
  });

  testWidgets('ngày nghỉ có lý do riêng', (tester) async {
    await _pumpMenu(tester, _week(dayOff: true));
    expect(find.text('Ngày nghỉ'), findsOneWidget);
  });

  testWidgets('bé chưa học ngày này có lý do riêng', (tester) async {
    await _pumpMenu(tester, _week(enrolled: false));
    expect(find.text('Bé chưa học ngày này'), findsOneWidget);
  });

  testWidgets('Tuần sau ⇒ tải tuần kế tiếp theo weekStart', (tester) async {
    final source = await _pumpMenu(tester, _week(meals: [_snack]));
    await tester.tap(find.byTooltip('Tuần sau'));
    await tester.pumpAndSettle();
    expect(source.requested, [null, DateTime(2026, 11, 30)]);
  });
}

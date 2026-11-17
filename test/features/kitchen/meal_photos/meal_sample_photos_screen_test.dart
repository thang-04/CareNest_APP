import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/kitchen/meal_photos/data/fake_kitchen_photo_source.dart';
import 'package:carenest_app/features/kitchen/meal_photos/presentation/screens/meal_sample_photos_screen.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

import '../../../helpers/pump_app.dart';

Future<void> pumpPhotos(WidgetTester tester, {double textScale = 1}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: MealSamplePhotosScreen(
        source: FakeKitchenPhotoSource(delay: Duration.zero),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Thẻ của một bữa trong nhóm đang chọn.
Finder mealCard(String title) => find.ancestor(
  of: find.text(title),
  matching: find.byKey(ValueKey('meal-card-$title')),
);

void main() {
  testWidgets('Ảnh mẫu: mỗi nhóm tuổi chỉ có các bữa được cấu hình cho nhóm', (
    tester,
  ) async {
    await pumpPhotos(tester);
    expect(find.text('Nhà trẻ 2/3'), findsOneWidget);
    expect(find.text('Lá 0/2'), findsOneWidget);
    expect(find.text('Bữa sáng · 07:45'), findsOneWidget);

    await tester.tap(find.text('Lá 0/2'));
    await tester.pumpAndSettle();
    expect(find.text('Bữa trưa · 10:45'), findsOneWidget);
    expect(find.text('Bữa chiều · 14:30'), findsOneWidget);
    expect(find.text('Bữa sáng · 07:45'), findsNothing);
    expect(
      find.text(
        'Nhóm Lá (5–6 tuổi) ăn 2 bữa mỗi ngày. Mỗi bữa cần ít nhất 1 ảnh, chụp bao nhiêu cũng được.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Ảnh mẫu: lỗi tải ⇒ báo lỗi có Thử lại', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: MealSamplePhotosScreen(
          source: FakeKitchenPhotoSource(
            mode: FakeMode.error,
            delay: Duration.zero,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa tải được ảnh mẫu'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('AC-10: Ảnh mẫu chữ 2.0 không tràn', (tester) async {
    await pumpPhotos(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Chồi 0/3'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ảnh mẫu: trạng thái từng bữa theo khung giờ và số ảnh', (
    tester,
  ) async {
    await pumpPhotos(tester);
    await tester.tap(find.text('Chồi 0/3'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: mealCard('Bữa sáng · 07:45'),
        matching: find.text('Quá giờ, chưa có ảnh'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: mealCard('Bữa trưa · 10:45'),
        matching: find.text('Cần chụp'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: mealCard('Bữa trưa · 10:45'),
        matching: find.text('Đăng được 10:30–11:30'),
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Bữa chiều · 14:30'), 200);
    expect(
      find.descendant(
        of: mealCard('Bữa chiều · 14:30'),
        matching: find.text('Chưa tới giờ'),
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(find.text('Mầm 2/3'), -200);
    await tester.tap(find.text('Mầm 2/3'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: mealCard('Bữa sáng · 07:45'),
        matching: find.text('Đã có 3 ảnh'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: mealCard('Bữa sáng · 07:45'),
        matching: find.text('Hết giờ đăng (07:30–08:30)'),
      ),
      findsOneWidget,
    );
  });
}

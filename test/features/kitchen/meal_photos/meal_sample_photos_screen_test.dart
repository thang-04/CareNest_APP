import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/kitchen/meal_photos/data/fake_kitchen_photo_source.dart';
import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';
import 'package:carenest_app/features/kitchen/meal_photos/presentation/screens/meal_sample_photos_screen.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

import '../../../helpers/pump_app.dart';

Future<void> pumpPhotos(
  WidgetTester tester, {
  double textScale = 1,
  KitchenPhotoSource? source,
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: MealSamplePhotosScreen(
        source: source ?? FakeKitchenPhotoSource(delay: Duration.zero),
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

Finder inCard(String meal, String text) =>
    find.descendant(of: mealCard(meal), matching: find.text(text));

/// Mở nhóm Chồi rồi bấm nút chụp của bữa trưa (đang mở giờ, chưa có ảnh).
Future<void> tapLunchCamera(WidgetTester tester) async {
  await tester.tap(find.text('Chồi 0/3'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(inCard('Bữa trưa · 10:45', 'Chụp ảnh'));
  await tester.tap(inCard('Bữa trưa · 10:45', 'Chụp ảnh'));
}

/// Tải được nhưng đăng ảnh lỗi.
class _UploadFailsSource extends FakeKitchenPhotoSource {
  _UploadFailsSource() : super(delay: Duration.zero);

  @override
  Future<KitchenPhotoDay> addPhoto({
    required String groupId,
    required String mealId,
  }) async => throw StateError('mất mạng');
}

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

  testWidgets(
    'Ảnh mẫu: chỉ bữa đang mở giờ mới chụp được, bao nhiêu ảnh cũng được',
    (tester) async {
      await pumpPhotos(tester);
      await tapLunchCamera(tester);
      await tester.pumpAndSettle();
      expect(inCard('Bữa sáng · 07:45', 'Chụp ảnh'), findsNothing);
      expect(inCard('Bữa trưa · 10:45', 'Đã có 1 ảnh'), findsOneWidget);
      expect(find.text('Chồi 1/3'), findsOneWidget);

      await tester.ensureVisible(inCard('Bữa trưa · 10:45', 'Chụp thêm ảnh'));
      await tester.tap(inCard('Bữa trưa · 10:45', 'Chụp thêm ảnh'));
      await tester.pumpAndSettle();
      expect(inCard('Bữa trưa · 10:45', 'Đã có 2 ảnh'), findsOneWidget);
      expect(find.text('Chồi 1/3'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Bữa chiều · 14:30'), 200);
      expect(inCard('Bữa chiều · 14:30', 'Chụp ảnh'), findsNothing);
    },
  );

  testWidgets('Ảnh mẫu: đang đăng thì nút chờ, bấm lại không đăng trùng', (
    tester,
  ) async {
    await pumpPhotos(tester, source: FakeKitchenPhotoSource());
    await tapLunchCamera(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(inCard('Bữa trưa · 10:45', 'Đang đăng ảnh…'), findsOneWidget);
    await tester.tap(inCard('Bữa trưa · 10:45', 'Đang đăng ảnh…'));
    await tester.pumpAndSettle();
    expect(inCard('Bữa trưa · 10:45', 'Đã có 1 ảnh'), findsOneWidget);
  });

  testWidgets('Ảnh mẫu: đăng lỗi ⇒ báo, bữa vẫn cần chụp', (tester) async {
    await pumpPhotos(tester, source: _UploadFailsSource());
    await tapLunchCamera(tester);
    await tester.pumpAndSettle();
    expect(
      inCard('Bữa trưa · 10:45', 'Chưa đăng được ảnh. Thử lại.'),
      findsOneWidget,
    );
    expect(inCard('Bữa trưa · 10:45', 'Cần chụp'), findsOneWidget);
    expect(inCard('Bữa trưa · 10:45', 'Chụp ảnh'), findsOneWidget);
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

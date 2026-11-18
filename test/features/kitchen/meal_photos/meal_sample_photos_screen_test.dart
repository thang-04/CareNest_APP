import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/kitchen/kitchen_day/domain/kitchen_day.dart';
import 'package:carenest_app/features/kitchen/meal_photos/data/fake_kitchen_photo_source.dart';
import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';
import 'package:carenest_app/features/kitchen/meal_photos/presentation/screens/meal_sample_photos_screen.dart';

import '../../../helpers/pump_app.dart';

/// PNG 1×1 trong suốt: ảnh "vừa chụp" giải mã được trong test.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// Camera giả: trả ảnh PNG, hoặc null khi bếp huỷ, hoặc ném lỗi.
class _FakeCamera implements SamplePhotoCamera {
  _FakeCamera({this.cancels = false, this.error});

  final bool cancels;
  final Object? error;
  var calls = 0;

  @override
  Future<Uint8List?> takePhoto() async {
    calls++;
    if (error case final error?) throw error;
    return cancels ? null : _png;
  }
}

/// Ghi lại mọi lần đăng; [failures] lần đầu lỗi mạng.
class _RecordingSource extends FakeKitchenPhotoSource {
  _RecordingSource({this.failures = 0}) : super(delay: Duration.zero);

  int failures;
  final posted = <(MealSession, Uint8List)>[];

  @override
  Future<KitchenPhotoDay> upload({
    required MealSession session,
    required Uint8List bytes,
  }) async {
    posted.add((session, bytes));
    if (failures > 0) {
      failures--;
      throw StateError('mất mạng');
    }
    return super.upload(session: session, bytes: bytes);
  }
}

Future<void> pumpPhotos(
  WidgetTester tester, {
  double textScale = 1,
  KitchenPhotoSource? source,
  SamplePhotoCamera? camera,
}) async {
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: MealSamplePhotosScreen(
        source: source ?? FakeKitchenPhotoSource(delay: Duration.zero),
        camera: camera ?? _FakeCamera(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder mealCard(MealSession session) =>
    find.byKey(ValueKey('meal-card-${session.code}'));

Finder inCard(MealSession session, String text) =>
    find.descendant(of: mealCard(session), matching: find.text(text));

Future<void> tapLunch(WidgetTester tester, String label) async {
  await tester.ensureVisible(inCard(MealSession.lunch, label));
  await tester.pumpAndSettle();
  await tester.tap(inCard(MealSession.lunch, label));
}

/// Lần tải đầu lỗi, các lần sau có dữ liệu.
class _FailOnceSource extends FakeKitchenPhotoSource {
  _FailOnceSource() : super(delay: Duration.zero);

  var _failed = false;

  @override
  Future<KitchenPhotoDay> loadToday() async {
    if (!_failed) {
      _failed = true;
      throw StateError('mất mạng');
    }
    return super.loadToday();
  }
}

void main() {
  testWidgets('Ảnh mẫu: mỗi bữa một thẻ, trạng thái theo khung giờ', (
    tester,
  ) async {
    await pumpPhotos(tester);
    expect(inCard(MealSession.morning, 'Đã có ảnh'), findsOneWidget);
    expect(
      inCard(MealSession.morning, 'Đăng 07:50 · Hết giờ đăng (07:30–08:30)'),
      findsOneWidget,
    );
    expect(inCard(MealSession.lunch, 'Cần chụp'), findsOneWidget);
    expect(inCard(MealSession.lunch, 'Giờ đăng 10:30–11:30'), findsOneWidget);
    expect(inCard(MealSession.morning, 'Chụp ảnh'), findsNothing);
    await tester.scrollUntilVisible(mealCard(MealSession.afternoon), 200);
    expect(inCard(MealSession.afternoon, 'Chưa tới giờ'), findsOneWidget);
    expect(inCard(MealSession.afternoon, 'Chụp ảnh'), findsNothing);
  });

  testWidgets('Ảnh mẫu: chụp đăng đúng bữa, hiện ảnh, chụp lại thay ảnh', (
    tester,
  ) async {
    final camera = _FakeCamera();
    final source = _RecordingSource();
    await pumpPhotos(tester, source: source, camera: camera);
    await tapLunch(tester, 'Chụp ảnh');
    await tester.pumpAndSettle();
    expect(source.posted.single, (MealSession.lunch, _png));
    expect(inCard(MealSession.lunch, 'Đã có ảnh'), findsOneWidget);
    expect(
      find.descendant(
        of: mealCard(MealSession.lunch),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );

    await tapLunch(tester, 'Chụp lại');
    await tester.pumpAndSettle();
    expect(source.posted, hasLength(2));
    // Một bữa chỉ một ảnh (BE thay file)
    expect(
      find.descendant(
        of: mealCard(MealSession.lunch),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Ảnh mẫu: không mở được camera ⇒ báo, nút bấm lại được', (
    tester,
  ) async {
    final source = _RecordingSource();
    await pumpPhotos(
      tester,
      source: source,
      camera: _FakeCamera(
        error: PlatformException(code: 'camera_access_denied'),
      ),
    );
    await tapLunch(tester, 'Chụp ảnh');
    await tester.pumpAndSettle();
    expect(source.posted, isEmpty);
    expect(
      inCard(
        MealSession.lunch,
        'Không mở được camera. Kiểm tra quyền camera rồi thử lại.',
      ),
      findsOneWidget,
    );
    expect(inCard(MealSession.lunch, 'Chụp ảnh'), findsOneWidget);
  });

  testWidgets('Ảnh mẫu: huỷ camera ⇒ không đăng, không báo lỗi', (
    tester,
  ) async {
    final source = _RecordingSource();
    await pumpPhotos(
      tester,
      source: source,
      camera: _FakeCamera(cancels: true),
    );
    await tapLunch(tester, 'Chụp ảnh');
    await tester.pumpAndSettle();
    expect(source.posted, isEmpty);
    expect(inCard(MealSession.lunch, 'Cần chụp'), findsOneWidget);
  });

  testWidgets('Ảnh mẫu: đang đăng thì nút chờ, bấm lại không đăng trùng', (
    tester,
  ) async {
    await pumpPhotos(tester, source: FakeKitchenPhotoSource());
    await tapLunch(tester, 'Chụp ảnh');
    await tester.pump(const Duration(milliseconds: 100));
    expect(inCard(MealSession.lunch, 'Đang đăng ảnh…'), findsOneWidget);
    await tester.tap(inCard(MealSession.lunch, 'Đang đăng ảnh…'));
    await tester.pumpAndSettle();
    expect(inCard(MealSession.lunch, 'Đã có ảnh'), findsOneWidget);
  });

  testWidgets(
    'Ảnh mẫu: đăng lỗi ⇒ giữ ảnh vừa chụp, Đăng lại gửi đúng ảnh đó',
    (tester) async {
      final camera = _FakeCamera();
      final source = _RecordingSource(failures: 1);
      await pumpPhotos(tester, source: source, camera: camera);
      await tapLunch(tester, 'Chụp ảnh');
      await tester.pumpAndSettle();
      expect(
        inCard(
          MealSession.lunch,
          'Chưa đăng được ảnh vừa chụp. Kiểm tra mạng rồi đăng lại.',
        ),
        findsOneWidget,
      );
      await tapLunch(tester, 'Đăng lại ảnh');
      await tester.pumpAndSettle();
      expect(camera.calls, 1);
      expect(source.posted, hasLength(2));
      expect(inCard(MealSession.lunch, 'Đã có ảnh'), findsOneWidget);
      expect(inCard(MealSession.lunch, 'Đăng lại ảnh'), findsNothing);
    },
  );

  testWidgets('Ảnh mẫu: tải lỗi rồi Thử lại ⇒ hiện các bữa', (tester) async {
    await pumpPhotos(tester, source: _FailOnceSource());
    expect(find.text('Chưa tải được ảnh mẫu'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(mealCard(MealSession.lunch), findsOneWidget);
  });

  testWidgets('AC-10: Ảnh mẫu chữ 2.0 không tràn', (tester) async {
    await pumpPhotos(tester, textScale: 2);
    expect(tester.takeException(), isNull);
  });
}

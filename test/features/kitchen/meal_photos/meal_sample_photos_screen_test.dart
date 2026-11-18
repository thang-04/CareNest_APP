import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/kitchen/meal_photos/data/fake_kitchen_photo_source.dart';
import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';
import 'package:carenest_app/features/kitchen/meal_photos/presentation/screens/meal_sample_photos_screen.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

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
  _RecordingSource({this.failures = 0, super.delay = Duration.zero});

  int failures;
  final posted = <Uint8List>[];

  @override
  Future<KitchenPhotoDay> addPhoto({
    required String groupId,
    required String mealId,
    required Uint8List bytes,
  }) async {
    posted.add(bytes);
    if (failures > 0) {
      failures--;
      throw StateError('mất mạng');
    }
    return super.addPhoto(groupId: groupId, mealId: mealId, bytes: bytes);
  }
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

/// Trả đúng một ngày dựng sẵn (trạng thái khó có trong dữ liệu giả).
class _DaySource implements KitchenPhotoSource {
  _DaySource(this.day);

  final KitchenPhotoDay day;

  @override
  Future<KitchenPhotoDay> loadToday() async => day;

  @override
  Future<KitchenPhotoDay> addPhoto({
    required String groupId,
    required String mealId,
    required Uint8List bytes,
  }) async => day;
}

KitchenPhotoDay _oneGroupDay(List<SampleMeal> meals) => KitchenPhotoDay(
  date: FakeParentHomeSource.today,
  campusLabel: 'Cơ sở chính',
  groups: [
    AgeGroupMeals(
      id: 'mg-lon',
      name: 'Mẫu giáo lớn',
      ageRange: '5–6 tuổi',
      meals: meals,
    ),
  ],
);

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

/// Thẻ của một bữa trong nhóm đang chọn.
Finder mealCard(String meal) => find.byKey(ValueKey('meal-card-$meal'));

Finder inCard(String meal, String text) =>
    find.descendant(of: mealCard(meal), matching: find.text(text));

Finder groupTile(String id) => find.byKey(ValueKey('group-tile-$id'));

Finder inTile(String id, String text) =>
    find.descendant(of: groupTile(id), matching: find.text(text));

Future<void> openGroup(WidgetTester tester, String id) async {
  await tester.ensureVisible(groupTile(id));
  await tester.pumpAndSettle();
  await tester.tap(groupTile(id));
  await tester.pumpAndSettle();
}

/// Bấm vùng chụp của bữa trưa nhóm đang mở (Mẫu giáo nhỡ: đang trong giờ, chưa có ảnh).
Future<void> tapLunchCapture(WidgetTester tester) async {
  final zone = inCard('Bữa trưa', 'Chụp ảnh mẫu bữa trưa');
  // Chữ lớn đẩy thẻ bữa ra ngoài vùng ListView đã dựng ⇒ cuộn tới khi thấy
  await tester.scrollUntilVisible(zone, 200);
  await tester.pumpAndSettle();
  await tester.tap(zone);
}

void main() {
  testWidgets('Ảnh mẫu: mở nhóm còn bữa cần chụp, tiến độ cả ngày', (
    tester,
  ) async {
    await pumpPhotos(tester);
    expect(find.text('Cơ sở chính'), findsOneWidget);
    expect(find.text('3/9 phần đã có ảnh mẫu'), findsOneWidget);
    expect(inTile('nha-tre', '2/3'), findsOneWidget);
    expect(inTile('mg-be', '1/2'), findsOneWidget);
    expect(inTile('mg-nho', '0/2'), findsOneWidget);
    expect(inTile('mg-lon', '0/2'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Mẫu giáo nhỡ, 4 đến 5 tuổi, 0 trên 2 bữa có ảnh'),
      findsOneWidget,
    );
    expect(inCard('Bữa trưa', 'Cần chụp'), findsOneWidget);
    expect(
      inCard('Bữa trưa', 'Đăng được 10:30–11:30 · còn 40 phút'),
      findsOneWidget,
    );
    expect(
      inCard('Bữa trưa', 'Ảnh đăng cho nhóm Mẫu giáo nhỡ'),
      findsOneWidget,
    );
  });

  testWidgets('Ảnh mẫu: mỗi nhóm tuổi chỉ có các bữa theo cấu hình', (
    tester,
  ) async {
    await pumpPhotos(tester);
    expect(find.text('4–5 tuổi · ăn bữa trưa và bữa chiều'), findsOneWidget);
    expect(mealCard('Bữa phụ sáng'), findsNothing);

    await openGroup(tester, 'nha-tre');
    expect(
      find.text('24–36 tháng · ăn bữa phụ sáng, bữa trưa và bữa chiều'),
      findsOneWidget,
    );
    expect(mealCard('Bữa phụ sáng'), findsOneWidget);
    expect(mealCard('Bữa trưa'), findsOneWidget);
    await tester.scrollUntilVisible(mealCard('Bữa chiều'), 200);
    expect(mealCard('Bữa chiều'), findsOneWidget);
  });

  testWidgets('Ảnh mẫu: bấm vùng chụp mở camera, đăng đúng ảnh vừa chụp', (
    tester,
  ) async {
    final camera = _FakeCamera();
    final source = _RecordingSource();
    await pumpPhotos(tester, source: source, camera: camera);
    await tapLunchCapture(tester);
    await tester.pumpAndSettle();
    expect(camera.calls, 1);
    expect(source.posted, [_png]);
    expect(inCard('Bữa trưa', 'Có 1 ảnh'), findsOneWidget);
    expect(inCard('Bữa trưa', '10:50'), findsOneWidget);
    expect(inTile('mg-nho', '1/2'), findsOneWidget);
    // Vẫn ở nhóm vừa chụp, không nhảy sang Mẫu giáo lớn
    expect(find.text('4–5 tuổi · ăn bữa trưa và bữa chiều'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('4/9 phần đã có ảnh mẫu'), -200);
    expect(find.text('4/9 phần đã có ảnh mẫu'), findsOneWidget);
  });

  testWidgets('Ảnh mẫu: ảnh vừa chụp hiện ngay, ảnh có sẵn là ô giữ chỗ', (
    tester,
  ) async {
    await pumpPhotos(tester);
    await tapLunchCapture(tester);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: mealCard('Bữa trưa'), matching: find.byType(Image)),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(groupTile('nha-tre'), -200);
    await openGroup(tester, 'nha-tre');
    expect(inCard('Bữa phụ sáng', '07:52'), findsOneWidget);
    expect(
      find.descendant(
        of: mealCard('Bữa phụ sáng'),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
  });

  testWidgets('Ảnh mẫu: không mở được camera ⇒ báo, vùng chụp bấm lại được', (
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
    await tapLunchCapture(tester);
    await tester.pumpAndSettle();
    expect(source.posted, isEmpty);
    expect(
      inCard(
        'Bữa trưa',
        'Không mở được camera. Kiểm tra quyền camera rồi thử lại.',
      ),
      findsOneWidget,
    );
    expect(inCard('Bữa trưa', 'Chụp ảnh mẫu bữa trưa'), findsOneWidget);
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
    await tapLunchCapture(tester);
    await tester.pumpAndSettle();
    expect(source.posted, isEmpty);
    expect(inCard('Bữa trưa', 'Cần chụp'), findsOneWidget);
    expect(inCard('Bữa trưa', 'Chụp ảnh mẫu bữa trưa'), findsOneWidget);
  });

  testWidgets('Ảnh mẫu: có ảnh rồi vẫn Chụp thêm được trong giờ', (
    tester,
  ) async {
    await pumpPhotos(tester);
    await tapLunchCapture(tester);
    await tester.pumpAndSettle();
    expect(inCard('Bữa trưa', 'Chụp ảnh mẫu bữa trưa'), findsNothing);

    await tester.ensureVisible(inCard('Bữa trưa', 'Chụp thêm'));
    await tester.pumpAndSettle();
    await tester.tap(inCard('Bữa trưa', 'Chụp thêm'));
    await tester.pumpAndSettle();
    expect(inCard('Bữa trưa', 'Có 2 ảnh'), findsOneWidget);
    expect(inTile('mg-nho', '1/2'), findsOneWidget);
  });

  testWidgets('Ảnh mẫu: chỉ bữa đang trong giờ mới chụp được', (tester) async {
    await pumpPhotos(tester);
    await tester.scrollUntilVisible(mealCard('Bữa chiều'), 200);
    expect(inCard('Bữa chiều', 'Chưa tới giờ'), findsOneWidget);
    expect(inCard('Bữa chiều', 'Nút chụp mở lúc 14:30'), findsOneWidget);
    expect(inCard('Bữa chiều', 'Chụp ảnh mẫu bữa chiều'), findsNothing);

    await tester.scrollUntilVisible(groupTile('nha-tre'), -200);
    await openGroup(tester, 'nha-tre');
    expect(inCard('Bữa phụ sáng', 'Có 2 ảnh'), findsOneWidget);
    expect(
      inCard('Bữa phụ sáng', 'Đăng được 07:30–08:30 · đã qua'),
      findsOneWidget,
    );
    expect(inCard('Bữa phụ sáng', 'Chụp thêm'), findsNothing);
  });

  testWidgets('Ảnh mẫu: hết giờ mà chưa có ảnh ⇒ chỉ báo đỏ, không chụp bù', (
    tester,
  ) async {
    await pumpPhotos(
      tester,
      source: _DaySource(
        _oneGroupDay(const [
          SampleMeal(
            id: 'LUNCH',
            name: 'Bữa trưa',
            window: PhotoWindow.closed,
            opensAt: '10:30',
            closesAt: '11:30',
          ),
        ]),
      ),
    );
    expect(inCard('Bữa trưa', 'Quá giờ, chưa có ảnh'), findsOneWidget);
    expect(
      inCard(
        'Bữa trưa',
        'Hết giờ đăng (10:30–11:30). Ảnh bữa này không đăng thêm được.',
      ),
      findsOneWidget,
    );
    expect(inCard('Bữa trưa', 'Chụp ảnh mẫu bữa trưa'), findsNothing);
    expect(inCard('Bữa trưa', 'Chụp thêm'), findsNothing);
  });

  testWidgets('Ảnh mẫu: Hiệu trưởng chưa đặt giờ đăng ⇒ báo, không chụp', (
    tester,
  ) async {
    await pumpPhotos(
      tester,
      source: _DaySource(
        _oneGroupDay(const [
          SampleMeal(
            id: 'AFTERNOON',
            name: 'Bữa chiều',
            window: PhotoWindow.notSet,
          ),
        ]),
      ),
    );
    expect(inCard('Bữa chiều', 'Chưa có giờ đăng'), findsOneWidget);
    expect(
      inCard(
        'Bữa chiều',
        'Chưa đăng được ảnh bữa chiều. Báo Hiệu trưởng đặt giờ đăng ảnh trong Cấu hình thời gian.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'Ảnh mẫu: đang đăng thì vùng chụp chờ, bấm lại không đăng trùng',
    (tester) async {
      final source = _RecordingSource(delay: const Duration(milliseconds: 300));
      await pumpPhotos(tester, source: source);
      await tapLunchCapture(tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(inCard('Bữa trưa', 'Đang đăng ảnh…'), findsOneWidget);
      await tester.tap(inCard('Bữa trưa', 'Đang đăng ảnh…'));
      await tester.pumpAndSettle();
      expect(source.posted, hasLength(1));
      expect(inCard('Bữa trưa', 'Có 1 ảnh'), findsOneWidget);
    },
  );

  testWidgets(
    'Ảnh mẫu: đăng lỗi ⇒ giữ ảnh vừa chụp, Đăng lại gửi đúng ảnh đó',
    (tester) async {
      final camera = _FakeCamera();
      final source = _RecordingSource(failures: 1);
      await pumpPhotos(tester, source: source, camera: camera);
      await tapLunchCapture(tester);
      await tester.pumpAndSettle();
      expect(
        inCard(
          'Bữa trưa',
          'Chưa đăng được ảnh vừa chụp. Kiểm tra mạng rồi đăng lại.',
        ),
        findsOneWidget,
      );
      expect(inCard('Bữa trưa', 'Chưa đăng'), findsOneWidget);
      expect(inCard('Bữa trưa', 'Cần chụp'), findsOneWidget);

      await tester.ensureVisible(inCard('Bữa trưa', 'Đăng lại ảnh'));
      await tester.pumpAndSettle();
      await tester.tap(inCard('Bữa trưa', 'Đăng lại ảnh'));
      await tester.pumpAndSettle();
      expect(camera.calls, 1);
      expect(source.posted, [_png, _png]);
      expect(inCard('Bữa trưa', 'Có 1 ảnh'), findsOneWidget);
      expect(inCard('Bữa trưa', 'Đăng lại ảnh'), findsNothing);
      expect(inCard('Bữa trưa', 'Chưa đăng'), findsNothing);
    },
  );

  testWidgets('Ảnh mẫu: tải lỗi rồi Thử lại ⇒ hiện các nhóm tuổi', (
    tester,
  ) async {
    await pumpPhotos(tester, source: _FailOnceSource());
    expect(find.text('Chưa tải được ảnh mẫu'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(inTile('nha-tre', '2/3'), findsOneWidget);
  });

  testWidgets('Ảnh mẫu: ngày nghỉ ⇒ không có bữa cần ảnh', (tester) async {
    await pumpPhotos(
      tester,
      source: FakeKitchenPhotoSource(
        mode: FakeMode.empty,
        delay: Duration.zero,
      ),
    );
    expect(find.text('Hôm nay trường nghỉ'), findsOneWidget);
    expect(find.text('Không có bữa nào cần ảnh mẫu.'), findsOneWidget);
  });

  testWidgets('AC-10: Ảnh mẫu chữ 2.0 không tràn', (tester) async {
    await pumpPhotos(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    await tapLunchCapture(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(groupTile('nha-tre'), -300);
    await openGroup(tester, 'nha-tre');
    expect(tester.takeException(), isNull);
  });
}

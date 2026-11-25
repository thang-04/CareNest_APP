import 'package:flutter/foundation.dart';
import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

/// Ảnh mẫu giả của bếp cơ sở chính lúc 10:50 ngày 12/10: bữa phụ sáng đã có ảnh (hết giờ đăng), bữa
/// trưa đang mở chưa có ảnh, bữa chiều chưa tới giờ. 1 ảnh mỗi bữa như BE (NUT-16, user 25/11);
/// ảnh chụp thêm chỉ giữ trong bộ nhớ và thay ảnh cũ.
class FakeKitchenPhotoSource implements KitchenPhotoSource {
  FakeKitchenPhotoSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 300),
  });

  /// Một nguồn cho Trang chủ bếp và màn Ảnh mẫu khi chạy bản giả: chụp ở màn ảnh thì việc ở Trang chủ đổi theo.
  static final shared = FakeKitchenPhotoSource();

  final FakeMode mode;
  final Duration delay;

  /// Giờ giả "bây giờ", gắn cho ảnh vừa đăng
  static const _now = '10:50';

  /// Ảnh vừa chụp theo bữa (thay ảnh có sẵn).
  final Map<String, Uint8List> _added = {};

  /// Bữa: tên, giờ mở, giờ đóng, trạng thái giờ đăng, số phút còn, giờ đăng ảnh có sẵn.
  static const _meals = [
    (
      'MORNING',
      'Bữa phụ sáng',
      '07:30',
      '08:30',
      PhotoWindow.closed,
      null,
      '07:52',
    ),
    ('LUNCH', 'Bữa trưa', '10:30', '11:30', PhotoWindow.open, 40, null),
    (
      'AFTERNOON',
      'Bữa chiều',
      '14:30',
      '15:30',
      PhotoWindow.upcoming,
      null,
      null,
    ),
  ];

  KitchenPhotoDay _day() => KitchenPhotoDay(
    date: FakeParentHomeSource.today,
    campusLabel: 'Cơ sở chính',
    isDayOff: mode == FakeMode.empty,
    meals: mode == FakeMode.empty
        ? const []
        : [
            for (final (id, name, opensAt, closesAt, window, left, posted)
                in _meals)
              SampleMeal(
                id: id,
                name: name,
                window: window,
                opensAt: opensAt,
                closesAt: closesAt,
                minutesLeft: left,
                photos: [
                  if (_added[id] case final bytes?)
                    SamplePhoto(id: '$id-new', postedAt: _now, bytes: bytes)
                  // Ảnh giả có sẵn: chưa có tệp, hiện ô giữ chỗ
                  else if (posted != null)
                    SamplePhoto(id: '$id-1', postedAt: posted),
                ],
              ),
          ],
  );

  @override
  Future<KitchenPhotoDay> loadToday() async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    return _day();
  }

  @override
  Future<KitchenPhotoDay> addPhoto({
    required String mealId,
    required Uint8List bytes,
  }) async {
    await Future<void>.delayed(delay);
    _added[mealId] = bytes;
    return _day();
  }

  @override
  Future<Uint8List> loadPhoto(String photoId) =>
      Future.error(StateError('Ảnh giả không có tệp'));
}

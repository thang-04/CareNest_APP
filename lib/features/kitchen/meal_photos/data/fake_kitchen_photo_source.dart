import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/kitchen/kitchen_day/domain/kitchen_day.dart';
import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

/// Ảnh mẫu giả của bếp cơ sở chính lúc khoảng 11:00 ngày 12/10: bữa phụ sáng đã có ảnh
/// (hết giờ đăng), bữa trưa đang mở chưa có ảnh, bữa chiều chưa tới giờ.
/// Ảnh đăng thêm chỉ giữ trong bộ nhớ; đăng lại thay ảnh cũ như BE.
class FakeKitchenPhotoSource implements KitchenPhotoSource {
  FakeKitchenPhotoSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 300),
  });

  final FakeMode mode;
  final Duration delay;

  final Map<MealSession, SamplePhoto> _uploaded = {};
  int _nextId = 1;

  static const _windows = {
    MealSession.morning: ('07:30–08:30', PhotoWindow.closed),
    MealSession.lunch: ('10:30–11:30', PhotoWindow.open),
    MealSession.afternoon: ('14:30–15:30', PhotoWindow.upcoming),
  };

  KitchenPhotoDay _day() {
    final today = FakeParentHomeSource.today;
    return KitchenPhotoDay(
      date: today,
      kitchenLabel: 'Bếp cơ sở chính',
      meals: mode == FakeMode.empty
          ? const []
          : [
              for (final MapEntry(key: session, value: (label, window))
                  in _windows.entries)
                SampleMeal(
                  session: session,
                  windowLabel: label,
                  window: window,
                  photo:
                      _uploaded[session] ??
                      (session == MealSession.morning
                          // Ảnh giả có sẵn: chưa có tệp, hiện ô giữ chỗ
                          ? SamplePhoto(
                              id: 'seed-morning',
                              uploadedAt: DateTime(
                                today.year,
                                today.month,
                                today.day,
                                7,
                                50,
                              ),
                            )
                          : null),
                ),
            ],
    );
  }

  @override
  Future<KitchenPhotoDay> loadToday() async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    return _day();
  }

  @override
  Future<KitchenPhotoDay> upload({
    required MealSession session,
    required Uint8List bytes,
  }) async {
    await Future<void>.delayed(delay);
    final today = FakeParentHomeSource.today;
    _uploaded[session] = SamplePhoto(
      id: 'new-${_nextId++}',
      uploadedAt: DateTime(today.year, today.month, today.day, 11),
      bytes: bytes,
    );
    return _day();
  }
}

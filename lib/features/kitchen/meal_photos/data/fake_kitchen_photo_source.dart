import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

/// Ảnh mẫu giả của bếp cơ sở chính lúc khoảng 11:00 ngày 12/10: bữa sáng đã hết giờ đăng,
/// bữa trưa đang mở, bữa chiều chưa tới giờ. Nhóm Lá ăn 2 bữa (ví dụ của user 17/11).
/// Nhóm Mầm khớp ảnh phụ huynh thấy trong Thực đơn tuần. Ảnh đăng thêm chỉ giữ trong bộ nhớ.
class FakeKitchenPhotoSource implements KitchenPhotoSource {
  FakeKitchenPhotoSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 300),
  });

  final FakeMode mode;
  final Duration delay;

  /// Số ảnh đăng thêm theo "nhóm|bữa".
  final Map<String, int> _added = {};

  static const _windows = {
    'MORNING': ('Bữa sáng', '07:45', '07:30–08:30', PhotoWindow.closed),
    'LUNCH': ('Bữa trưa', '10:45', '10:30–11:30', PhotoWindow.open),
    'AFTERNOON': ('Bữa chiều', '14:30', '14:30–15:30', PhotoWindow.upcoming),
  };

  static const _groups = [
    (
      'nha-tre',
      'Nhà trẻ',
      '2–3 tuổi',
      {'MORNING': 2, 'LUNCH': 1, 'AFTERNOON': 0},
    ),
    ('mam', 'Mầm', '3–4 tuổi', {'MORNING': 3, 'LUNCH': 2, 'AFTERNOON': 0}),
    ('choi', 'Chồi', '4–5 tuổi', {'MORNING': 0, 'LUNCH': 0, 'AFTERNOON': 0}),
    ('la', 'Lá', '5–6 tuổi', {'LUNCH': 0, 'AFTERNOON': 0}),
  ];

  SampleMeal _meal(String groupId, String mealId, int posted) {
    final (name, time, windowLabel, window) = _windows[mealId]!;
    final count = posted + (_added['$groupId|$mealId'] ?? 0);
    return SampleMeal(
      id: mealId,
      name: name,
      time: time,
      windowLabel: windowLabel,
      window: window,
      photoIds: [for (var i = 1; i <= count; i++) '$groupId-$mealId-$i'],
    );
  }

  KitchenPhotoDay _day() => KitchenPhotoDay(
    date: FakeParentHomeSource.today,
    kitchenLabel: 'Bếp cơ sở chính',
    groups: mode == FakeMode.empty
        ? const []
        : [
            for (final (id, label, ageRange, meals) in _groups)
              AgeGroupMeals(
                id: id,
                label: label,
                ageRange: ageRange,
                meals: [
                  for (final MapEntry(key: mealId, value: posted)
                      in meals.entries)
                    _meal(id, mealId, posted),
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
    required String groupId,
    required String mealId,
    required Uint8List bytes,
  }) async {
    await Future<void>.delayed(delay);
    final key = '$groupId|$mealId';
    _added[key] = (_added[key] ?? 0) + 1;
    return _day();
  }
}

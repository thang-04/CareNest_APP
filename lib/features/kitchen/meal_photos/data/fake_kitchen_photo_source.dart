import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

/// Ảnh mẫu giả của bếp cơ sở chính lúc 10:50 ngày 12/10 (canvas "Màn bếp theo nhóm tuổi (B)"):
/// bữa phụ sáng đã hết giờ đăng, bữa trưa đang mở, bữa chiều chưa tới giờ. Bữa của từng nhóm
/// theo seed BE `age_groups.meal_sessions`: Nhà trẻ 3 bữa, Mẫu giáo bé/nhỡ/lớn bữa trưa và
/// bữa chiều. Ảnh đăng thêm chỉ giữ trong bộ nhớ.
class FakeKitchenPhotoSource implements KitchenPhotoSource {
  FakeKitchenPhotoSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 300),
  });

  final FakeMode mode;
  final Duration delay;

  /// Giờ giả "bây giờ", gắn cho ảnh vừa đăng
  static const _now = '10:50';

  /// Ảnh đăng thêm theo "nhóm|bữa".
  final Map<String, List<Uint8List>> _added = {};

  static const _windows = {
    'MORNING': ('Bữa phụ sáng', '07:30', '08:30', PhotoWindow.closed, null),
    'LUNCH': ('Bữa trưa', '10:30', '11:30', PhotoWindow.open, 40),
    'AFTERNOON': ('Bữa chiều', '14:30', '15:30', PhotoWindow.upcoming, null),
  };

  /// Giờ đăng các ảnh có sẵn theo bữa
  static const _groups = [
    (
      'nha-tre',
      'Nhà trẻ',
      '24–36 tháng',
      {
        'MORNING': ['07:52', '07:55'],
        'LUNCH': ['10:41'],
        'AFTERNOON': <String>[],
      },
    ),
    (
      'mg-be',
      'Mẫu giáo bé',
      '3–4 tuổi',
      {
        'LUNCH': ['10:44'],
        'AFTERNOON': <String>[],
      },
    ),
    (
      'mg-nho',
      'Mẫu giáo nhỡ',
      '4–5 tuổi',
      {'LUNCH': <String>[], 'AFTERNOON': <String>[]},
    ),
    (
      'mg-lon',
      'Mẫu giáo lớn',
      '5–6 tuổi',
      {'LUNCH': <String>[], 'AFTERNOON': <String>[]},
    ),
  ];

  SampleMeal _meal(String groupId, String mealId, List<String> posted) {
    final (name, opensAt, closesAt, window, minutesLeft) = _windows[mealId]!;
    final added = _added['$groupId|$mealId'] ?? const [];
    return SampleMeal(
      id: mealId,
      name: name,
      window: window,
      opensAt: opensAt,
      closesAt: closesAt,
      minutesLeft: minutesLeft,
      photos: [
        // Ảnh giả có sẵn: chưa có tệp, hiện ô giữ chỗ
        for (final (i, time) in posted.indexed)
          SamplePhoto(id: '$groupId-$mealId-${i + 1}', postedAt: time),
        for (final (i, bytes) in added.indexed)
          SamplePhoto(
            id: '$groupId-$mealId-new-${i + 1}',
            postedAt: _now,
            bytes: bytes,
          ),
      ],
    );
  }

  KitchenPhotoDay _day() => KitchenPhotoDay(
    date: FakeParentHomeSource.today,
    campusLabel: 'Cơ sở chính',
    isDayOff: mode == FakeMode.empty,
    groups: mode == FakeMode.empty
        ? const []
        : [
            for (final (id, name, ageRange, meals) in _groups)
              AgeGroupMeals(
                id: id,
                name: name,
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
    (_added['$groupId|$mealId'] ??= []).add(bytes);
    return _day();
  }
}

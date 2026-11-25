import 'package:carenest_app/features/kitchen/kitchen_meals/domain/kitchen_meals.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

/// Suất giả ngày 12/10 cơ sở chính, PHT xác nhận 08:30, khớp Trang chủ bếp: bữa phụ sáng chỉ
/// Nhà trẻ (46 suất, 1 thay thế); trưa và chiều 182 suất (175 thường, 7 thay thế).
/// Mầm 3A 24 + 1 khớp màn Giáo viên (25 bé có mặt, 1 bé dị ứng ăn suất thay thế).
class FakeKitchenMealsSource implements KitchenMealsSource {
  FakeKitchenMealsSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 400),
  });

  final FakeMode mode;
  final Duration delay;

  /// Bảng cũ theo mockup K03, còn dùng cho màn chốt suất của Phó HT (V04, chỉ debug).
  static const classes = [
    ClassMealCount(
      className: 'Mầm 3A',
      regular: 24,
      alternative: 1,
      note: 'dị ứng hải sản',
      changed: true,
    ),
    ClassMealCount(className: 'Mầm 3B', regular: 26, alternative: 0),
    ClassMealCount(
      className: 'Chồi 1',
      regular: 29,
      alternative: 2,
      note: 'ăn chay',
    ),
    ClassMealCount(
      className: 'Chồi 2',
      regular: 30,
      alternative: 1,
      note: 'dị ứng hải sản',
    ),
    ClassMealCount(
      className: 'Lá 1',
      regular: 31,
      alternative: 2,
      note: 'dị ứng sữa bò, hải sản',
    ),
    ClassMealCount(
      className: 'Lá 2',
      regular: 35,
      alternative: 1,
      note: 'ăn chay',
    ),
  ];

  static const _nursery = [
    ClassMealCount(className: 'Nhà trẻ 1', regular: 23, alternative: 1),
    ClassMealCount(className: 'Nhà trẻ 2', regular: 22, alternative: 0),
  ];

  static const _allClasses = [
    ..._nursery,
    ClassMealCount(className: 'Mầm 3A', regular: 24, alternative: 1),
    ClassMealCount(className: 'Mầm 3B', regular: 26, alternative: 0),
    ClassMealCount(className: 'Chồi 1', regular: 22, alternative: 2),
    ClassMealCount(className: 'Chồi 2', regular: 21, alternative: 1),
    ClassMealCount(className: 'Lá 1', regular: 18, alternative: 2),
    ClassMealCount(className: 'Lá 2', regular: 19, alternative: 0),
  ];

  static const _sessions = [
    SessionMealCount(
      session: 'MORNING',
      label: 'Bữa phụ sáng',
      blockNote: 'Nhà trẻ',
      total: 46,
      regular: 45,
      alternative: 1,
      classes: _nursery,
    ),
    SessionMealCount(
      session: 'LUNCH',
      label: 'Bữa trưa',
      total: 182,
      regular: 175,
      alternative: 7,
      classes: _allClasses,
    ),
    SessionMealCount(
      session: 'AFTERNOON',
      label: 'Bữa chiều',
      total: 182,
      regular: 175,
      alternative: 7,
      classes: _allClasses,
    ),
  ];

  @override
  Future<MealCountSheet?> loadSheet() async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    if (mode == FakeMode.empty) return null;
    final today = FakeParentHomeSource.today;
    return MealCountSheet(
      confirmedAt: DateTime(today.year, today.month, today.day, 8, 30),
      sessions: _sessions,
    );
  }
}

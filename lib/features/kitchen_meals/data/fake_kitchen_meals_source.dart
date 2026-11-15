import 'package:carenest_app/features/kitchen_meals/domain/kitchen_meals.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';

/// Dữ liệu giả mockup K03 — bữa trưa 12/10 cơ sở chính: 182 suất (175 thường, 7 thay thế).
/// Mầm 3A 24 + 1 khớp màn Giáo viên (25 bé có mặt, bé Hoàng Nam dị ứng hải sản).
class FakeKitchenMealsSource implements KitchenMealsSource {
  FakeKitchenMealsSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 400),
  });

  final FakeMode mode;
  final Duration delay;

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

  @override
  Future<MealCountSheet?> loadSheet() async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    if (mode == FakeMode.empty) return null;
    return MealCountSheet(
      mealLabel: 'Bữa trưa',
      confirmedAt: DateTime(
        FakeParentHomeSource.today.year,
        FakeParentHomeSource.today.month,
        FakeParentHomeSource.today.day,
        8,
        30,
      ),
      total: 182,
      regular: 175,
      alternative: 7,
      classes: classes,
      adjustmentNote:
          '09:05 · Mầm 3A xin +1 suất (giáo viên sửa điểm danh) · chờ Phó HT duyệt',
    );
  }
}

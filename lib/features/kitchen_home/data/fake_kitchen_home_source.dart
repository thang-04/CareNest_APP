import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/features/kitchen_home/domain/kitchen_today.dart';
import 'package:carenest_app/features/kitchen_meal_samples/data/fake_meal_sample_source.dart';
import 'package:carenest_app/features/kitchen_meals/data/fake_kitchen_meals_source.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/school_menu/domain/meal_slot.dart';

/// Dữ liệu giả Figma Bếp 01, khớp K03 (182 suất, 6 lớp, Mầm 3A +1 do GV sửa điểm danh), K04 (định lượng)
/// và khung giờ ảnh mẫu bữa trưa.
class FakeKitchenHomeSource implements KitchenHomeSource {
  FakeKitchenHomeSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 400),
  });

  final FakeMode mode;
  final Duration delay;

  @override
  Future<KitchenToday> loadToday() async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    final today = FakeParentHomeSource.today;
    if (mode == FakeMode.empty) {
      return KitchenToday(
        staffName: 'Nguyễn Thị Mai',
        kitchenLabel: 'Bếp cơ sở chính',
        date: today,
        tasks: const [],
      );
    }
    var regular = 0;
    var alternative = 0;
    for (final row in FakeKitchenMealsSource.classes) {
      regular += row.regular;
      alternative += row.alternative;
    }
    final total = regular + alternative;
    final lunchWindow = FakeMealSampleSource.windows[MealSlot.lunch]!;
    return KitchenToday(
      staffName: 'Nguyễn Thị Mai',
      kitchenLabel: 'Bếp cơ sở chính',
      date: today,
      mealLabel: 'Bữa trưa',
      confirmedAt: DateTime(today.year, today.month, today.day, 8, 30),
      total: total,
      regular: regular,
      alternative: alternative,
      tasks: [
        const KitchenTask(
          kind: KitchenTaskKind.menu,
          title: 'Thực đơn hôm nay',
          subtitle: 'Đã công bố · có thực đơn thay thế',
          badge: 'Xem',
          level: KitchenBadgeLevel.info,
        ),
        const KitchenTask(
          kind: KitchenTaskKind.mealCounts,
          title: 'Suất ăn theo lớp',
          subtitle: '6 lớp · cập nhật 09:05',
          badge: '+1 suất',
          level: KitchenBadgeLevel.changed,
        ),
        KitchenTask(
          kind: KitchenTaskKind.quantities,
          title: 'Định lượng thực phẩm',
          subtitle: 'Theo $total suất đã xác nhận',
          badge: 'Xem',
          level: KitchenBadgeLevel.done,
        ),
        KitchenTask(
          kind: KitchenTaskKind.mealSamples,
          title: 'Ảnh mẫu bữa',
          subtitle:
              'Bữa trưa · chụp ${DateLabels.time24(lunchWindow.opensAt)}–${DateLabels.time24(lunchWindow.closesAt)}',
          badge: 'Cần làm',
          level: KitchenBadgeLevel.todo,
          highlighted: true,
        ),
        const KitchenTask(
          kind: KitchenTaskKind.sampleLog,
          title: 'Sổ lưu mẫu',
          subtitle: 'Bữa trưa chưa ghi mẫu',
          badge: 'Ghi',
          level: KitchenBadgeLevel.info,
        ),
      ],
    );
  }
}

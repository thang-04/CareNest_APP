import 'package:carenest_app/features/kitchen/kitchen_home/domain/kitchen_today.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

/// Dữ liệu giả Trang chủ bếp, khớp `FakeKitchenDaySource` (bữa trưa 200 suất, 7 lớp),
/// ảnh mẫu giả và sổ lưu mẫu giả (bữa trưa chưa lưu, 1 mẫu hôm qua cần hủy).
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
    return KitchenToday(
      staffName: 'Nguyễn Thị Mai',
      kitchenLabel: 'Bếp cơ sở chính',
      date: today,
      mealLabel: 'Bữa trưa',
      confirmedAt: DateTime(today.year, today.month, today.day, 8, 30),
      total: 200,
      regular: 193,
      alternative: 7,
      tasks: const [
        KitchenTask(
          kind: KitchenTaskKind.menu,
          title: 'Thực đơn hôm nay',
          subtitle: 'Đã công bố',
          badge: 'Xem',
          level: KitchenBadgeLevel.info,
        ),
        KitchenTask(
          kind: KitchenTaskKind.mealCounts,
          title: 'Suất ăn theo lớp',
          subtitle: '4 nhóm tuổi · 7 lớp',
          badge: 'Đã xác nhận',
          level: KitchenBadgeLevel.done,
        ),
        KitchenTask(
          kind: KitchenTaskKind.foodNeeds,
          title: 'Thực phẩm cần',
          subtitle: 'Hàng tươi · Hàng khô',
          badge: 'Xem',
          level: KitchenBadgeLevel.info,
        ),
        // Khớp ảnh mẫu giả: bữa trưa đang mở giờ đăng, chưa có ảnh
        KitchenTask(
          kind: KitchenTaskKind.mealPhotos,
          title: 'Ảnh mẫu bữa ăn',
          subtitle: 'Bữa trưa chưa có ảnh',
          badge: 'Cần chụp',
          level: KitchenBadgeLevel.todo,
          highlighted: true,
        ),
        KitchenTask(
          kind: KitchenTaskKind.foodSamples,
          title: 'Sổ lưu mẫu',
          subtitle: 'Bữa trưa chưa lưu · 1 mẫu cần hủy',
          badge: 'Cần ghi',
          level: KitchenBadgeLevel.todo,
        ),
      ],
    );
  }
}

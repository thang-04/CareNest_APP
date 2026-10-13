import 'package:carenest_app/features/food_quantities/data/fake_food_quantity_source.dart';
import 'package:carenest_app/features/kitchen_home/domain/kitchen_today.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';

/// Dữ liệu giả mockup K01, khớp K03 (182 suất, 6 lớp, Mầm 3A xin +1 chờ duyệt), K04 (phiếu đã duyệt),
/// K05 (2 lô).
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
      total: 182,
      regular: 175,
      alternative: 7,
      tasks: const [
        KitchenTask(
          kind: KitchenTaskKind.menu,
          title: 'Thực đơn hôm nay',
          subtitle: 'Đã công bố · có thực đơn thay thế',
          badge: 'Xem',
          level: KitchenBadgeLevel.info,
        ),
        KitchenTask(
          kind: KitchenTaskKind.mealCounts,
          title: 'Suất ăn theo lớp',
          subtitle: '6 lớp · Mầm 3A xin +1 suất lúc 09:05',
          badge: 'Chờ duyệt +1',
          level: KitchenBadgeLevel.changed,
        ),
        KitchenTask(
          kind: KitchenTaskKind.quantities,
          title: 'Định lượng & phiếu xuất kho',
          subtitle: '${FakeFoodQuantitySource.slipCode} · Phó HT đã duyệt',
          badge: 'Đã duyệt',
          level: KitchenBadgeLevel.done,
        ),
        KitchenTask(
          kind: KitchenTaskKind.receipt,
          title: 'Nhận nguyên liệu',
          subtitle: '2 lô chờ xác nhận',
          badge: 'Cần làm',
          level: KitchenBadgeLevel.todo,
          highlighted: true,
        ),
        KitchenTask(
          kind: KitchenTaskKind.cooking,
          title: 'Cập nhật trạng thái nấu',
          subtitle: 'Bữa trưa',
          badge: 'Cập nhật',
          level: KitchenBadgeLevel.info,
        ),
      ],
    );
  }
}

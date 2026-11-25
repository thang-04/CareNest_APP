import 'package:carenest_app/features/kitchen/kitchen_menu/domain/kitchen_menu.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

/// Thực đơn giả tuần của ngày giả (Xem thử): Thứ Hai – Thứ Năm đã công bố, Thứ Sáu chưa có món.
class FakeKitchenMenuSource implements KitchenMenuSource {
  const FakeKitchenMenuSource();

  static const _lunch = MenuSessionDishes(
    session: 'LUNCH',
    label: 'Bữa trưa',
    blocks: [
      MenuBlockDishes(
        label: 'Nhà trẻ',
        dishes: ['Cháo thịt bằm bí đỏ', 'Sữa chua'],
      ),
      MenuBlockDishes(
        label: 'Mẫu giáo',
        dishes: ['Cơm trắng', 'Cá basa sốt cà chua', 'Canh rau ngót'],
      ),
    ],
  );

  @override
  Future<KitchenMenuDay> loadDay([DateTime? date]) async {
    final day = date ?? FakeParentHomeSource.today;
    final published = day.weekday < DateTime.friday;
    return KitchenMenuDay(
      date: day,
      published: published,
      sessions: published
          ? const [
              MenuSessionDishes(
                session: 'MORNING',
                label: 'Bữa phụ sáng',
                blocks: [
                  MenuBlockDishes(label: 'Nhà trẻ', dishes: ['Sữa tươi']),
                ],
              ),
              _lunch,
              MenuSessionDishes(
                session: 'AFTERNOON',
                label: 'Bữa chiều',
                blocks: [
                  MenuBlockDishes(
                    label: 'Mẫu giáo',
                    dishes: ['Bánh flan', 'Nước cam'],
                  ),
                ],
              ),
            ]
          : const [],
    );
  }
}

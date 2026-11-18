import 'package:carenest_app/features/kitchen/food_quantities/domain/food_quantities.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

/// Lượng thực phẩm giả ngày 12/10 cơ sở chính, theo suất đã chốt của 3 bữa (bữa phụ sáng 46,
/// trưa 182, chiều 182) và món trong Sổ lưu mẫu giả.
class FakeFoodQuantitySource implements FoodQuantitySource {
  FakeFoodQuantitySource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 300),
  });

  final FakeMode mode;
  final Duration delay;

  static const _needs = [
    FoodNeed(
      food: 'Cá basa phi lê',
      amount: '10,5 kg',
      storage: FoodStorage.fresh,
    ),
    FoodNeed(
      food: 'Thịt lợn nạc',
      amount: '9,8 kg',
      storage: FoodStorage.fresh,
    ),
    FoodNeed(food: 'Bí đỏ', amount: '12 kg', storage: FoodStorage.fresh),
    FoodNeed(food: 'Cà rốt', amount: '1,5 kg', storage: FoodStorage.fresh),
    FoodNeed(food: 'Cà chua', amount: '3 kg', storage: FoodStorage.fresh),
    FoodNeed(food: 'Thịt gà', amount: '0,7 kg', storage: FoodStorage.fresh),
    FoodNeed(food: 'Chuối tiêu', amount: '15 kg', storage: FoodStorage.fresh),
    FoodNeed(food: 'Sữa chua', amount: '182 hộp', storage: FoodStorage.fresh),
    FoodNeed(food: 'Gạo tẻ', amount: '19,6 kg', storage: FoodStorage.dry),
    FoodNeed(food: 'Dầu ăn', amount: '1,2 lít', storage: FoodStorage.dry),
    FoodNeed(food: 'Nước mắm', amount: '0,8 lít', storage: FoodStorage.dry),
  ];

  @override
  Future<FoodNeedDay?> loadDay() async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    if (mode == FakeMode.empty) return null;
    return FoodNeedDay(date: FakeParentHomeSource.today, needs: _needs);
  }
}

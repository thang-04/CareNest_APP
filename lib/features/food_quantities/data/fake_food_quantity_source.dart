import 'package:carenest_app/features/food_quantities/domain/food_quantities.dart';

/// Định lượng giả mockup K04 — bữa trưa 12/10, 182 suất đã xác nhận; thịt gà cho 7 suất thay thế.
class FakeFoodQuantitySource implements FoodQuantitySource {
  const FakeFoodQuantitySource();

  @override
  Future<QuantityPlan> loadPlan() async => const QuantityPlan(
    mealLabel: 'Bữa trưa',
    servings: 182,
    lines: [
      QuantityLine(food: 'Gạo tẻ', usage: 'Cơm', amount: '18,2 kg'),
      QuantityLine(food: 'Thịt lợn nạc', usage: 'Canh bí đỏ', amount: '9,1 kg'),
      QuantityLine(food: 'Bí đỏ', usage: 'Canh bí đỏ', amount: '12,0 kg'),
      QuantityLine(
        food: 'Cá basa phi lê',
        usage: 'Cá sốt cà',
        amount: '10,5 kg',
      ),
      QuantityLine(food: 'Cà chua', usage: 'Cá sốt cà', amount: '3,0 kg'),
      QuantityLine(
        food: 'Thịt gà',
        usage: 'Suất thay thế',
        amount: '0,7 kg',
        forAlternative: true,
      ),
      QuantityLine(food: 'Chuối', usage: 'Tráng miệng', amount: '182 quả'),
    ],
  );
}

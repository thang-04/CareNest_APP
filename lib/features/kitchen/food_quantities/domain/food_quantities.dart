import 'package:flutter/foundation.dart';

/// Nơi lấy thực phẩm theo BE `FoodStorage` (NUT-10): hàng tươi NCC giao hằng ngày, hàng khô
/// lấy từ kho.
enum FoodStorage { fresh, dry }

/// Một thực phẩm cần cho cả ngày. Số do BE tính từ suất đã xác nhận và định lượng thực đơn đã
/// công bố, đã cộng thải bỏ (NUT-07); [amount] là chuỗi lớp dữ liệu định dạng từ số + đơn vị BE.
@immutable
class FoodNeed {
  const FoodNeed({
    required this.food,
    required this.amount,
    required this.storage,
  });

  /// "Cá basa phi lê"
  final String food;

  /// "10,5 kg"
  final String amount;
  final FoodStorage storage;
}

/// Lượng thực phẩm cần trong ngày (BE `KitchenDayResponse.foods`).
@immutable
class FoodNeedDay {
  const FoodNeedDay({required this.date, required this.needs});

  final DateTime date;
  final List<FoodNeed> needs;
}

abstract interface class FoodQuantitySource {
  /// Null khi chưa có lượng: ngày nghỉ, thực đơn chưa công bố hoặc chưa có suất đã xác nhận.
  Future<FoodNeedDay?> loadDay();
}

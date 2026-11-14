import 'package:flutter/foundation.dart';

/// Một thực phẩm cần dùng; số do BE tính = suất đã xác nhận × định lượng thực đơn đã công bố (NUT-07).
@immutable
class QuantityLine {
  const QuantityLine({
    required this.food,
    required this.usage,
    required this.amount,
    this.forAlternative = false,
  });

  final String food;

  /// "Canh bí đỏ"
  final String usage;

  /// "9,1 kg" — chuỗi BE định dạng sẵn.
  final String amount;
  final bool forAlternative;
}

@immutable
class QuantityPlan {
  const QuantityPlan({
    required this.mealLabel,
    required this.servings,
    required this.lines,
  });

  final String mealLabel;

  /// Số suất đã xác nhận của cơ sở (NUT-02).
  final int servings;
  final List<QuantityLine> lines;
}

abstract interface class FoodQuantitySource {
  Future<QuantityPlan> loadPlan();
}

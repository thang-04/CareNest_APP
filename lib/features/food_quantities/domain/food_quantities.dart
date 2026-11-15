import 'package:flutter/foundation.dart';

/// Một thực phẩm cần dùng; số do BE tính = suất đã chốt × định lượng thực đơn đã duyệt (NUT-07).
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

/// Phiếu xuất kho đã duyệt — nghiệp vụ nhận nguyên liệu mới (quyết định 7, PROPOSED).
@immutable
class IssueSlip {
  const IssueSlip({
    required this.code,
    required this.approvedBy,
    required this.approvedAt,
  });

  final String code;
  final String approvedBy;
  final DateTime approvedAt;
}

@immutable
class QuantityPlan {
  const QuantityPlan({
    required this.mealLabel,
    required this.servings,
    required this.lines,
    this.slip,
  });

  final String mealLabel;
  final int servings;
  final List<QuantityLine> lines;
  final IssueSlip? slip;
}

abstract interface class FoodQuantitySource {
  Future<QuantityPlan> loadPlan();
}

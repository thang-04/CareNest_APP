import 'package:flutter/foundation.dart';

/// Kết quả so chuẩn BE trả cho từng chất (NUT-06): APP không tự so với chuẩn.
enum NutrientVerdict { met, low, high }

@immutable
class NutrientRow {
  const NutrientRow({
    required this.name,
    required this.value,
    required this.standard,
    required this.verdict,
    required this.verdictLabel,
  });

  /// "Protein"
  final String name;

  /// "13,8%"
  final String value;

  /// "Chuẩn: 12–15%"
  final String standard;
  final NutrientVerdict verdict;

  /// "Đạt" / "Thiếu" / "Vượt"
  final String verdictLabel;
}

@immutable
class MealEnergy {
  const MealEnergy({required this.mealLabel, required this.energy});

  /// "Bữa sáng"
  final String mealLabel;

  /// "168 kcal"
  final String energy;
}

/// Cân đối dinh dưỡng một nhóm tuổi một ngày theo thực đơn đã duyệt — mockup V07. Tính xác định ở BE (NUT-06).
@immutable
class NutritionBalance {
  const NutritionBalance({
    required this.groupLabel,
    required this.date,
    required this.energy,
    required this.dayEnergy,
    required this.energyRatio,
    required this.energyNote,
    required this.energyMet,
    required this.nutrients,
    required this.meals,
    this.warning,
  });

  /// "Nhóm Mầm"
  final String groupLabel;
  final DateTime date;

  /// "612 / 615 kcal"
  final String energy;

  /// "612 kcal" — năng lượng thực đơn ngày, cho nhãn ngắn.
  final String dayEnergy;

  /// Tỉ lệ đạt so với nhu cầu (0–1) BE trả, chỉ để vẽ thanh.
  final double energyRatio;

  /// "Đạt 99,5% nhu cầu theo độ tuổi (3–4 tuổi)"
  final String energyNote;
  final bool energyMet;
  final List<NutrientRow> nutrients;
  final List<MealEnergy> meals;

  /// Cảnh báo BE trả, vd. "Canxi chưa đạt chuẩn…"
  final String? warning;
}

abstract interface class NutritionBalanceSource {
  /// Null khi nhóm tuổi không có thực đơn ngày đó.
  Future<NutritionBalance?> load({
    required String campusId,
    required String groupId,
    required DateTime day,
  });
}

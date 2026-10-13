import 'package:carenest_app/features/nutrition_balance/domain/nutrition_balance.dart';

/// Dữ liệu giả mockup V07 / H07: nhóm Mầm theo mockup (thiếu canxi); Chồi, Lá đạt. Nhà trẻ chỉ có ở
/// cơ sở 2 (khớp `FakeSchoolMenuSource`). Mọi "Đạt / Thiếu" là giá trị giả như BE trả.
class FakeNutritionBalanceSource implements NutritionBalanceSource {
  const FakeNutritionBalanceSource();

  static const _groups = {
    'nha-tre': ('Nhóm Nhà trẻ', '560 / 580 kcal', 0.966, '2–3 tuổi', '96,6%'),
    'mam': ('Nhóm Mầm', '612 / 615 kcal', 0.995, '3–4 tuổi', '99,5%'),
    'choi': ('Nhóm Chồi', '668 / 680 kcal', 0.982, '4–5 tuổi', '98,2%'),
    'la': ('Nhóm Lá', '702 / 720 kcal', 0.975, '5–6 tuổi', '97,5%'),
  };

  static const _meals = {
    'nha-tre': ['150 kcal', '290 kcal', '120 kcal'],
    'mam': ['168 kcal', '322 kcal', '122 kcal'],
    'choi': ['182 kcal', '352 kcal', '134 kcal'],
    'la': ['190 kcal', '372 kcal', '140 kcal'],
  };

  @override
  Future<NutritionBalance?> load({
    required String campusId,
    required String groupId,
    required DateTime day,
  }) async {
    final group = _groups[groupId];
    final meals = _meals[groupId];
    if (group == null || meals == null) return null;
    if (groupId == 'nha-tre' && campusId != 'campus-2') return null;
    final (label, energy, ratio, ages, percent) = group;
    final calciumLow = groupId == 'mam';
    return NutritionBalance(
      groupLabel: label,
      date: day,
      energy: energy,
      dayEnergy: '${energy.split(' / ').first} kcal',
      energyRatio: ratio,
      energyNote: 'Đạt $percent nhu cầu theo độ tuổi ($ages)',
      energyMet: true,
      nutrients: [
        const NutrientRow(
          name: 'Protein',
          value: '13,8%',
          standard: 'Chuẩn: 12–15%',
          verdict: NutrientVerdict.met,
          verdictLabel: 'Đạt',
        ),
        const NutrientRow(
          name: 'Lipid',
          value: '27,1%',
          standard: 'Chuẩn: 25–35%',
          verdict: NutrientVerdict.met,
          verdictLabel: 'Đạt',
        ),
        const NutrientRow(
          name: 'Glucid',
          value: '59,1%',
          standard: 'Chuẩn: 52–60%',
          verdict: NutrientVerdict.met,
          verdictLabel: 'Đạt',
        ),
        NutrientRow(
          name: 'Canxi',
          value: calciumLow ? '312 mg' : '368 mg',
          standard: 'Chuẩn: từ 350 mg',
          verdict: calciumLow ? NutrientVerdict.low : NutrientVerdict.met,
          verdictLabel: calciumLow ? 'Thiếu' : 'Đạt',
        ),
      ],
      meals: [
        for (final (i, name) in const [
          'Bữa sáng',
          'Bữa trưa',
          'Bữa chiều',
        ].indexed)
          MealEnergy(mealLabel: name, energy: meals[i]),
      ],
      warning: calciumLow
          ? 'Canxi chưa đạt chuẩn. Điều chỉnh định lượng thực hiện trên CareNest Web.'
          : null,
    );
  }
}

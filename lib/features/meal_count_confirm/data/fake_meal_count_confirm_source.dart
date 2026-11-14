import 'package:carenest_app/features/kitchen_meals/data/fake_kitchen_meals_source.dart';
import 'package:carenest_app/features/kitchen_meals/domain/kitchen_meals.dart';
import 'package:carenest_app/features/meal_count_confirm/domain/meal_count_draft.dart';

/// Dữ liệu giả mockup V04: bữa trưa 12/10, tổng hợp 08:15, giờ chốt 08:30 (khớp K03 "chốt lúc 08:30").
/// Số theo lớp như K03. Mặc định chưa xác nhận (PHT xác nhận trên Web); [confirmedAt] để xem trạng thái đã xác nhận.
class FakeMealCountConfirmSource implements MealCountConfirmSource {
  FakeMealCountConfirmSource({this.confirmedAt});

  static final shared = FakeMealCountConfirmSource();

  final DateTime? confirmedAt;

  late final MealCountDraft _draft = MealCountDraft(
    mealLabel: 'Bữa trưa',
    date: DateTime(2026, 10, 12),
    summarizedAt: DateTime(2026, 10, 12, 8, 15),
    deadline: DateTime(2026, 10, 12, 8, 30),
    total: 182,
    regular: 175,
    alternative: 7,
    classes: [
      for (final row in FakeKitchenMealsSource.classes)
        ClassMealCount(
          className: row.className,
          regular: row.regular,
          alternative: row.alternative,
          note: row.note,
        ),
    ],
    confirmedAt: confirmedAt,
  );

  @override
  Future<MealCountDraft> loadToday() async => _draft;
}

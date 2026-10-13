import 'package:carenest_app/features/kitchen_meals/data/fake_kitchen_meals_source.dart';
import 'package:carenest_app/features/kitchen_meals/domain/kitchen_meals.dart';
import 'package:carenest_app/features/meal_count_confirm/domain/meal_count_draft.dart';

/// Dữ liệu giả mockup V04: bữa trưa 12/10, tổng hợp 08:15, giờ chốt 08:30 (khớp K03 "chốt lúc 08:30").
/// Số theo lớp như K03; chưa có điều chỉnh vì điều chỉnh chỉ phát sinh sau khi chốt.
class FakeMealCountConfirmSource implements MealCountConfirmSource {
  FakeMealCountConfirmSource();

  static final shared = FakeMealCountConfirmSource();

  late MealCountDraft _draft = MealCountDraft(
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
  );

  @override
  Future<MealCountDraft> loadToday() async => _draft;

  @override
  Future<MealCountDraft> confirm() async {
    _draft = MealCountDraft(
      mealLabel: _draft.mealLabel,
      date: _draft.date,
      summarizedAt: _draft.summarizedAt,
      deadline: _draft.deadline,
      total: _draft.total,
      regular: _draft.regular,
      alternative: _draft.alternative,
      classes: _draft.classes,
      confirmedAt: DateTime(2026, 10, 12, 8, 25),
    );
    return _draft;
  }
}

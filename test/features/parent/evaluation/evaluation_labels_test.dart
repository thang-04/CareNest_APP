import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/parent/evaluation/domain/evaluation.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/evaluation_labels.dart';

void main() {
  // Cùng câu với Web (CareNest_FE DailyAssessmentCells.jsx › mealsText)
  test('meals_allFinished_saysAnHet', () {
    expect(
      EvaluationLabels.meals({
        MealSession.morning: EatingLevel.finished,
        MealSession.lunch: EatingLevel.finished,
        MealSession.afternoon: EatingLevel.finished,
      }),
      'Ăn hết',
    );
  });

  test('meals_listsOnlyMealsNotFinished', () {
    expect(
      EvaluationLabels.meals({
        MealSession.morning: EatingLevel.finished,
        MealSession.lunch: EatingLevel.none,
        MealSession.afternoon: EatingLevel.little,
      }),
      'Trưa: không ăn, Chiều (xế): ăn ít',
    );
  });
}

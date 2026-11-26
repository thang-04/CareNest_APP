import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/features/teacher/class_roster/domain/child_health.dart';

/// Sổ sức khỏe giả: 4 lần đo của kỳ cân đo, mới nhất trước.
class FakeChildHealthSource implements ChildHealthSource {
  const FakeChildHealthSource();

  @override
  Future<ChildHealthHistory> load(String childId) async => ChildHealthHistory(
    childId: childId,
    entries: [
      HealthEntry(
        date: DateTime(2026, 9, 5),
        title: 'Kỳ cân đo quý III',
        kindLabel: 'Kỳ cân đo',
        heightCm: 104,
        weightKg: 17.2,
        bmi: 15.9,
        warningLabel: 'Bình thường',
        warningTone: AppStatusTone.green,
      ),
      HealthEntry(
        date: DateTime(2026, 6, 5),
        title: 'Kỳ cân đo quý II',
        kindLabel: 'Kỳ cân đo',
        heightCm: 101.5,
        weightKg: 16.4,
        bmi: 15.9,
        warningLabel: 'Bình thường',
        warningTone: AppStatusTone.green,
      ),
      HealthEntry(
        date: DateTime(2026, 3, 5),
        title: 'Kỳ cân đo quý I',
        kindLabel: 'Kỳ cân đo',
        heightCm: 99,
        weightKg: 15.8,
        bmi: 16.1,
      ),
      HealthEntry(
        date: DateTime(2025, 12, 5),
        title: 'Kỳ cân đo quý IV',
        kindLabel: 'Kỳ cân đo',
        heightCm: 96.5,
        weightKg: 15.1,
        bmi: 16.2,
      ),
    ],
  );
}

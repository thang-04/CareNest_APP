import 'package:carenest_app/features/kitchen_sample_log/domain/sample_log.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';

/// Dữ liệu giả Sổ lưu mẫu, khớp thực đơn đã công bố thứ Hai 12/10; bữa trưa chưa ghi mẫu.
class FakeSampleLogSource implements SampleLogSource {
  FakeSampleLogSource();

  static final shared = FakeSampleLogSource();

  final List<SampleLogEntry> entries = [];

  @override
  Future<SampleLogForm> loadForm() async {
    final day = FakeParentHomeSource.today;
    return SampleLogForm(
      dishes: const [
        SampleDish(
          id: 'b-chao',
          slot: MealSlot.breakfast,
          dish: 'Cháo thịt bằm',
        ),
        SampleDish(id: 'l-canh', slot: MealSlot.lunch, dish: 'Canh bí đỏ thịt'),
        SampleDish(id: 'l-ca', slot: MealSlot.lunch, dish: 'Cá basa sốt cà'),
        SampleDish(
          id: 'l-ga',
          slot: MealSlot.lunch,
          dish: 'Thịt gà rim (thay thế)',
        ),
        SampleDish(id: 's-flan', slot: MealSlot.snack, dish: 'Bánh flan'),
      ],
      sampledAt: DateTime(day.year, day.month, day.day, 11, 5),
      suggestedDishId: 'l-ca',
    );
  }

  @override
  Future<void> record(SampleLogEntry entry) async => entries.add(entry);
}

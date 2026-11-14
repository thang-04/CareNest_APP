import 'package:carenest_app/features/kitchen_meal_samples/domain/meal_samples.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';

/// Dữ liệu giả Ảnh mẫu bữa, khớp Trang chủ bếp (bữa trưa 12/10, 7 suất thay thế) và thực đơn đã công bố.
/// Bữa trưa đã chụp mẫu suất thường.
class FakeMealSampleSource implements MealSampleSource {
  FakeMealSampleSource();

  static final shared = FakeMealSampleSource();

  static final _day = FakeParentHomeSource.today;

  static SampleWindow _window(int fromHour, int fromMinute, int toHour) =>
      SampleWindow(
        opensAt: DateTime(
          _day.year,
          _day.month,
          _day.day,
          fromHour,
          fromMinute,
        ),
        closesAt: DateTime(_day.year, _day.month, _day.day, toHour, fromMinute),
      );

  static final windows = {
    MealSlot.breakfast: _window(7, 30, 8),
    MealSlot.lunch: _window(10, 30, 11),
    MealSlot.snack: _window(14, 30, 15),
  };

  final Map<MealSlot, Set<SampleKind>> _captured = {
    MealSlot.lunch: {SampleKind.regular},
  };
  final List<MealSlot> saved = [];

  @override
  Future<MealSampleDay> loadDay() async => MealSampleDay(
    kitchenLabel: 'Bếp cơ sở chính',
    date: _day,
    menus: const {
      MealSlot.breakfast: 'Cháo thịt bằm · Sữa tươi',
      MealSlot.lunch: 'Cơm · Canh bí đỏ thịt · Cá basa sốt cà · Chuối',
      MealSlot.snack: 'Bánh flan · Nước cam',
    },
    windows: windows,
    kinds: SampleKind.values,
    alternativeCount: 7,
  );

  @override
  Set<SampleKind> captured(MealSlot slot) => Set.of(_captured[slot] ?? {});

  @override
  void capture(MealSlot slot, SampleKind kind) =>
      (_captured[slot] ??= {}).add(kind);

  @override
  Future<void> save(MealSlot slot) async => saved.add(slot);
}

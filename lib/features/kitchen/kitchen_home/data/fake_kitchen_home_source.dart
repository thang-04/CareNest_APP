import 'package:carenest_app/features/kitchen/food_samples/data/fake_food_sample_source.dart';
import 'package:carenest_app/features/kitchen/food_samples/domain/food_samples.dart';
import 'package:carenest_app/features/kitchen/kitchen_home/domain/kitchen_tasks.dart';
import 'package:carenest_app/features/kitchen/kitchen_home/domain/kitchen_today.dart';
import 'package:carenest_app/features/kitchen/meal_photos/data/fake_kitchen_photo_source.dart';
import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

/// Trang chủ bếp giả lúc 10:50 ngày 12/10: số suất khớp màn Suất ăn theo lớp (bữa phụ sáng
/// 46 suất của Nhà trẻ; trưa, chiều 182 suất; PHT xác nhận 08:30). Việc hôm nay
/// ghép từ ảnh mẫu và sổ lưu mẫu — BE không có API "việc hôm nay", lớp dữ liệu ghép khi nối.
class FakeKitchenHomeSource implements KitchenHomeSource {
  FakeKitchenHomeSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 400),
    KitchenPhotoSource? photos,
    FoodSampleSource? samples,
  }) : _photos = photos ?? FakeKitchenPhotoSource.shared,
       _samples = samples ?? FakeFoodSampleSource.shared;

  final FakeMode mode;
  final Duration delay;
  final KitchenPhotoSource _photos;
  final FoodSampleSource _samples;

  static const _servings = [
    SessionServings(
      session: 'MORNING',
      label: 'Bữa phụ sáng',
      total: 46,
      blockNote: 'Nhà trẻ',
    ),
    SessionServings(session: 'LUNCH', label: 'Bữa trưa', total: 182),
    SessionServings(session: 'AFTERNOON', label: 'Bữa chiều', total: 182),
  ];

  @override
  Future<KitchenToday> loadToday() async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    final today = FakeParentHomeSource.today;
    if (mode == FakeMode.empty) {
      return KitchenToday(
        date: today,
        campusLabel: 'Cơ sở chính',
        countStatus: KitchenCountStatus.none,
        servings: const [],
        tasks: const [],
        isDayOff: true,
      );
    }
    final photoDay = await _photos.loadToday();
    final sampleDay = await _samples.loadToday();
    return KitchenToday(
      date: today,
      campusLabel: 'Cơ sở chính',
      countStatus: KitchenCountStatus.confirmed,
      confirmedAt: DateTime(today.year, today.month, today.day, 8, 30),
      servings: _servings,
      tasks: kitchenTasks(photoDay, sampleDay),
      // Khớp thực đơn giả: cá basa có trẻ Mầm 3A dị ứng
      allergyDishes: 1,
    );
  }
}

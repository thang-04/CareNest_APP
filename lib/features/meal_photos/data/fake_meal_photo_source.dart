import 'package:carenest_app/features/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/meal_photos/domain/meal_photos.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';

/// Dữ liệu giả mockup T15/T16, khớp Thực đơn tuần (thứ Hai 12/10) và Điểm danh (25 bé có mặt,
/// bé Hoàng Nam dị ứng hải sản ăn suất thay thế). Một bản dùng chung giữa hai màn.
class FakeMealPhotoSource implements MealPhotoSource {
  FakeMealPhotoSource();

  static final shared = FakeMealPhotoSource();

  static const maxPhotos = 6;

  final Map<MealSlot, int> _captured = {MealSlot.lunch: 2};
  final Map<MealSlot, String> _sent = {
    MealSlot.breakfast: 'đã gửi 07:55 · 21/28 phụ huynh đã xem',
  };

  @override
  Future<MealPhotoDay> loadDay(String classId) async => MealPhotoDay(
    date: FakeParentHomeSource.today,
    className: FakeClassRosterSource.className,
    menus: const {
      MealSlot.breakfast: 'Cháo thịt bằm · Sữa tươi',
      MealSlot.lunch: 'Cơm · Canh bí đỏ thịt · Cá basa sốt cà · Chuối',
      MealSlot.snack: 'Bánh flan · Nước cam',
    },
    regularCount: 24,
    alternativeCount: 1,
    alternativeNote: 'Dị ứng hải sản: chụp riêng',
    alternativeChild: 'Lê Hoàng Nam',
    classSize: FakeClassRosterSource.kids.length,
    sentNotes: Map.of(_sent),
  );

  @override
  int capturedCount(MealSlot slot) => _captured[slot] ?? 0;

  @override
  void capture(MealSlot slot) {
    final count = capturedCount(slot);
    if (count < maxPhotos) _captured[slot] = count + 1;
  }

  @override
  Future<void> send(
    MealSlot slot,
    PhotoAudience audience,
    String message,
  ) async {
    _sent[slot] = 'đã gửi 11:05 · 0/28 phụ huynh đã xem';
  }
}

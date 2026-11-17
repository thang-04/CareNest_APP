import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

/// Ảnh mẫu giả của bếp cơ sở chính lúc khoảng 11:00 ngày 12/10: bữa sáng đã hết giờ đăng,
/// bữa trưa đang mở, bữa chiều chưa tới giờ. Nhóm Lá ăn 2 bữa (ví dụ của user 17/11).
/// Nhóm Mầm khớp ảnh phụ huynh thấy trong Thực đơn tuần.
class FakeKitchenPhotoSource implements KitchenPhotoSource {
  FakeKitchenPhotoSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 300),
  });

  final FakeMode mode;
  final Duration delay;

  static List<String> _ids(String prefix, int count) => [
    for (var i = 1; i <= count; i++) '$prefix-$i',
  ];

  static SampleMeal _breakfast(int photos) => SampleMeal(
    name: 'Bữa sáng',
    time: '07:45',
    windowLabel: '07:30–08:30',
    window: PhotoWindow.closed,
    photoIds: _ids('sang', photos),
  );

  static SampleMeal _lunch(int photos) => SampleMeal(
    name: 'Bữa trưa',
    time: '10:45',
    windowLabel: '10:30–11:30',
    window: PhotoWindow.open,
    photoIds: _ids('trua', photos),
  );

  static const _afternoon = SampleMeal(
    name: 'Bữa chiều',
    time: '14:30',
    windowLabel: '14:30–15:30',
    window: PhotoWindow.upcoming,
  );

  @override
  Future<KitchenPhotoDay> loadToday() async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    return KitchenPhotoDay(
      date: FakeParentHomeSource.today,
      kitchenLabel: 'Bếp cơ sở chính',
      groups: mode == FakeMode.empty
          ? const []
          : [
              AgeGroupMeals(
                id: 'nha-tre',
                label: 'Nhà trẻ',
                ageRange: '2–3 tuổi',
                meals: [_breakfast(2), _lunch(1), _afternoon],
              ),
              AgeGroupMeals(
                id: 'mam',
                label: 'Mầm',
                ageRange: '3–4 tuổi',
                meals: [_breakfast(3), _lunch(2), _afternoon],
              ),
              AgeGroupMeals(
                id: 'choi',
                label: 'Chồi',
                ageRange: '4–5 tuổi',
                meals: [_breakfast(0), _lunch(0), _afternoon],
              ),
              AgeGroupMeals(
                id: 'la',
                label: 'Lá',
                ageRange: '5–6 tuổi',
                meals: [_lunch(0), _afternoon],
              ),
            ],
    );
  }
}

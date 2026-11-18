import 'package:carenest_app/features/kitchen/kitchen_day/domain/kitchen_day.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

/// Dữ liệu giả theo `KitchenDayResponse` + nhóm tuổi (`/age-groups`, `Line.ageGroupId`)
/// + nguyên liệu món (`DishDetailResponse.Ingredient`). Cơ sở chính, 3 bữa đã xác nhận.
/// Nhóm Lá ăn 2 bữa (trưa, chiều). Mầm 3A 24 + 1 khớp màn Giáo viên.
class FakeKitchenDaySource implements KitchenDaySource {
  FakeKitchenDaySource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 400),
  });

  final FakeMode mode;
  final Duration delay;

  static const nhaTre = 1;
  static const mam = 2;
  static const choi = 3;
  static const la = 4;

  static const ageGroups = [
    KitchenAgeGroup(
      id: nhaTre,
      name: 'Nhà trẻ',
      block: MenuBlock.nursery,
      sessions: MealSession.values,
    ),
    KitchenAgeGroup(
      id: mam,
      name: 'Mầm',
      block: MenuBlock.kindergarten,
      sessions: MealSession.values,
    ),
    KitchenAgeGroup(
      id: choi,
      name: 'Chồi',
      block: MenuBlock.kindergarten,
      sessions: MealSession.values,
    ),
    KitchenAgeGroup(
      id: la,
      name: 'Lá',
      block: MenuBlock.kindergarten,
      sessions: [MealSession.lunch, MealSession.afternoon],
    ),
  ];

  static const _classes = [
    (10, 'Nhà trẻ 1', nhaTre, 18, 0),
    (1, 'Mầm 3A', mam, 24, 1),
    (2, 'Mầm 3B', mam, 26, 0),
    (3, 'Chồi 1', choi, 29, 2),
    (4, 'Chồi 2', choi, 30, 1),
    (5, 'Lá 1', la, 31, 2),
    (6, 'Lá 2', la, 35, 1),
  ];

  /// Gam/trẻ cho các nhóm mẫu giáo: cùng món, khác định lượng (NUT-13).
  static List<DishIngredient> _kg(String food, num mam, num choi, num la) => [
    DishIngredient(
      foodName: food,
      ageGroupId: FakeKitchenDaySource.mam,
      gramsPerChild: mam,
    ),
    DishIngredient(
      foodName: food,
      ageGroupId: FakeKitchenDaySource.choi,
      gramsPerChild: choi,
    ),
    DishIngredient(
      foodName: food,
      ageGroupId: FakeKitchenDaySource.la,
      gramsPerChild: la,
    ),
  ];

  static List<DishIngredient> _nt(String food, num grams) => [
    DishIngredient(foodName: food, ageGroupId: nhaTre, gramsPerChild: grams),
  ];

  static final menu = [
    SessionMenu(
      session: MealSession.morning,
      block: MenuBlock.nursery,
      dishes: [
        MenuDish(
          id: 41,
          name: 'Sữa công thức',
          ingredients: _nt('Sữa bột công thức', 30),
        ),
      ],
    ),
    SessionMenu(
      session: MealSession.morning,
      block: MenuBlock.kindergarten,
      dishes: [
        MenuDish(
          id: 11,
          name: 'Sữa tươi',
          ingredients: _kg('Sữa tươi', 180, 180, 180),
        ),
      ],
    ),
    SessionMenu(
      session: MealSession.lunch,
      block: MenuBlock.nursery,
      dishes: [
        MenuDish(
          id: 42,
          name: 'Cháo thịt bí đỏ',
          ingredients: [
            ..._nt('Gạo tẻ', 25),
            ..._nt('Thịt lợn nạc', 20),
            ..._nt('Bí đỏ', 30),
          ],
        ),
        MenuDish(id: 43, name: 'Chuối nghiền', ingredients: _nt('Chuối', 50)),
      ],
    ),
    SessionMenu(
      session: MealSession.lunch,
      block: MenuBlock.kindergarten,
      dishes: [
        MenuDish(
          id: 21,
          name: 'Cơm tẻ',
          ingredients: _kg('Gạo tẻ', 50, 55, 60),
        ),
        MenuDish(
          id: 22,
          name: 'Cá sốt cà chua',
          ingredients: [
            ..._kg('Cá basa phi lê', 50, 55, 60),
            ..._kg('Cà chua', 15, 15, 20),
          ],
        ),
        MenuDish(
          id: 23,
          name: 'Canh bí đỏ nấu thịt',
          ingredients: [
            ..._kg('Bí đỏ', 60, 65, 70),
            ..._kg('Thịt lợn nạc', 15, 15, 20),
          ],
        ),
        MenuDish(
          id: 24,
          name: 'Thịt gà rim (thay thế)',
          ingredients: _kg('Thịt gà', 50, 55, 60),
        ),
      ],
    ),
    SessionMenu(
      session: MealSession.afternoon,
      block: MenuBlock.nursery,
      dishes: [
        MenuDish(id: 44, name: 'Sữa chua', ingredients: _nt('Sữa chua', 100)),
      ],
    ),
    SessionMenu(
      session: MealSession.afternoon,
      block: MenuBlock.kindergarten,
      dishes: [
        MenuDish(
          id: 31,
          name: 'Cháo thịt bằm',
          ingredients: [
            ..._kg('Gạo tẻ', 30, 35, 40),
            ..._kg('Thịt lợn nạc', 20, 20, 25),
          ],
        ),
        MenuDish(id: 32, name: 'Chuối', ingredients: _kg('Chuối', 80, 80, 100)),
      ],
    ),
  ];

  static KitchenDay sample() {
    final today = FakeParentHomeSource.today;
    return KitchenDay(
      date: today,
      dayOff: false,
      menuStatus: KitchenMenuStatus.published,
      countStatus: KitchenCountStatus.confirmed,
      confirmedAt: DateTime(today.year, today.month, today.day, 8, 30),
      ageGroups: ageGroups,
      menu: menu,
      servings: [
        for (final session in MealSession.values)
          for (final (id, name, group, normal, substitute) in _classes)
            // Lớp chỉ có suất ở bữa nhóm tuổi của lớp được ăn (NUT-17)
            if (ageGroups
                .firstWhere((g) => g.id == group)
                .sessions
                .contains(session))
              ClassServings(
                session: session,
                classroomId: id,
                classroomName: name,
                ageGroupId: group,
                normal: normal,
                // Bữa phụ sáng là sữa, không có suất thay thế
                substitute: session == MealSession.morning ? 0 : substitute,
              ),
      ],
      foods: const [
        FoodNeed(
          name: 'Gạo tẻ',
          unit: 'kg',
          storage: FoodStorage.dry,
          quantity: 18.2,
        ),
        FoodNeed(
          name: 'Sữa tươi',
          unit: 'hộp',
          storage: FoodStorage.dry,
          quantity: 109,
        ),
        FoodNeed(
          name: 'Sữa bột công thức',
          unit: 'kg',
          storage: FoodStorage.dry,
          quantity: 0.5,
        ),
        FoodNeed(
          name: 'Cá basa phi lê',
          unit: 'kg',
          storage: FoodStorage.fresh,
          quantity: 10.5,
        ),
        FoodNeed(
          name: 'Thịt lợn nạc',
          unit: 'kg',
          storage: FoodStorage.fresh,
          quantity: 9.1,
        ),
        FoodNeed(
          name: 'Bí đỏ',
          unit: 'kg',
          storage: FoodStorage.fresh,
          quantity: 12,
        ),
        FoodNeed(
          name: 'Cà chua',
          unit: 'kg',
          storage: FoodStorage.fresh,
          quantity: 3,
        ),
        FoodNeed(
          name: 'Thịt gà',
          unit: 'kg',
          storage: FoodStorage.fresh,
          quantity: 0.7,
        ),
        FoodNeed(
          name: 'Chuối',
          unit: 'quả',
          storage: FoodStorage.fresh,
          quantity: 200,
        ),
        FoodNeed(
          name: 'Sữa chua',
          unit: 'hộp',
          storage: FoodStorage.fresh,
          quantity: 18,
        ),
      ],
    );
  }

  @override
  Future<KitchenDay> loadDay() async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    if (mode == FakeMode.empty) {
      return KitchenDay(
        date: FakeParentHomeSource.today,
        dayOff: false,
        menuStatus: KitchenMenuStatus.published,
        countStatus: KitchenCountStatus.none,
        ageGroups: ageGroups,
        menu: menu,
        servings: const [],
        foods: const [],
      );
    }
    return sample();
  }
}

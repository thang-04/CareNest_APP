import 'dart:typed_data';

import 'package:carenest_app/features/parent/parent_menu/domain/weekly_menu.dart';

/// Thực đơn giả tuần 12/10 – 16/10/2026 (Xem thử). child-2 học lớp Lá: ăn trưa và chiều, dị ứng cá.
class FakeWeeklyMenuSource implements WeeklyMenuSource {
  const FakeWeeklyMenuSource();

  static final weekStart = DateTime(2026, 10, 12);

  static const _breakfasts = [
    ['Cháo thịt bằm', 'Sữa tươi'],
    ['Bún bò', 'Sữa chua'],
    ['Phở gà', 'Sữa tươi'],
    ['Bánh mì trứng', 'Sữa đậu nành'],
    ['Xôi gấc', 'Sữa tươi'],
  ];
  static const _lunches = [
    ['Cơm trắng', 'Canh bí đỏ nấu thịt', 'Cá basa sốt cà chua', 'Chuối'],
    ['Cơm trắng', 'Canh rau ngót', 'Thịt kho trứng cút', 'Dưa hấu'],
    ['Cơm trắng', 'Canh cải nấu tôm', 'Gà rim gừng', 'Thanh long'],
    ['Cơm trắng', 'Canh mồng tơi nấu cua', 'Đậu sốt thịt', 'Đu đủ'],
    ['Cơm trắng', 'Canh chua cá', 'Thịt bò xào', 'Cam'],
  ];
  static const _snacks = [
    ['Bánh flan', 'Nước cam'],
    ['Chè đậu xanh'],
    ['Sữa chua', 'Bánh quy'],
    ['Khoai lang luộc', 'Sữa tươi'],
    ['Bánh bông lan', 'Nước ép táo'],
  ];

  @override
  Future<WeeklyMenu> loadWeek(String childId, {DateTime? weekStart}) async {
    final fishAllergy = childId == 'child-2';
    // Nhóm Lá ăn trưa và chiều (số bữa theo nhóm tuổi, NUT-17)
    final eatsMorning = !fishAllergy;
    List<MenuDish> dishes(List<String> names) => [
      for (final name in names)
        name.contains('Cá') || name.contains('cá')
            ? MenuDish(
                name: name,
                allergens: const ['Cá'],
                childAllergens: fishAllergy ? const ['Cá'] : const [],
              )
            : MenuDish(name: name),
    ];
    final start = FakeWeeklyMenuSource.weekStart;
    return WeeklyMenu(
      weekStart: start,
      days: [
        for (var i = 0; i < 5; i++)
          MenuDay(
            date: start.add(Duration(days: i)),
            meals: [
              if (eatsMorning)
                MenuMealEntry(
                  session: MenuSession.morning,
                  dishes: dishes(_breakfasts[i]),
                  photo: i == 0
                      ? MenuPhoto(
                          photoId: 'fake-0-morning',
                          uploadedAt: DateTime(2026, 10, 12, 7, 50),
                        )
                      : null,
                ),
              MenuMealEntry(
                session: MenuSession.lunch,
                dishes: dishes(_lunches[i]),
                photo: i == 0 && eatsMorning
                    ? MenuPhoto(
                        photoId: 'fake-0-lunch',
                        uploadedAt: DateTime(2026, 10, 12, 10, 52),
                      )
                    : null,
              ),
              MenuMealEntry(
                session: MenuSession.afternoon,
                dishes: dishes(_snacks[i]),
              ),
            ],
          ),
      ],
      unmatchedAllergies: fishAllergy ? const ['Dâu tây'] : const [],
    );
  }

  @override
  Future<Uint8List?> loadPhoto(String childId, String photoId) async => null;
}

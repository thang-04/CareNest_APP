import 'package:carenest_app/features/parent_menu/domain/weekly_menu.dart';

/// Thực đơn giả tuần 12/10 – 16/10/2026 theo mockup P05; trùng món với màn bếp và Phó HT.
class FakeWeeklyMenuSource implements WeeklyMenuSource {
  const FakeWeeklyMenuSource();

  static final weekStart = DateTime(2026, 10, 12);

  static const _breakfasts = [
    'Cháo thịt bằm · Sữa tươi',
    'Bún bò · Sữa chua',
    'Phở gà · Sữa tươi',
    'Bánh mì trứng · Sữa đậu nành',
    'Xôi gấc · Sữa tươi',
  ];
  static const _lunches = [
    'Cơm trắng · Canh bí đỏ nấu thịt · Cá basa sốt cà chua · Chuối',
    'Cơm trắng · Canh rau ngót · Thịt kho trứng cút · Dưa hấu',
    'Cơm trắng · Canh cải nấu tôm · Gà rim gừng · Thanh long',
    'Cơm trắng · Canh mồng tơi nấu cua · Đậu sốt thịt · Đu đủ',
    'Cơm trắng · Canh chua cá · Thịt bò xào · Cam',
  ];
  static const _snacks = [
    'Bánh flan · Nước cam',
    'Chè đậu xanh',
    'Sữa chua · Bánh quy',
    'Khoai lang luộc · Sữa tươi',
    'Bánh bông lan · Nước ép táo',
  ];
  static const _energy = [620, 605, 615, 598, 630];

  @override
  Future<WeeklyMenu> loadWeek(String childId) async {
    final hasAllergy = childId == 'child-2';
    return WeeklyMenu(
      weekStart: weekStart,
      days: [
        for (var i = 0; i < 5; i++)
          MenuDay(
            date: weekStart.add(Duration(days: i)),
            meals: [
              MenuMeal(name: 'Bữa sáng', time: '07:45', dishes: _breakfasts[i]),
              MenuMeal(name: 'Bữa trưa', time: '10:45', dishes: _lunches[i]),
              MenuMeal(name: 'Bữa chiều', time: '14:30', dishes: _snacks[i]),
            ],
            energyNote:
                'Năng lượng cả ngày: ${_energy[i]} kcal · đạt nhu cầu theo độ tuổi',
            allergyNote: hasAllergy
                ? 'Bé dị ứng hải sản · dùng suất thay thế cho món có cá, tôm, cua'
                : 'Bé không có dị ứng đã khai báo · dùng thực đơn chuẩn',
            allergyAlert: hasAllergy,
            // Chỉ hôm nay (12/10) đã có ảnh GV đăng
            photos: i == 0
                ? MealPhotoSet(
                    postedBy: hasAllergy ? 'Cô Thư' : 'Cô Hà',
                    postedAt: DateTime(2026, 10, 12, 11, 5),
                    slots: const ['Bữa sáng', 'Bữa trưa', 'Bữa chiều'],
                  )
                : null,
          ),
      ],
    );
  }
}

import 'package:carenest_app/features/parent_menu/data/fake_weekly_menu_source.dart';
import 'package:carenest_app/features/parent_menu/domain/weekly_menu.dart';
import 'package:carenest_app/features/school_menu/domain/school_menu.dart';

/// Thực đơn giả tuần 12–16/10, cùng món với màn Phụ huynh (P05) và có định lượng (mockup K02, H07).
/// Cơ sở chính: Mầm 51, Chồi 62, Lá 69 (khớp K03, tổng 182), không có lớp nhà trẻ.
/// Cơ sở 2: Nhà trẻ 22, Mầm 25, Chồi 26, Lá 57 (tổng 130 có mặt).
class FakeSchoolMenuSource implements SchoolMenuSource {
  const FakeSchoolMenuSource();

  static const groups = [
    ('nha-tre', 'Nhà trẻ'),
    ('mam', 'Mầm'),
    ('choi', 'Chồi'),
    ('la', 'Lá'),
  ];

  static const secondCampusId = 'campus-2';

  static const _ages = {
    'nha-tre': '2–3 tuổi',
    'mam': '3–4 tuổi',
    'choi': '4–5 tuổi',
    'la': '5–6 tuổi',
  };
  static const _counts = {'mam': 51, 'choi': 62, 'la': 69};
  static const _secondCounts = {'nha-tre': 22, 'mam': 25, 'choi': 26, 'la': 57};

  // Định lượng thứ Hai theo nhóm tuổi (mockup K02 cho nhóm Mầm)
  static const _mondayPortions = {
    'nha-tre': [
      'Cháo thịt bằm (200 ml) · Sữa tươi 150 ml',
      'Cơm nát 60 g · Canh rau ngọt · Thịt băm 30 g',
      'Bánh flan 1 cái · Nước cam 100 ml',
    ],
    'mam': [
      'Cháo thịt bằm (250 ml) · Sữa tươi 180 ml',
      'Cơm 80 g · Canh bí đỏ thịt · Cá basa sốt cà 45 g',
      'Bánh flan 1 cái · Nước cam 120 ml',
    ],
    'choi': [
      'Cháo thịt bằm (280 ml) · Sữa tươi 180 ml',
      'Cơm 90 g · Canh bí đỏ thịt · Cá basa sốt cà 50 g',
      'Bánh flan 1 cái · Nước cam 150 ml',
    ],
    'la': [
      'Cháo thịt bằm (300 ml) · Sữa tươi 200 ml',
      'Cơm 100 g · Canh bí đỏ thịt · Cá basa sốt cà 55 g',
      'Bánh flan 1 cái · Nước cam 150 ml',
    ],
  };

  static const _secondAlternatives = {
    'nha-tre': [
      AlternativeMenu(
        title: 'Dị ứng trứng',
        count: 1,
        swaps: [('Bánh flan', 'Sữa chua')],
        isAllergy: true,
      ),
    ],
    'mam': <AlternativeMenu>[],
    'choi': [
      AlternativeMenu(
        title: 'Ăn chay',
        count: 1,
        swaps: [('Canh thịt', 'Canh rau củ'), ('Cá', 'Đậu sốt cà')],
        isAllergy: false,
      ),
    ],
    'la': [
      AlternativeMenu(
        title: 'Dị ứng hải sản',
        count: 1,
        swaps: [('Cá basa sốt cà', 'Thịt gà rim')],
        isAllergy: true,
      ),
    ],
  };

  static const _alternatives = {
    'mam': [
      AlternativeMenu(
        title: 'Dị ứng hải sản',
        count: 1,
        swaps: [('Cá basa sốt cà', 'Thịt gà rim')],
        isAllergy: true,
      ),
    ],
    'choi': [
      AlternativeMenu(
        title: 'Dị ứng hải sản',
        count: 1,
        swaps: [('Cá basa sốt cà', 'Thịt gà rim')],
        isAllergy: true,
      ),
      AlternativeMenu(
        title: 'Ăn chay',
        count: 2,
        swaps: [('Canh thịt', 'Canh rau củ'), ('Cá', 'Đậu sốt cà')],
        isAllergy: false,
      ),
    ],
    'la': [
      AlternativeMenu(
        title: 'Dị ứng hải sản, sữa bò',
        count: 2,
        swaps: [
          ('Cá basa sốt cà', 'Thịt gà rim'),
          ('Sữa tươi', 'Sữa đậu nành'),
        ],
        isAllergy: true,
      ),
      AlternativeMenu(
        title: 'Ăn chay',
        count: 1,
        swaps: [('Canh thịt', 'Canh rau củ'), ('Cá', 'Đậu sốt cà')],
        isAllergy: false,
      ),
    ],
  };

  @override
  Future<SchoolMenuWeek> loadWeek(String campusId) async {
    final parentWeek = await const FakeWeeklyMenuSource().loadWeek('child-1');
    final second = campusId == secondCampusId;
    final counts = second ? _secondCounts : _counts;
    final alternatives = second ? _secondAlternatives : _alternatives;
    return SchoolMenuWeek(
      weekStart: FakeWeeklyMenuSource.weekStart,
      groups: groups,
      publishedNote: 'Đã duyệt & công bố · 09/10',
      nutritionSummary: second
          ? 'Năng lượng đạt chuẩn 4/4 nhóm tuổi'
          : 'Năng lượng đạt chuẩn 3/3 nhóm tuổi · Canxi nhóm Mầm còn thiếu',
      days: {
        for (final (i, day) in parentWeek.days.indexed)
          day.date: {
            for (final id in counts.keys)
              id: AgeGroupMenu(
                groupId: id,
                groupLabel: groups.firstWhere((g) => g.$1 == id).$2,
                ageRange: _ages[id]!,
                childCount: counts[id]!,
                meals: [
                  for (final (m, meal) in day.meals.indexed)
                    MenuMeal(
                      name: meal.name,
                      time: meal.time,
                      dishes: i == 0 ? _mondayPortions[id]![m] : meal.dishes,
                    ),
                ],
                alternatives: alternatives[id]!,
              ),
          },
      },
    );
  }
}

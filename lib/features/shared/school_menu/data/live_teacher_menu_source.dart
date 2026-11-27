import 'package:carenest_app/core/integration/api_dates.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/parent/parent_menu/domain/weekly_menu.dart';
import 'package:carenest_app/features/shared/school_menu/domain/school_menu.dart';

/// Thực đơn đã công bố của đúng lớp giáo viên phụ trách.
class LiveTeacherMenuSource implements SchoolMenuSource {
  LiveTeacherMenuSource(this._api, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final MobileApi _api;
  final DateTime Function() _clock;

  @override
  Future<SchoolMenuWeek> loadWeek(String classId) async {
    final now = _clock();
    final monday = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - DateTime.monday),
    );
    final data =
        await _api.json(
              'GET',
              '/classes/$classId/menu?weekStart=${apiDate(monday)}',
            )
            as Map? ??
        const {};
    final weekStart = DateTime.tryParse('${data['weekStart']}') ?? monday;
    final className = data['className']?.toString() ?? 'Lớp';
    final published = data['published'] == true;
    final days = <DateTime, Map<String, AgeGroupMenu>>{};
    for (final raw in (data['days'] as List? ?? const []).whereType<Map>()) {
      final date = DateTime.tryParse('${raw['date']}');
      if (date == null) continue;
      final meals = <MenuMeal>[];
      for (final meal in (raw['meals'] as List? ?? const []).whereType<Map>()) {
        final dishes = (meal['dishes'] as List? ?? const [])
            .map((dish) => dish.toString())
            .where((dish) => dish.isNotEmpty)
            .join(' · ');
        if (dishes.isEmpty) continue;
        final session = meal['session']?.toString() ?? '';
        meals.add(
          MenuMeal(
            name: _mealName(session),
            time: _mealTime(session),
            dishes: dishes,
          ),
        );
      }
      days[date] = {
        classId: AgeGroupMenu(
          groupId: classId,
          groupLabel: className,
          ageRange: '',
          childCount: 0,
          meals: meals,
        ),
      };
    }
    return SchoolMenuWeek(
      weekStart: weekStart,
      groups: [(classId, className)],
      days: days,
      publishedNote: published ? 'Đã công bố' : 'Chưa có thực đơn',
    );
  }

  static String _mealName(String session) => switch (session) {
    'MORNING' => 'Bữa sáng',
    'LUNCH' => 'Bữa trưa',
    'AFTERNOON' => 'Bữa xế',
    _ => 'Bữa ăn',
  };

  static String _mealTime(String session) => switch (session) {
    'MORNING' => 'Sáng',
    'LUNCH' => 'Trưa',
    'AFTERNOON' => 'Chiều',
    _ => '',
  };
}

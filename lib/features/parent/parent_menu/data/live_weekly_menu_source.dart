import 'dart:typed_data';

import 'package:carenest_app/core/integration/api_dates.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/parent/parent_menu/domain/weekly_menu.dart';

/// Thực đơn tuần của bé từ BE (PAR-14): `GET /children/{id}/menu?weekStart=`; ảnh bữa qua
/// `GET /children/{id}/meal-photos/{photoId}/content` (có token, không lưu ra máy).
class LiveWeeklyMenuSource implements WeeklyMenuSource {
  LiveWeeklyMenuSource(this._api);

  final MobileApi _api;

  @override
  Future<WeeklyMenu> loadWeek(String childId, {DateTime? weekStart}) async {
    final query = weekStart == null ? '' : '?weekStart=${apiDate(weekStart)}';
    final data = await _api.json('GET', '/children/$childId/menu$query') as Map;
    return WeeklyMenu(
      weekStart: DateTime.parse('${data['weekStart']}'),
      published: data['published'] == true,
      mealsHidden: data['mealsHidden'] == true,
      unmatchedAllergies: [
        for (final name in data['unmatchedAllergies'] as List? ?? const [])
          '$name',
      ],
      days: [
        for (final day in _maps(data['days']))
          MenuDay(
            date: DateTime.parse('${day['date']}'),
            enrolled: day['enrolled'] != false,
            dayOff: day['dayOff'] == true,
            meals: [
              for (final session in MenuSession.values)
                for (final meal in _maps(day['meals']))
                  if (MenuSession.fromCode(meal['session']) == session)
                    MenuMealEntry(
                      session: session,
                      dishes: [
                        for (final dish in _maps(meal['dishes']))
                          MenuDish(
                            name: '${dish['name'] ?? ''}',
                            allergens: _names(dish['allergens']),
                            childAllergens: _names(dish['childAllergens']),
                          ),
                      ],
                      photo: switch (meal['photo']) {
                        final Map photo => MenuPhoto(
                          photoId: '${photo['photoId']}',
                          uploadedAt: DateTime.parse(
                            '${photo['uploadedAt']}',
                          ).toLocal(),
                        ),
                        _ => null,
                      },
                    ),
            ],
          ),
      ],
    );
  }

  @override
  Future<Uint8List?> loadPhoto(String childId, String photoId) =>
      _api.binary('/children/$childId/meal-photos/$photoId/content');

  static Iterable<Map> _maps(Object? value) =>
      (value as List? ?? const []).whereType<Map>();

  static List<String> _names(Object? value) => [
    for (final item in _maps(value)) '${item['name'] ?? ''}',
  ];
}

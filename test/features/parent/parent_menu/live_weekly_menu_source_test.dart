import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/parent/parent_menu/data/live_weekly_menu_source.dart';
import 'package:carenest_app/features/parent/parent_menu/domain/weekly_menu.dart';

import '../../../helpers/live_fakes.dart';

/// Dữ liệu giả đúng contract `GET /children/{id}/menu` (BE PAR-14).
Map<String, Object?> menuJson({
  bool published = true,
  bool mealsHidden = false,
}) => {
  'childId': 5,
  'weekStart': '2026-11-23',
  'published': published,
  'mealsHidden': mealsHidden,
  'unmatchedAllergies': ['Dâu tây'],
  'days': [
    {
      'date': '2026-11-23',
      'enrolled': true,
      'dayOff': false,
      'meals': [
        {
          'session': 'AFTERNOON',
          'dishes': [
            {
              'name': 'Sữa chua',
              'allergens': <Object>[],
              'childAllergens': <Object>[],
            },
          ],
          'photo': null,
        },
        {
          'session': 'LUNCH',
          'dishes': [
            {
              'name': 'Cá sốt cà chua',
              'allergens': [
                {'id': 4, 'code': 'FISH', 'name': 'Cá'},
                {'id': 7, 'code': 'SOY', 'name': 'Đậu nành'},
              ],
              'childAllergens': [
                {'id': 4, 'code': 'FISH', 'name': 'Cá'},
              ],
            },
          ],
          'photo': {'photoId': 10, 'uploadedAt': '2026-11-23T04:05:00Z'},
        },
      ],
    },
    {
      'date': '2026-11-24',
      'enrolled': true,
      'dayOff': true,
      'meals': <Object>[],
    },
    {
      'date': '2026-11-25',
      'enrolled': false,
      'dayOff': false,
      'meals': <Object>[],
    },
  ],
};

class _PhotoApi extends ScriptedApi {
  _PhotoApi(super.session, super.routes);

  final binaryCalls = <String>[];

  @override
  Future<Uint8List> binary(String path) async {
    binaryCalls.add(path);
    return Uint8List.fromList([1, 2, 3]);
  }
}

void main() {
  late FakeLiveSession session;

  setUp(() => session = FakeLiveSession(['PARENT'], childIds: [5]));

  test(
    'map tuần: bữa theo thứ tự, món, chất dị ứng của bé, ảnh, cờ ngày',
    () async {
      final api = ScriptedApi(session, {
        'GET /children/5/menu': (_) => menuJson(),
      });
      final week = await LiveWeeklyMenuSource(api).loadWeek('5');

      expect(week.weekStart, DateTime(2026, 11, 23));
      expect(week.published, isTrue);
      expect(week.unmatchedAllergies, ['Dâu tây']);
      final monday = week.days.first;
      expect(monday.meals.map((m) => m.session), [
        MenuSession.lunch,
        MenuSession.afternoon,
      ]);
      final fish = monday.meals.first.dishes.single;
      expect(fish.name, 'Cá sốt cà chua');
      expect(fish.allergens, ['Cá', 'Đậu nành']);
      expect(fish.childAllergens, ['Cá']);
      expect(monday.meals.first.photo!.photoId, '10');
      expect(monday.meals.last.photo, isNull);
      expect(week.days[1].dayOff, isTrue);
      expect(week.days[2].enrolled, isFalse);
    },
  );

  test(
    'có weekStart ⇒ gửi theo tuần; mealsHidden, chưa công bố giữ cờ BE',
    () async {
      final api = ScriptedApi(session, {
        'GET /children/5/menu?weekStart=2026-11-30': (_) =>
            menuJson(published: false, mealsHidden: true),
      });
      final week = await LiveWeeklyMenuSource(
        api,
      ).loadWeek('5', weekStart: DateTime(2026, 11, 30));
      expect(week.published, isFalse);
      expect(week.mealsHidden, isTrue);
    },
  );

  test('ảnh tải qua /content của bé', () async {
    final api = _PhotoApi(session, {});
    final bytes = await LiveWeeklyMenuSource(api).loadPhoto('5', '10');
    expect(bytes, [1, 2, 3]);
    expect(api.binaryCalls, ['/children/5/meal-photos/10/content']);
  });

  test('lỗi BE đi thẳng ra màn', () async {
    final api = ScriptedApi(session, {});
    expect(LiveWeeklyMenuSource(api).loadWeek('5'), throwsA(isA<ApiFailure>()));
  });
}

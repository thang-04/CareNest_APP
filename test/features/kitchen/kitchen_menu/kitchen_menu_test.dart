import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/theme/app_theme.dart';
import 'package:carenest_app/features/kitchen/kitchen_menu/data/live_kitchen_menu_source.dart';
import 'package:carenest_app/features/kitchen/kitchen_menu/domain/kitchen_menu.dart';
import 'package:carenest_app/features/kitchen/kitchen_menu/presentation/screens/kitchen_menu_screen.dart';

import '../../../helpers/live_fakes.dart';
import '../../../helpers/pump_app.dart';

Map<String, Object?> _day(String date, {String status = 'PUBLISHED'}) => {
  'date': date,
  'dayOff': false,
  'menuStatus': status,
  'menu': status != 'PUBLISHED'
      ? <Object>[]
      : [
          {
            'session': 'LUNCH',
            'menuBlock': 'NURSERY',
            'dishes': [
              {'id': 2, 'code': 'D2', 'name': 'Cháo thịt bằm'},
            ],
          },
          {
            'session': 'LUNCH',
            'menuBlock': 'KINDERGARTEN',
            'dishes': [
              {'id': 3, 'code': 'D3', 'name': 'Cơm trắng'},
              {
                'id': 4,
                'code': 'D4',
                'name': 'Cá basa sốt cà',
                'allergens': [
                  {'id': 2, 'code': 'FISH', 'name': 'Cá'},
                ],
                'allergyWarnings': [
                  {
                    'allergen': {'id': 2, 'code': 'FISH', 'name': 'Cá'},
                    'byClass': [
                      {'classroomId': 11, 'classroomName': 'Mầm 1', 'count': 2},
                    ],
                  },
                ],
              },
            ],
          },
          {
            'session': 'MORNING',
            'menuBlock': 'NURSERY',
            'dishes': [
              {'id': 1, 'code': 'D1', 'name': 'Sữa chua'},
            ],
          },
        ],
  'servings': <Object>[],
  'foods': <Object>[],
  'unmatchedAllergies': [
    {
      'name': 'Hạt điều',
      'byClass': [
        {'classroomId': 11, 'classroomName': 'Mầm 1', 'count': 1},
      ],
    },
  ],
};

void main() {
  late FakeLiveSession session;
  setUp(() => session = FakeLiveSession(['KITCHEN_STAFF']));

  group('LiveKitchenMenuSource (NUT-08, NUT-13)', () {
    test('today_sessionsInServiceOrder_dishesByBlock', () async {
      final day = await LiveKitchenMenuSource(
        ScriptedApi(session, {
          'GET /nutrition/kitchen/day': (_) => _day('2026-11-25'),
        }),
      ).loadDay();
      expect(day.date, DateTime(2026, 11, 25));
      expect(day.published, isTrue);
      expect(day.sessions.map((s) => s.label), ['Bữa phụ sáng', 'Bữa trưa']);
      final lunch = day.sessions.last;
      expect(lunch.blocks.map((b) => b.label), ['Nhà trẻ', 'Mẫu giáo']);
      expect(lunch.blocks.last.dishes.map((d) => d.name), [
        'Cơm trắng',
        'Cá basa sốt cà',
      ]);
      final fish = lunch.blocks.last.dishes.last;
      expect(fish.allergens, ['Cá']);
      expect(fish.warnings.single.allergen, 'Cá');
      expect(fish.warnings.single.byClass, ['Mầm 1: 2 trẻ']);
      expect(day.unmatched, ['Hạt điều — Mầm 1: 1 trẻ']);
    });

    test('otherDay_sendsDate_draftWeekNotPublished', () async {
      final api = ScriptedApi(session, {
        'GET /nutrition/kitchen/day?date=2026-11-27': (_) =>
            _day('2026-11-27', status: 'DRAFT'),
      });
      final day = await LiveKitchenMenuSource(
        api,
      ).loadDay(DateTime(2026, 11, 27));
      expect(day.published, isFalse);
      expect(day.sessions, isEmpty);
    });
  });

  group('KitchenMenuScreen', () {
    Future<void> pump(WidgetTester tester, KitchenMenuSource source) async {
      usePhoneSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(body: KitchenMenuScreen(source: source)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('NUT-13: món theo bữa và khối, đổi ngày trong tuần', (
      tester,
    ) async {
      final api = ScriptedApi(session, {
        'GET /nutrition/kitchen/day': (_) => _day('2026-11-25'),
        'GET /nutrition/kitchen/day?date=2026-11-27': (_) =>
            _day('2026-11-27', status: 'DRAFT'),
      });
      await pump(tester, LiveKitchenMenuSource(api));
      expect(find.text('Thực đơn'), findsOneWidget);
      expect(find.text('Bữa trưa'), findsOneWidget);
      expect(find.text('Mẫu giáo'), findsOneWidget);
      expect(find.text('Cá basa sốt cà'), findsOneWidget);
      expect(find.text('Có Cá · Mầm 1: 2 trẻ'), findsOneWidget);
      expect(find.textContaining('Hạt điều'), findsOneWidget);

      // Thứ Sáu 27/11 trong dải ngày tuần 23–27/11
      await tester.tap(find.text('27/11'));
      await tester.pumpAndSettle();
      expect(api.calls, contains('GET /nutrition/kitchen/day?date=2026-11-27'));
      expect(find.text('Thực đơn tuần này chưa công bố'), findsOneWidget);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/kitchen/food_quantities/data/live_food_quantity_source.dart';
import 'package:carenest_app/features/kitchen/food_quantities/domain/food_quantities.dart';
import 'package:carenest_app/features/kitchen/kitchen_home/data/live_kitchen_home_source.dart';
import 'package:carenest_app/features/kitchen/kitchen_home/domain/kitchen_today.dart';
import 'package:carenest_app/features/kitchen/kitchen_meals/data/live_kitchen_meals_source.dart';

import '../../../helpers/live_fakes.dart';

/// `GET /nutrition/kitchen/day` giả: bữa phụ sáng chỉ Nhà trẻ, trưa cả hai khối.
Map<String, Object?> _day({bool dayOff = false}) => {
  'campusId': 1,
  'date': '2026-11-25',
  'dayOff': dayOff,
  'menuStatus': 'PUBLISHED',
  'countStatus': 'CONFIRMED',
  'confirmedAt': '2026-11-25T01:30:00Z',
  'menu': [
    {
      'session': 'MORNING',
      'menuBlock': 'NURSERY',
      'dishes': [
        {'id': 1, 'code': 'D1', 'name': 'Sữa chua'},
      ],
    },
    {
      'session': 'LUNCH',
      'menuBlock': 'NURSERY',
      'dishes': [
        {'id': 2, 'code': 'D2', 'name': 'Cháo thịt'},
      ],
    },
    {
      'session': 'LUNCH',
      'menuBlock': 'KINDERGARTEN',
      'dishes': [
        {'id': 3, 'code': 'D3', 'name': 'Cơm, cá kho'},
      ],
    },
  ],
  'servings': [
    {
      'session': 'LUNCH',
      'classroomId': 11,
      'classroomName': 'Mầm 1',
      'normal': 20,
      'substitute': 2,
    },
    {
      'session': 'LUNCH',
      'classroomId': 12,
      'classroomName': 'Nhà trẻ 1',
      'normal': 15,
      'substitute': 0,
    },
    {
      'session': 'MORNING',
      'classroomId': 12,
      'classroomName': 'Nhà trẻ 1',
      'normal': 15,
      'substitute': 0,
    },
  ],
  'foods': [
    {
      'food': {
        'id': 5,
        'code': 'F5',
        'name': 'Cá basa phi lê',
        'unit': 'g',
        'purchaseUnit': 'kg',
        'purchaseUnitSize': 1000,
      },
      'storage': 'FRESH',
      'quantity': 10500,
    },
    {
      'food': {
        'id': 6,
        'code': 'F6',
        'name': 'Gạo tẻ',
        'unit': 'kg',
        'purchaseUnit': null,
        'purchaseUnitSize': null,
      },
      'storage': 'DRY',
      'quantity': 12.25,
    },
  ],
};

Map<String, Object?> _count(
  String session, {
  int normal = 0,
  int substitute = 0,
  String status = 'CONFIRMED',
  bool reconfirm = false,
}) => {
  'session': session,
  'status': status,
  'needsReconfirmation': reconfirm,
  'confirmedAt': '2026-11-25T01:30:00Z',
  'totals': {'normal': normal, 'substitute': substitute},
};

ScriptedApi _api(
  FakeLiveSession session, {
  Map<String, Object?>? day,
  List<Map<String, Object?>>? counts,
}) => ScriptedApi(session, {
  'GET /nutrition/kitchen/day': (_) => day ?? _day(),
  'GET /meal-counts': (_) => {
    'date': '2026-11-25',
    'today': '2026-11-25',
    'schoolDay': true,
    'counts':
        counts ??
        [
          _count('MORNING', normal: 15),
          _count('LUNCH', normal: 35, substitute: 2),
        ],
  },
});

void main() {
  late FakeLiveSession session;
  setUp(() => session = FakeLiveSession(['KITCHEN_STAFF']));

  group('LiveKitchenHomeSource (NUT-02, NUT-03)', () {
    test('confirmedSessions_useBeTotals_andBlockNote', () async {
      final today = await LiveKitchenHomeSource(_api(session)).loadToday();
      expect(today.date, DateTime(2026, 11, 25));
      expect(today.countStatus, KitchenCountStatus.confirmed);
      expect(today.servings.map((s) => s.session), ['MORNING', 'LUNCH']);
      final morning = today.servings.first;
      expect(morning.label, 'Bữa phụ sáng');
      expect(morning.total, 15);
      expect(morning.blockNote, 'Nhà trẻ');
      final lunch = today.servings.last;
      expect(lunch.total, 37);
      expect(lunch.substitute, 2);
      expect(lunch.blockNote, isNull);
    });

    test('sessionWaitingReconfirmation_isHidden', () async {
      final today = await LiveKitchenHomeSource(
        _api(
          session,
          counts: [
            _count('MORNING', normal: 15),
            _count('LUNCH', normal: 40, substitute: 2, reconfirm: true),
          ],
        ),
      ).loadToday();
      expect(today.servings.map((s) => s.session), ['MORNING']);
    });

    test('dayOff_isPassedThrough', () async {
      final today = await LiveKitchenHomeSource(
        _api(session, day: _day(dayOff: true), counts: const []),
      ).loadToday();
      expect(today.isDayOff, isTrue);
      expect(today.servings, isEmpty);
    });
  });

  group('LiveKitchenMealsSource (NUT-17, AUTH-05)', () {
    test('classesGroupedBySession_withBeTotals', () async {
      final sheet = await LiveKitchenMealsSource(_api(session)).loadSheet();
      expect(sheet, isNotNull);
      expect(sheet!.sessions.map((s) => s.session), ['MORNING', 'LUNCH']);
      final lunch = sheet.sessions.last;
      expect(lunch.classes.map((c) => c.className), ['Mầm 1', 'Nhà trẻ 1']);
      expect(lunch.classes.first.regular, 20);
      expect(lunch.classes.first.alternative, 2);
      expect(lunch.total, 37);
      expect(lunch.regular, 35);
      expect(lunch.alternative, 2);
    });

    test('noConfirmedSession_isNull', () async {
      final sheet = await LiveKitchenMealsSource(
        _api(
          session,
          day: {..._day(), 'countStatus': 'NONE', 'servings': <Object>[]},
          counts: [_count('LUNCH', status: 'PENDING_CONFIRMATION')],
        ),
      ).loadSheet();
      expect(sheet, isNull);
    });
  });

  group('LiveFoodQuantitySource (NUT-01)', () {
    test('formatsPurchaseUnit_andStorage', () async {
      final day = await LiveFoodQuantitySource(_api(session)).loadDay();
      expect(day, isNotNull);
      expect(day!.needs.first.food, 'Cá basa phi lê');
      expect(day.needs.first.amount, '10,5 kg');
      expect(day.needs.first.storage, FoodStorage.fresh);
      expect(day.needs.last.amount, '12,25 kg');
      expect(day.needs.last.storage, FoodStorage.dry);
    });

    test('noFoods_isNull', () async {
      final day = await LiveFoodQuantitySource(
        _api(session, day: {..._day(), 'foods': <Object>[]}),
      ).loadDay();
      expect(day, isNull);
    });
  });
}

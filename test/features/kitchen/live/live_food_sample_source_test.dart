import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/kitchen/food_samples/data/live_food_sample_source.dart';
import 'package:carenest_app/features/kitchen/food_samples/domain/food_samples.dart';

import '../../../helpers/live_fakes.dart';

const _today = '2026-11-25';

Map<String, Object?> _sample(
  int id, {
  String date = _today,
  String session = 'LUNCH',
  String status = 'RECORDED',
  String disposal = 'NONE',
  bool editable = true,
  String disposableFrom = '2026-11-26T04:00:00Z',
}) => {
  'id': id,
  'campusId': 1,
  'date': date,
  'session': session,
  'sampledAt': '2026-11-25T04:00:00Z',
  'dishes': [
    {
      'id': 3,
      'code': 'D3',
      'name': 'Cơm, cá kho',
      'weight': '150 g',
      'container': 'Hộp inox',
      'temperature': '',
    },
  ],
  'status': status,
  'disposableFrom': disposableFrom,
  'disposalStatus': disposal,
  'editable': editable,
};

Map<String, Object?> _kitchenDay() => {
  'date': _today,
  'dayOff': false,
  'menu': [
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
  'servings': <Object>[],
  'foods': <Object>[],
};

void main() {
  late FakeLiveSession session;
  setUp(() => session = FakeLiveSession(['KITCHEN_STAFF']));

  ScriptedApi api(List<Map<String, Object?>> samples) => ScriptedApi(session, {
    'GET /nutrition/kitchen/day': (_) => _kitchenDay(),
    'GET /meal-counts': (_) => {'today': _today, 'counts': <Object>[]},
    'GET /nutrition/food-samples?from=2026-10-26&to=2026-11-25': (_) => samples,
  });

  test('loadToday_mapsMenuTodaySampleAndPastToDispose (NUT-21)', () async {
    final day = await LiveFoodSampleSource(
      api([
        _sample(9, editable: false),
        _sample(7, date: '2026-11-24', disposableFrom: '2026-11-25T03:00:00Z'),
        _sample(5, date: '2026-11-20', disposal: 'APPROVED'),
      ]),
      clock: () => DateTime.utc(2026, 11, 25, 5),
    ).loadToday();

    expect(day.date, DateTime(2026, 11, 25));
    final lunch = day.sessions.single;
    expect(lunch.label, 'Bữa trưa');
    expect(lunch.dishes.map((d) => d.name), ['Cháo thịt', 'Cơm, cá kho']);
    expect(lunch.dishes.first.blockLabel, 'Nhà trẻ');
    expect(lunch.sample?.id, 9);
    // Cờ `editable` lấy từ BE, App không tự suy
    expect(lunch.sample?.editable, isFalse);
    expect(lunch.sample?.dishes.single.weight, '150 g');
    // Mẫu đã PHT duyệt hủy thì xong; mẫu hôm qua đã qua mốc hủy
    expect(day.toDispose.map((s) => s.id), [7]);
    expect(day.toDispose.single.disposableNow, isTrue);
  });

  test('saveSample_new_postsDishesAndNotes', () async {
    final scripted = api(const []);
    Object? sent;
    scripted.routes['POST /nutrition/food-samples'] = (body) {
      sent = body;
      return _sample(10);
    };
    final source = LiveFoodSampleSource(scripted);
    await source.loadToday();
    await source.saveSample(
      session: 'LUNCH',
      dishes: const [
        DishNoteInput(
          dishId: 3,
          weight: '150 g',
          container: 'Hộp inox',
          temperature: '',
        ),
      ],
    );
    expect(sent, {
      'date': _today,
      'session': 'LUNCH',
      'dishIds': [2, 3],
      'dishDetails': [
        {
          'dishId': 3,
          'weight': '150 g',
          'container': 'Hộp inox',
          'temperature': '',
        },
      ],
    });
  });

  test('saveSample_existing_putsById', () async {
    final scripted = api([_sample(9)]);
    scripted.routes['PUT /nutrition/food-samples/9'] = (_) => _sample(9);
    await LiveFoodSampleSource(
      scripted,
    ).saveSample(session: 'LUNCH', sampleId: 9, dishes: const []);
    expect(scripted.calls, contains('PUT /nutrition/food-samples/9'));
  });

  test('recordDisposal_postsDispose', () async {
    final scripted = api([_sample(7, date: '2026-11-24')]);
    scripted.routes['POST /nutrition/food-samples/7/dispose'] = (_) =>
        _sample(7, date: '2026-11-24', disposal: 'RECORDED');
    await LiveFoodSampleSource(scripted).recordDisposal(7);
    expect(scripted.calls, contains('POST /nutrition/food-samples/7/dispose'));
  });

  test('recordDisposal_tooEarly_surfacesBeMessage', () async {
    final scripted = api([_sample(7, date: '2026-11-24')]);
    scripted.routes['POST /nutrition/food-samples/7/dispose'] = (_) =>
        throw ApiFailure(400, 'Chưa đủ 24 giờ kể từ lúc lấy mẫu', 6062);
    expect(
      () => LiveFoodSampleSource(scripted).recordDisposal(7),
      throwsA(isA<ApiFailure>().having((f) => f.errorCode, 'errorCode', 6062)),
    );
  });
}

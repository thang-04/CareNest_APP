import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/kitchen/meal_photos/data/live_kitchen_photo_source.dart';
import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';

import '../../../helpers/live_fakes.dart';

/// API giả ghi lại lần đăng ảnh multipart.
class _PhotoApi extends ScriptedApi {
  _PhotoApi(super.session, super.routes);

  String? uploadedPath;
  String? uploadedField;
  Uint8List? uploaded;

  @override
  Future<Object?> multipart(
    String method,
    String path, {
    required String field,
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    uploadedPath = '$method $path';
    uploadedField = field;
    uploaded = bytes;
    return {'id': 21, 'session': 'LUNCH'};
  }

  @override
  Future<Uint8List> binary(String path) async {
    calls.add('BINARY $path');
    return Uint8List.fromList([1, 2, 3]);
  }
}

void main() {
  late FakeLiveSession session;
  setUp(() => session = FakeLiveSession(['KITCHEN_STAFF']));

  _PhotoApi api({List<Map<String, Object?>> photos = const []}) => _PhotoApi(
    session,
    {
      'GET /nutrition/kitchen/day': (_) => {
        'date': '2026-11-25',
        'dayOff': false,
        'menu': [
          {'session': 'MORNING', 'menuBlock': 'NURSERY', 'dishes': []},
          {'session': 'LUNCH', 'menuBlock': 'KINDERGARTEN', 'dishes': []},
        ],
        'servings': <Object>[],
        'foods': <Object>[],
      },
      'GET /meal-counts': (_) => {'today': '2026-11-25', 'counts': <Object>[]},
      'GET /nutrition/meal-photo-windows': (_) => [
        {'session': 'MORNING', 'startTime': '07:30:00', 'endTime': '08:30:00'},
        {'session': 'LUNCH', 'startTime': '10:30:00', 'endTime': '11:30:00'},
      ],
      'GET /nutrition/meal-photos?date=2026-11-25': (_) => photos,
    },
  );

  test('loadToday_onePhotoPerMeal_windowByDeviceClock (NUT-16)', () async {
    final day = await LiveKitchenPhotoSource(
      api(
        photos: [
          {
            'id': 9,
            'campusId': 1,
            'date': '2026-11-25',
            'session': 'MORNING',
            'uploadedAt': '2026-11-25T00:52:00Z',
          },
        ],
      ),
      clock: () => DateTime(2026, 11, 25, 10, 50),
    ).loadToday();

    expect(day.meals.map((m) => m.id), ['MORNING', 'LUNCH']);
    final morning = day.meals.first;
    expect(morning.name, 'Bữa phụ sáng');
    expect(morning.window, PhotoWindow.closed);
    expect(morning.photos.single.id, '9');
    expect(morning.status, MealPhotoStatus.done);
    final lunch = day.meals.last;
    expect(lunch.window, PhotoWindow.open);
    expect(lunch.opensAt, '10:30');
    expect(lunch.closesAt, '11:30');
    expect(lunch.minutesLeft, 40);
    expect(lunch.status, MealPhotoStatus.needed);
  });

  test('loadToday_noWindow_isNotSet', () async {
    final scripted = api();
    scripted.routes['GET /nutrition/meal-photo-windows'] = (_) => <Object>[];
    final day = await LiveKitchenPhotoSource(
      scripted,
      clock: () => DateTime(2026, 11, 25, 10, 50),
    ).loadToday();
    expect(day.meals.every((m) => m.window == PhotoWindow.notSet), isTrue);
  });

  test('addPhoto_postsMultipartWithSession', () async {
    final scripted = api();
    await LiveKitchenPhotoSource(
      scripted,
      clock: () => DateTime(2026, 11, 25, 10, 50),
    ).addPhoto(mealId: 'LUNCH', bytes: Uint8List.fromList([9]));
    expect(scripted.uploadedPath, 'POST /nutrition/meal-photos?session=LUNCH');
    expect(scripted.uploadedField, 'file');
    expect(scripted.uploaded, [9]);
  });

  test('loadPhoto_readsContentWithAuth', () async {
    final scripted = api();
    final bytes = await LiveKitchenPhotoSource(scripted).loadPhoto('9');
    expect(bytes, [1, 2, 3]);
    expect(scripted.calls, contains('BINARY /nutrition/meal-photos/9/content'));
  });

  test('addPhoto_outsideWindow_surfacesBeError', () async {
    final scripted = _FailingUploadApi(session, api().routes);
    expect(
      () => LiveKitchenPhotoSource(
        scripted,
      ).addPhoto(mealId: 'LUNCH', bytes: Uint8List.fromList([9])),
      throwsA(isA<ApiFailure>()),
    );
  });
}

class _FailingUploadApi extends ScriptedApi {
  _FailingUploadApi(super.session, super.routes);

  @override
  Future<Object?> multipart(
    String method,
    String path, {
    required String field,
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async => throw ApiFailure(400, 'Ngoài giờ đăng ảnh bữa này', 6065);
}

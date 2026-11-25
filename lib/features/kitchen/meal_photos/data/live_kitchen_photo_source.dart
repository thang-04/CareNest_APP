import 'dart:typed_data';

import 'package:carenest_app/core/integration/api_dates.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';
import 'package:carenest_app/features/kitchen/shared/kitchen_day_api.dart';

/// Ảnh mẫu từ BE (NUT-16): 1 ảnh mỗi điểm trường × ngày × bữa (`GET /nutrition/meal-photos?date`),
/// đăng lại là thay (`POST` multipart `file` + `session`), giờ đăng `GET /nutrition/meal-photo-windows`.
/// Bữa cần chụp = bữa có trong thực đơn đã công bố hoặc sổ báo ăn hôm nay.
class LiveKitchenPhotoSource implements KitchenPhotoSource {
  LiveKitchenPhotoSource(this._api, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final MobileApi _api;
  final DateTime Function() _clock;

  @override
  Future<KitchenPhotoDay> loadToday() async {
    final data = await KitchenDayData.load(_api);
    final date = data.date;
    final results = await Future.wait([
      _api.json('GET', '/nutrition/meal-photo-windows'),
      _api.json('GET', '/nutrition/meal-photos?date=${apiDate(date)}'),
    ]);
    final windows = {
      for (final window in KitchenDayData.maps(results[0]))
        '${window['session']}': window,
    };
    final photos = {
      for (final photo in KitchenDayData.maps(results[1]))
        '${photo['session']}': photo,
    };
    final eaten = {
      for (final menu in KitchenDayData.maps(data.day['menu']))
        '${menu['session']}',
      for (final count in KitchenDayData.maps(data.counts['counts']))
        '${count['session']}',
    };
    // Thực đơn chưa công bố và chưa có sổ báo ăn: hiện mọi bữa có giờ đăng
    final sessions = eaten.isEmpty ? windows.keys.toSet() : eaten;
    return KitchenPhotoDay(
      date: date,
      // BE chưa trả tên điểm trường cho bếp ⇒ ẩn
      campusLabel: '',
      isDayOff: data.dayOff,
      meals: [
        for (final session in kitchenSessionOrder)
          if (sessions.contains(session))
            _meal(session, windows[session], photos[session], date),
      ],
    );
  }

  @override
  Future<KitchenPhotoDay> addPhoto({
    required String mealId,
    required Uint8List bytes,
  }) async {
    await _api.multipart(
      'POST',
      '/nutrition/meal-photos?session=$mealId',
      field: 'file',
      bytes: bytes,
      filename: 'meal-$mealId.jpg',
      contentType: 'image/jpeg',
    );
    return loadToday();
  }

  @override
  Future<Uint8List> loadPhoto(String photoId) =>
      _api.binary('/nutrition/meal-photos/$photoId/content');

  SampleMeal _meal(
    String session,
    Map<Object?, Object?>? window,
    Map<Object?, Object?>? photo,
    DateTime date,
  ) {
    final opens = _time(window?['startTime']);
    final closes = _time(window?['endTime']);
    // Giờ điện thoại chỉ để hiển thị (user 25/11); BE chặn đăng ngoài giờ
    final now = _clock();
    final start = opens == null ? null : _at(date, opens);
    final end = closes == null ? null : _at(date, closes);
    final state = start == null || end == null
        ? PhotoWindow.notSet
        : now.isBefore(start)
        ? PhotoWindow.upcoming
        : now.isAfter(end)
        ? PhotoWindow.closed
        : PhotoWindow.open;
    return SampleMeal(
      id: session,
      name: kitchenSessionLabels[session] ?? '',
      window: state,
      opensAt: opens,
      closesAt: closes,
      minutesLeft: state == PhotoWindow.open
          ? end!.difference(now).inMinutes
          : null,
      photos: [
        if (photo != null)
          SamplePhoto(
            id: '${photo['id']}',
            postedAt: _hhmm(DateTime.parse('${photo['uploadedAt']}').toLocal()),
          ),
      ],
    );
  }

  /// "07:30:00" ⇒ "07:30"
  static String? _time(Object? value) => switch (value) {
    final String text when text.length >= 5 => text.substring(0, 5),
    _ => null,
  };

  static DateTime _at(DateTime date, String hhmm) => DateTime(
    date.year,
    date.month,
    date.day,
    int.parse(hhmm.substring(0, 2)),
    int.parse(hhmm.substring(3, 5)),
  );

  static String _hhmm(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}

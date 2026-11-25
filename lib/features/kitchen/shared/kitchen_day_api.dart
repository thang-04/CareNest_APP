import 'package:carenest_app/core/integration/mobile_api.dart';

/// Nhãn buổi như Web (BE `MealSession`).
const kitchenSessionLabels = {
  'MORNING': 'Bữa phụ sáng',
  'LUNCH': 'Bữa trưa',
  'AFTERNOON': 'Bữa chiều',
};

/// Thứ tự phục vụ (BE `MealSession`).
const kitchenSessionOrder = ['MORNING', 'LUNCH', 'AFTERNOON'];

/// Nhãn khối thực đơn (BE `MenuBlock`, NUT-13).
const kitchenBlockLabels = {'NURSERY': 'Nhà trẻ', 'KINDERGARTEN': 'Mẫu giáo'};

/// Một ngày bếp hôm nay (ngày máy chủ): `GET /nutrition/kitchen/day` + `GET /meal-counts`.
/// Bếp chỉ thấy điểm trường của tài khoản (BE `KitchenAccess`), không cần gửi điểm trường.
class KitchenDayData {
  const KitchenDayData({required this.day, required this.counts});

  final Map<Object?, Object?> day;
  final Map<Object?, Object?> counts;

  static Future<KitchenDayData> load(MobileApi api) async {
    final results = await Future.wait([
      api.json('GET', '/nutrition/kitchen/day'),
      api.json('GET', '/meal-counts'),
    ]);
    return KitchenDayData(
      day: results[0] as Map? ?? const {},
      counts: results[1] as Map? ?? const {},
    );
  }

  /// Ngày máy chủ (`/meal-counts.today`), không theo giờ điện thoại.
  DateTime get date =>
      _date(counts['today']) ?? _date(day['date']) ?? DateTime.now();

  bool get dayOff => day['dayOff'] == true;

  /// Bữa đã xác nhận và không chờ xác nhận lại (NUT-02, NUT-03), theo thứ tự phục vụ.
  List<Map<Object?, Object?>> get confirmedCounts {
    final confirmed = [
      for (final count in maps(counts['counts']))
        if (count['status'] == 'CONFIRMED' &&
            count['needsReconfirmation'] != true)
          count,
    ];
    confirmed.sort(
      (a, b) => kitchenSessionOrder
          .indexOf('${a['session']}')
          .compareTo(kitchenSessionOrder.indexOf('${b['session']}')),
    );
    return confirmed;
  }

  /// Khối ăn bữa [session] theo thực đơn đã công bố; "Nhà trẻ" khi chỉ một khối ăn bữa đó.
  String? blockNote(String session) {
    final blocks = {
      for (final menu in maps(day['menu']))
        if (menu['session'] == session) '${menu['menuBlock']}',
    };
    return blocks.length == 1 ? kitchenBlockLabels[blocks.single] : null;
  }

  /// Giờ PHT xác nhận gần nhất (BE `confirmedAt`).
  DateTime? get confirmedAt => switch (day['confirmedAt']) {
    final String value => DateTime.parse(value).toLocal(),
    _ => null,
  };

  static Iterable<Map<Object?, Object?>> maps(Object? list) =>
      (list as List? ?? const []).whereType<Map>();

  static DateTime? _date(Object? value) => switch (value) {
    final String text => DateTime.parse(text),
    _ => null,
  };

  static int count(Object? value) => value is num ? value.toInt() : 0;
}

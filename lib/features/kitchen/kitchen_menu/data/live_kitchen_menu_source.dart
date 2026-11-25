import 'package:carenest_app/core/integration/api_dates.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/kitchen/kitchen_menu/domain/kitchen_menu.dart';
import 'package:carenest_app/features/kitchen/shared/kitchen_day_api.dart';

/// Thực đơn ngày cho bếp từ BE `GET /nutrition/kitchen/day?date` (phương án B, user 25/11): món theo
/// bữa × khối của tuần đã công bố; BE không trả món khi tuần còn nháp.
class LiveKitchenMenuSource implements KitchenMenuSource {
  LiveKitchenMenuSource(this._api);

  final MobileApi _api;

  @override
  Future<KitchenMenuDay> loadDay([DateTime? date]) async {
    final path = date == null
        ? '/nutrition/kitchen/day'
        : '/nutrition/kitchen/day?date=${apiDate(date)}';
    final day = await _api.json('GET', path) as Map? ?? const {};
    final bySession = <String, List<MenuBlockDishes>>{};
    for (final menu in KitchenDayData.maps(day['menu'])) {
      (bySession['${menu['session']}'] ??= []).add(
        MenuBlockDishes(
          label: kitchenBlockLabels['${menu['menuBlock']}'] ?? '',
          dishes: [
            for (final dish in KitchenDayData.maps(menu['dishes']))
              '${dish['name'] ?? ''}',
          ],
        ),
      );
    }
    // Nhà trẻ trước Mẫu giáo như Web
    for (final blocks in bySession.values) {
      blocks.sort(
        (a, b) => (a.label == 'Nhà trẻ' ? 0 : 1).compareTo(
          b.label == 'Nhà trẻ' ? 0 : 1,
        ),
      );
    }
    return KitchenMenuDay(
      date: DateTime.parse('${day['date']}'),
      published: day['menuStatus'] == 'PUBLISHED',
      isDayOff: day['dayOff'] == true,
      sessions: [
        for (final session in kitchenSessionOrder)
          if (bySession[session] case final blocks?)
            MenuSessionDishes(
              session: session,
              label: kitchenSessionLabels[session] ?? '',
              blocks: blocks,
            ),
      ],
    );
  }
}

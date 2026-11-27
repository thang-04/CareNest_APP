import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/kitchen/kitchen_meals/domain/kitchen_meals.dart';
import 'package:carenest_app/features/kitchen/shared/kitchen_day_api.dart';

/// Suất ăn theo lớp từ BE: lớp = `/nutrition/kitchen/day.servings` (chỉ số đã xác nhận, không tên trẻ —
/// AUTH-05, NUT-03); tổng từng bữa = `/meal-counts.totals` của bữa đã chốt.
class LiveKitchenMealsSource implements KitchenMealsSource {
  LiveKitchenMealsSource(this._api);

  final MobileApi _api;

  @override
  Future<MealCountSheet?> loadSheet() async {
    final data = await KitchenDayData.load(_api);
    final sessions = <SessionMealCount>[];
    for (final count in data.confirmedCounts) {
      final session = '${count['session']}';
      final totals = count['totals'] as Map? ?? const {};
      // NUT-23 (25/11): BE giữ substitute = 0 cho client cũ; App chỉ dùng normal
      final normal = KitchenDayData.count(totals['normal']);
      sessions.add(
        SessionMealCount(
          session: session,
          label: kitchenSessionLabels[session] ?? '',
          total: normal,
          regular: normal,
          alternative: 0,
          blockNote: data.blockNote(session),
          classes: [
            for (final line in KitchenDayData.maps(data.day['servings']))
              if (line['session'] == session)
                ClassMealCount(
                  className: '${line['classroomName'] ?? ''}',
                  regular: KitchenDayData.count(line['normal']),
                  alternative: 0,
                ),
          ],
        ),
      );
    }
    final confirmedAt = data.confirmedAt;
    if (sessions.isEmpty || confirmedAt == null) return null;
    return MealCountSheet(confirmedAt: confirmedAt, sessions: sessions);
  }
}

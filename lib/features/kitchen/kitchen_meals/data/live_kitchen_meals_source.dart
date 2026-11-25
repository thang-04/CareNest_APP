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
      final normal = KitchenDayData.count(totals['normal']);
      final substitute = KitchenDayData.count(totals['substitute']);
      sessions.add(
        SessionMealCount(
          session: session,
          label: kitchenSessionLabels[session] ?? '',
          total: normal + substitute,
          regular: normal,
          alternative: substitute,
          blockNote: data.blockNote(session),
          classes: [
            for (final line in KitchenDayData.maps(data.day['servings']))
              if (line['session'] == session)
                ClassMealCount(
                  className: '${line['classroomName'] ?? ''}',
                  regular: KitchenDayData.count(line['normal']),
                  alternative: KitchenDayData.count(line['substitute']),
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

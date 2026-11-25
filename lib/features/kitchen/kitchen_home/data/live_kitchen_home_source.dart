import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/kitchen/kitchen_home/domain/kitchen_today.dart';
import 'package:carenest_app/features/kitchen/shared/kitchen_day_api.dart';

/// Trang chủ bếp từ BE: số suất đã chốt từng bữa = `/meal-counts` (tổng suất = `normal` + `substitute`
/// theo BE `nutrition.md`, không cộng các lớp); trạng thái ngày = `/nutrition/kitchen/day`.
class LiveKitchenHomeSource implements KitchenHomeSource {
  LiveKitchenHomeSource(this._api, {this.tasks});

  final MobileApi _api;

  /// Việc hôm nay ghép từ ảnh mẫu + sổ lưu mẫu (BE không có API việc); null ⇒ chưa có việc.
  final Future<List<KitchenTask>> Function()? tasks;

  @override
  Future<KitchenToday> loadToday() async {
    final data = await KitchenDayData.load(_api);
    final today = await (tasks?.call() ?? Future.value(const <KitchenTask>[]));
    return KitchenToday(
      date: data.date,
      // BE chưa trả tên điểm trường cho bếp (đề xuất Thắng mục 2) ⇒ ẩn
      campusLabel: '',
      countStatus: switch (data.day['countStatus']) {
        'CONFIRMED' => KitchenCountStatus.confirmed,
        'PARTIAL' => KitchenCountStatus.partial,
        _ => KitchenCountStatus.none,
      },
      confirmedAt: data.confirmedAt,
      isDayOff: data.dayOff,
      servings: [
        for (final count in data.confirmedCounts)
          if (count['totals'] case final Map totals)
            SessionServings(
              session: '${count['session']}',
              label: kitchenSessionLabels['${count['session']}'] ?? '',
              total:
                  KitchenDayData.count(totals['normal']) +
                  KitchenDayData.count(totals['substitute']),
              substitute: KitchenDayData.count(totals['substitute']),
              blockNote: data.blockNote('${count['session']}'),
            ),
      ],
      tasks: today,
    );
  }
}

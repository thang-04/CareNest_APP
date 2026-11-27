import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/kitchen/kitchen_home/domain/kitchen_today.dart';
import 'package:carenest_app/features/kitchen/shared/kitchen_day_api.dart';

/// Trang chủ bếp từ BE: số suất đã chốt từng bữa = `/meal-counts` (tổng suất = `normal`,
/// không cộng các lớp; NUT-23 bỏ suất thay thế); trạng thái ngày = `/nutrition/kitchen/day`.
class LiveKitchenHomeSource implements KitchenHomeSource {
  LiveKitchenHomeSource(this._api, {this.tasks, this.account});

  final MobileApi _api;

  /// Việc hôm nay ghép từ ảnh mẫu + sổ lưu mẫu (BE không có API việc); null ⇒ chưa có việc.
  final Future<List<KitchenTask>> Function()? tasks;

  /// `/accounts/me` của phiên: `assignments[].campusName` (AUTH-22) cho nhãn điểm trường.
  final Map<String, dynamic>? Function()? account;

  /// Tên điểm trường của ngày bếp trong phân công hôm nay (BE đã bỏ phân công hết hạn).
  String _campusName(Object? campusId) {
    final assignments = (account?.call()?['assignments'] as List? ?? const [])
        .whereType<Map>();
    final match = assignments
        .where((a) => '${a['campusId']}' == '$campusId')
        .firstOrNull;
    return '${match?['campusName'] ?? ''}';
  }

  @override
  Future<KitchenToday> loadToday() async {
    final data = await KitchenDayData.load(_api);
    final today = await (tasks?.call() ?? Future.value(const <KitchenTask>[]));
    return KitchenToday(
      date: data.date,
      campusLabel: _campusName(data.day['campusId']),
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
              // NUT-23 (25/11): BE giữ substitute = 0 cho client cũ ⇒ tổng = normal
              total: KitchenDayData.count(totals['normal']),
              blockNote: data.blockNote('${count['session']}'),
            ),
      ],
      tasks: today,
      allergyDishes:
          [
            for (final menu in KitchenDayData.maps(data.day['menu']))
              for (final dish in KitchenDayData.maps(menu['dishes']))
                if (KitchenDayData.maps(dish['allergyWarnings']).isNotEmpty)
                  dish,
          ].length +
          KitchenDayData.maps(data.day['unmatchedAllergies']).length,
    );
  }
}

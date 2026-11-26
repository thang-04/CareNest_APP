import 'package:carenest_app/routing/route_paths.dart';

/// Nút mở màn trong chi tiết thông báo của phụ huynh (PAR-07, plan 2026-11-25 AC-4): loại BE
/// `NotificationType` + bé ⇒ màn của bé. Loại khác hoặc thiếu bé ⇒ null (không có nút).
({String label, String path})? parentNotificationTarget(
  String? type,
  String? childId,
) {
  if (childId == null || childId.isEmpty) return null;
  final (label, path) = switch (type) {
    'HEALTH_RESULT_PUBLISHED' ||
    'HEALTH_RESULT_UPDATED' ||
    'HEALTH_TREND_APPROVED' => ('Xem sổ sức khỏe', RoutePaths.parentHealthBook),
    'CHILD_EVALUATION_CONFIRMED' ||
    'THEME_EVALUATION_CONFIRMED' ||
    'WEEKLY_COMMENT_SENT' => (
      'Xem đánh giá của bé',
      RoutePaths.parentEvaluation,
    ),
    'REWARD_LIST_UPDATED' => ('Xem khen thưởng', RoutePaths.parentRewards),
    'LEAVE_REQUEST_CHANGED' => (
      'Xem đơn xin nghỉ',
      RoutePaths.parentLeaveNotices,
    ),
    'CHILD_PICKED_UP' || 'DAILY_HEALTH_NOTED' => (
      'Xem điểm danh của bé',
      RoutePaths.parentAttendance,
    ),
    _ => (null, null),
  };
  if (label == null || path == null) return null;
  return (label: label, path: RoutePaths.withChild(path, childId));
}

/// Nút mở màn trong chi tiết thông báo của bếp: suất đã xác nhận ⇒ Suất ăn theo lớp; thực đơn đổi ⇒
/// tab Thực đơn. BE `link` (vd. `/kitchen/meal-count`) là đường dẫn Web nên App không dùng.
({String label, String path})? kitchenNotificationTarget(String? type) =>
    switch (type) {
      'MEAL_COUNT_CONFIRMED' => (
        label: 'Xem suất ăn theo lớp',
        path: RoutePaths.kitchenMeals,
      ),
      'MENU_CHANGED' ||
      'MENU_PUBLISHED' => (label: 'Xem thực đơn', path: RoutePaths.kitchenMenu),
      _ => null,
    };

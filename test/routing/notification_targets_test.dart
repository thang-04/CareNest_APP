import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/routing/notification_targets.dart';
import 'package:carenest_app/routing/route_paths.dart';

void main() {
  test('PAR-07: loại thông báo của bé mở đúng màn kèm bé', () {
    final cases = {
      'HEALTH_RESULT_PUBLISHED': RoutePaths.parentHealthBook,
      'HEALTH_RESULT_UPDATED': RoutePaths.parentHealthBook,
      'HEALTH_TREND_APPROVED': RoutePaths.parentHealthBook,
      'CHILD_EVALUATION_CONFIRMED': RoutePaths.parentEvaluation,
      'THEME_EVALUATION_CONFIRMED': RoutePaths.parentEvaluation,
      'WEEKLY_COMMENT_SENT': RoutePaths.parentEvaluation,
      'REWARD_LIST_UPDATED': RoutePaths.parentRewards,
      'LEAVE_REQUEST_CHANGED': RoutePaths.parentLeaveNotices,
      'CHILD_PICKED_UP': RoutePaths.parentAttendance,
      'DAILY_HEALTH_NOTED': RoutePaths.parentAttendance,
    };
    for (final MapEntry(key: type, value: path) in cases.entries) {
      final target = parentNotificationTarget(type, '5');
      expect(target, isNotNull, reason: type);
      expect(target!.path, RoutePaths.withChild(path, '5'), reason: type);
      expect(target.label, isNotEmpty, reason: type);
    }
  });

  test('loại khác hoặc thiếu bé ⇒ không có nút', () {
    expect(parentNotificationTarget('SCHOOL_ANNOUNCEMENT', '5'), isNull);
    expect(parentNotificationTarget('MENU_PUBLISHED', '5'), isNull);
    expect(parentNotificationTarget('HEALTH_RESULT_PUBLISHED', null), isNull);
    expect(parentNotificationTarget(null, '5'), isNull);
  });
}

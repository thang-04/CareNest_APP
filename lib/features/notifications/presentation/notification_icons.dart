import 'package:flutter/widgets.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/features/notifications/domain/app_notification.dart';

IconData notificationIcon(NotificationKind kind) => switch (kind) {
  NotificationKind.general => AppIcons.bell,
  NotificationKind.review => AppIcons.clipboardCheck,
  NotificationKind.leave => AppIcons.calendarOff,
  NotificationKind.menu => AppIcons.menuBook,
  NotificationKind.health => AppIcons.heart,
  NotificationKind.attendance => AppIcons.checkCircle,
  NotificationKind.meal => AppIcons.meal,
  NotificationKind.approval => AppIcons.approval,
};

/// Nhóm danh sách theo ngày gửi (DESIGN.md §B: Hôm nay / Hôm qua / Trước đó).
String notificationGroup(DateTime sentAt, DateTime today) {
  final day = DateTime(sentAt.year, sentAt.month, sentAt.day);
  final start = DateTime(today.year, today.month, today.day);
  if (!day.isBefore(start)) return 'Hôm nay';
  if (!day.isBefore(start.subtract(const Duration(days: 1)))) return 'Hôm qua';
  return 'Trước đó';
}

/// "Cô Hà · 12/10/2026 · 16:05"
String notificationMeta(AppNotification item) => [
  ?item.sender,
  DateLabels.date(item.sentAt),
  DateLabels.time24(item.sentAt),
].join(' · ');

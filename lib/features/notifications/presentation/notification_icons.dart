import 'package:flutter/widgets.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/features/notifications/domain/app_notification.dart';

IconData notificationIcon(NotificationType type) => switch (type) {
  NotificationType.childPickedUp ||
  NotificationType.childPlaced ||
  NotificationType.childWithdrawn => AppIcons.child,
  NotificationType.healthResultPublished ||
  NotificationType.healthResultUpdated ||
  NotificationType.healthCheckOpened ||
  NotificationType.dailyHealthNoted ||
  NotificationType.childTbContact ||
  NotificationType.childTbContactDateChanged => AppIcons.heart,
  NotificationType.leaveRequestChanged => AppIcons.calendarOff,
  NotificationType.attendanceDayUnlocked ||
  NotificationType.attendanceReminder ||
  NotificationType.cutoffChanged => AppIcons.checkCircle,
  NotificationType.mealCountConfirmed ||
  NotificationType.mealCountReconfirm => AppIcons.meal,
  NotificationType.weeklyCommentSent ||
  NotificationType.assessmentReminder ||
  NotificationType.assessmentReopened ||
  NotificationType.leaderReminder => AppIcons.clipboardCheck,
  NotificationType.rewardListUpdated ||
  NotificationType.guardianPhoneChangeRequested ||
  NotificationType.guardianPhoneChangeDecided => AppIcons.approval,
  NotificationType.eduSubmitted ||
  NotificationType.eduStepApproved ||
  NotificationType.eduReleased ||
  NotificationType.eduReturned ||
  NotificationType.eduDeadlineExtended ||
  NotificationType.eduDeadlineNear ||
  NotificationType.staffAssigned ||
  NotificationType.schoolYearActivated => AppIcons.school,
  NotificationType.unknown => AppIcons.bell,
};

/// Lối mở màn liên quan theo `docs/integration/PUSH_NOTIFICATION.md`; null ⇒ chỉ xem trong danh sách.
String? notificationAction(NotificationType type) => switch (type) {
  NotificationType.childPickedUp ||
  NotificationType.dailyHealthNoted => 'Xem hôm nay của bé',
  NotificationType.healthResultPublished ||
  NotificationType.healthResultUpdated => 'Xem sức khỏe của bé',
  NotificationType.weeklyCommentSent => 'Xem nhận xét của bé',
  NotificationType.leaveRequestChanged => 'Xem đơn nghỉ của lớp',
  NotificationType.childPlaced => 'Xem lớp học',
  NotificationType.attendanceDayUnlocked ||
  NotificationType.attendanceReminder => 'Mở điểm danh',
  NotificationType.mealCountConfirmed => 'Xem suất ăn hôm nay',
  _ => null,
};

/// "12/10/2026 · 16:05"
String notificationMeta(AppNotification item) =>
    '${DateLabels.date(item.sentAt)} · ${DateLabels.time24(item.sentAt)}';

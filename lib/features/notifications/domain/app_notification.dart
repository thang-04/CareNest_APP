import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/account/domain/account_profile.dart';

/// Loại thông báo — khớp BE `NotificationType` (danh mục theo role: `BE:docs/modules/notification.md`, PAR-07).
/// Loại BE thêm sau mà App chưa biết ⇒ [unknown]: vẫn hiện trong danh sách, không crash.
enum NotificationType {
  childPickedUp('CHILD_PICKED_UP'),
  mealCountReconfirm('MEAL_COUNT_RECONFIRM'),
  childWithdrawn('CHILD_WITHDRAWN'),
  guardianPhoneChangeRequested('GUARDIAN_PHONE_CHANGE_REQUESTED'),
  guardianPhoneChangeDecided('GUARDIAN_PHONE_CHANGE_DECIDED'),
  childTbContact('CHILD_TB_CONTACT'),
  childTbContactDateChanged('CHILD_TB_CONTACT_DATE_CHANGED'),
  healthResultPublished('HEALTH_RESULT_PUBLISHED'),
  healthResultUpdated('HEALTH_RESULT_UPDATED'),
  healthCheckOpened('HEALTH_CHECK_OPENED'),
  healthTrendApproved('HEALTH_TREND_APPROVED'),
  childPlaced('CHILD_PLACED'),
  attendanceDayUnlocked('ATTENDANCE_DAY_UNLOCKED'),
  eduSubmitted('EDU_SUBMITTED'),
  eduStepApproved('EDU_STEP_APPROVED'),
  eduReleased('EDU_RELEASED'),
  eduReturned('EDU_RETURNED'),
  eduDeadlineExtended('EDU_DEADLINE_EXTENDED'),
  eduDeadlineNear('EDU_DEADLINE_NEAR'),
  weeklyCommentSent('WEEKLY_COMMENT_SENT'),
  attendanceReminder('ATTENDANCE_REMINDER'),
  assessmentReminder('ASSESSMENT_REMINDER'),
  assessmentReopened('ASSESSMENT_REOPENED'),
  leaderReminder('LEADER_REMINDER'),
  staffAssigned('STAFF_ASSIGNED'),
  cutoffChanged('CUTOFF_CHANGED'),
  leaveRequestChanged('LEAVE_REQUEST_CHANGED'),
  mealCountConfirmed('MEAL_COUNT_CONFIRMED'),
  rewardListUpdated('REWARD_LIST_UPDATED'),
  dailyHealthNoted('DAILY_HEALTH_NOTED'),
  schoolYearActivated('SCHOOL_YEAR_ACTIVATED'),
  unknown('');

  const NotificationType(this.code);

  /// Mã BE (`CHILD_PICKED_UP`...).
  final String code;

  static NotificationType fromCode(String code) => values.firstWhere(
    (type) => type.code == code && type != unknown,
    orElse: () => unknown,
  );
}

/// Một thông báo theo BE `NotificationResponse` (id, type, title, body, childId, createdAt, readAt).
/// Nội dung do BE soạn; App không thêm dữ liệu sức khỏe hay chi tiết nhạy cảm (PAR-07).
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.sentAt,
    this.body,
    this.childId,
    this.tag,
    this.unread = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final DateTime sentAt;
  final String? body;
  final String? childId;

  /// Ngữ cảnh hiển thị ghép từ `childId` / lớp, vd. "Bé Nguyễn Minh Anh · Mầm 3A".
  final String? tag;

  /// BE `readAt == null`; chỉ để App hiện badge của chính người nhận (PAR-05).
  final bool unread;

  AppNotification markRead() => AppNotification(
    id: id,
    type: type,
    title: title,
    sentAt: sentAt,
    body: body,
    childId: childId,
    tag: tag,
  );
}

abstract interface class NotificationSource {
  Future<List<AppNotification>> load(AppRole role);
}

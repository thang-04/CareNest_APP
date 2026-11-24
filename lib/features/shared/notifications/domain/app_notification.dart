import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/shared/account/domain/account_profile.dart';

/// Loại thông báo ⇒ chọn icon; nhãn hiển thị lấy `typeLabel` BE trả.
enum NotificationKind {
  general,
  review,
  leave,
  menu,
  health,
  attendance,
  meal,
  approval,
}

@immutable
class NotificationAttachment {
  const NotificationAttachment({
    required this.id,
    required this.fileName,
    this.contentType,
  });

  final String id;
  final String fileName;
  final String? contentType;
}

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.sentAt,
    this.sender,
    this.body,
    this.typeLabel,
    this.tag,
    this.hasPhoto = false,
    this.actionLabel,
    this.attachments = const [],
    this.unread = false,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final DateTime sentAt;

  /// Người gửi rút gọn ("Cô Hà"); null với thông báo hệ thống.
  final String? sender;
  final String? body;

  /// Nhóm loại do BE đặt tên (cùng nhãn badge với web), vd. "Thông báo của trường".
  final String? typeLabel;

  /// Ngữ cảnh, vd. "Bé Nguyễn Minh Anh · Mầm 3A".
  final String? tag;
  final bool hasPhoto;

  /// Lối mở màn liên quan, vd. "Xem đánh giá của bé".
  final String? actionLabel;
  final List<NotificationAttachment> attachments;
  final bool unread;

  AppNotification markRead() => AppNotification(
    id: id,
    kind: kind,
    title: title,
    sentAt: sentAt,
    sender: sender,
    body: body,
    typeLabel: typeLabel,
    tag: tag,
    hasPhoto: hasPhoto,
    actionLabel: actionLabel,
    attachments: attachments,
  );
}

abstract interface class NotificationSource {
  Future<List<AppNotification>> load(AppRole role);

  /// Toàn văn theo ID và ghi nhận đã đọc; null khi không có hoặc không thuộc tài khoản (403/404).
  Future<AppNotification?> loadDetail(AppRole role, String id);

  Future<void> markAllRead();

  /// Tải tệp qua API có xác thực rồi lưu về máy.
  Future<void> saveAttachment(NotificationAttachment file);
}

import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/account/domain/account_profile.dart';

/// Loại thông báo ⇒ chọn icon; mã thật lấy từ BE khi có contract.
enum NotificationKind {
  review,
  leave,
  menu,
  health,
  attendance,
  meal,
  approval,
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
    this.tag,
    this.hasPhoto = false,
    this.actionLabel,
    this.unread = false,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final DateTime sentAt;

  /// Người gửi rút gọn ("Cô Hà"); null với thông báo hệ thống.
  final String? sender;
  final String? body;

  /// Ngữ cảnh, vd. "Bé Nguyễn Minh Anh · Mầm 3A".
  final String? tag;
  final bool hasPhoto;

  /// Lối mở màn liên quan, vd. "Xem đánh giá của bé".
  final String? actionLabel;
  final bool unread;

  AppNotification markRead() => AppNotification(
    id: id,
    kind: kind,
    title: title,
    sentAt: sentAt,
    sender: sender,
    body: body,
    tag: tag,
    hasPhoto: hasPhoto,
    actionLabel: actionLabel,
  );
}

abstract interface class NotificationSource {
  Future<List<AppNotification>> load(AppRole role);
}

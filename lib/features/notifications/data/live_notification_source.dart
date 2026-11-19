import 'package:flutter/services.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/account/domain/account_profile.dart';
import 'package:carenest_app/features/notifications/domain/app_notification.dart';

/// Thông báo của tài khoản đang đăng nhập (`/me/notifications`, tin trường `/me/announcements`).
class LiveNotificationSource implements NotificationSource {
  const LiveNotificationSource(this.api);

  final MobileApi api;

  @override
  Future<List<AppNotification>> load(AppRole role) async {
    final feed = await api.json('GET', '/me/notifications') as Map;
    return [
      for (final item in feed['items'] as List? ?? const [])
        _fromJson(item as Map),
    ];
  }

  @override
  Future<AppNotification?> loadDetail(AppRole role, String id) async {
    try {
      final notification =
          await api.json('GET', '/me/notifications/$id') as Map;
      final announcementId = notification['announcementId'];
      // Bản trong danh sách là tóm tắt; tin của trường lấy toàn văn, người gửi, tệp
      final announcement = announcementId == null
          ? null
          : await api.json('GET', '/me/announcements/$announcementId') as Map;
      await api.json('POST', '/me/notifications/$id/read');
      return _fromJson({...notification, ...?announcement, 'id': id});
    } on ApiFailure catch (failure) {
      if (failure.status == 403 || failure.status == 404) return null;
      rethrow;
    }
  }

  @override
  Future<void> markAllRead() => api.json('POST', '/me/notifications/read-all');

  @override
  Future<void> saveAttachment(NotificationAttachment file) async {
    final data = await api.binary(
      '/announcement-attachments/${file.id}/content',
    );
    await const MethodChannel('carenest/files').invokeMethod<void>('save', {
      'name': file.fileName,
      'type': file.contentType,
      'bytes': data,
    });
  }

  static AppNotification _fromJson(Map json) => AppNotification(
    id: '${json['id']}',
    kind: _kindOf(json['type']?.toString()),
    title: json['title']?.toString() ?? '',
    body: json['body']?.toString(),
    typeLabel: json['typeLabel']?.toString(),
    sender: json['senderName']?.toString(),
    sentAt:
        DateTime.tryParse(
          (json['sentAt'] ?? json['createdAt'])?.toString() ?? '',
        )?.toLocal() ??
        DateTime.now(),
    attachments: [
      for (final file in json['attachments'] as List? ?? const [])
        NotificationAttachment(
          id: '${(file as Map)['id']}',
          fileName: file['fileName']?.toString() ?? 'Tệp',
          contentType: file['contentType']?.toString(),
        ),
    ],
    unread: json.containsKey('readAt') && json['readAt'] == null,
  );

  /// Mã loại BE ⇒ chỉ chọn icon; nhãn hiển thị vẫn là `typeLabel` BE trả.
  static NotificationKind _kindOf(String? type) => switch (type ?? '') {
    final t when t.startsWith('EDU_') => NotificationKind.approval,
    final t when t.contains('HEALTH') || t.startsWith('CHILD_TB') =>
      NotificationKind.health,
    'MENU_PUBLISHED' => NotificationKind.menu,
    final t when t.startsWith('LEAVE_') => NotificationKind.leave,
    final t when t.startsWith('ATTENDANCE_') || t == 'CHILD_PICKED_UP' =>
      NotificationKind.attendance,
    final t when t.startsWith('MEAL_') || t == 'CUTOFF_CHANGED' =>
      NotificationKind.meal,
    final t
        when t.contains('EVALUATION') ||
            t.startsWith('ASSESSMENT_') ||
            t == 'WEEKLY_COMMENT_SENT' =>
      NotificationKind.review,
    _ => NotificationKind.general,
  };
}

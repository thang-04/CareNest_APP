import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';

class LiveNotificationsScreen extends StatefulWidget {
  const LiveNotificationsScreen({
    super.key,
    required this.api,
    required this.signOut,
  });
  final MobileApi api;
  final Future<void> Function() signOut;
  @override
  State<LiveNotificationsScreen> createState() =>
      _LiveNotificationsScreenState();
}

class _LiveNotificationsScreenState extends State<LiveNotificationsScreen> {
  Map<String, dynamic>? feed;
  Object? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final value =
          await widget.api.json('GET', '/me/notifications')
              as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          feed = value;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Thông báo'),
      actions: [
        IconButton(
          onPressed: widget.signOut,
          icon: const Icon(Icons.logout),
          tooltip: 'Đăng xuất',
        ),
      ],
    ),
    body: error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$error'),
                TextButton(onPressed: load, child: const Text('Thử lại')),
              ],
            ),
          )
        : feed == null
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              children: [
                ListTile(
                  title: Text('Chưa đọc: ${feed!['unreadCount']}'),
                  trailing: TextButton(
                    onPressed: () async {
                      await widget.api.json(
                        'POST',
                        '/me/notifications/read-all',
                      );
                      await load();
                    },
                    child: const Text('Đánh dấu đã đọc'),
                  ),
                ),
                for (final dynamic raw in feed!['items'] as List)
                  ListTile(
                    title: Text(raw['title']?.toString() ?? ''),
                    subtitle: Text(raw['body']?.toString() ?? ''),
                    onTap: () async {
                      await context.push('/live/notifications/${raw['id']}');
                      if (mounted) await load();
                    },
                  ),
                if ((feed!['items'] as List).isEmpty)
                  const ListTile(title: Text('Chưa có thông báo.')),
              ],
            ),
          ),
  );
}

class LiveNotificationDetailScreen extends StatefulWidget {
  const LiveNotificationDetailScreen({
    super.key,
    required this.api,
    required this.id,
  });
  final MobileApi api;
  final int id;
  @override
  State<LiveNotificationDetailScreen> createState() =>
      _LiveNotificationDetailScreenState();
}

class _LiveNotificationDetailScreenState
    extends State<LiveNotificationDetailScreen> {
  Map<String, dynamic>? item;
  Object? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final notification =
          await widget.api.json('GET', '/me/notifications/${widget.id}')
              as Map<String, dynamic>;
      final id = notification['announcementId'];
      final announcement = id == null
          ? null
          : await widget.api.json('GET', '/me/announcements/$id')
                as Map<String, dynamic>;
      await widget.api.json('POST', '/me/notifications/${widget.id}/read');
      if (mounted) {
        setState(() {
          item = {...notification, ...?announcement};
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  Future<void> saveAttachment(Map<String, dynamic> attachment) async {
    try {
      final data = await widget.api.binary(
        '/announcement-attachments/${attachment['id']}/content',
      );
      await const MethodChannel('carenest/files').invokeMethod<void>('save', {
        'name': attachment['fileName'],
        'type': attachment['contentType'],
        'bytes': data,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể tải tệp: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chi tiết thông báo')),
    body: error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error is ApiFailure &&
                          [403, 404].contains((error as ApiFailure).status)
                      ? 'Không tìm thấy hoặc bạn không có quyền xem thông báo.'
                      : '$error',
                ),
                TextButton(onPressed: load, child: const Text('Thử lại')),
              ],
            ),
          )
        : item == null
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                item!['title']?.toString() ?? '',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (item!['senderName'] != null)
                Text('Người gửi: ${item!['senderName']}'),
              const SizedBox(height: 16),
              Text(item!['body']?.toString() ?? ''),
              for (final dynamic file in (item!['attachments'] as List? ?? []))
                ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: Text(file['fileName']?.toString() ?? 'Tệp'),
                  onTap: () => saveAttachment(file as Map<String, dynamic>),
                ),
            ],
          ),
  );
}

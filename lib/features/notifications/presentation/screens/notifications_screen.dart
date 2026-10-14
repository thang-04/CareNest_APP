import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/account/domain/account_profile.dart';
import 'package:carenest_app/features/notifications/data/fake_notification_source.dart';
import 'package:carenest_app/features/notifications/domain/app_notification.dart';
import 'package:carenest_app/features/notifications/presentation/notification_icons.dart';

/// Thông báo — mockup P06, dùng chung 5 vai trò. Danh sách in-app, không phải nội dung push.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.role,
    required this.onOpen,
    this.source = const FakeNotificationSource(),
  });

  final AppRole role;

  /// Mở chi tiết theo ID; dữ liệu chi tiết tải lại theo ID.
  final ValueChanged<String> onOpen;
  final NotificationSource source;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification>? _items;
  Object? _error;
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final items = await widget.source.load(widget.role);
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  // Đánh dấu đã đọc là thao tác BE; bản dữ liệu giả chỉ đổi trên màn
  void _markAllRead() =>
      setState(() => _items = [for (final item in _items!) item.markRead()]);

  void _open(AppNotification item) {
    setState(
      () => _items = [
        for (final other in _items!)
          other.id == item.id ? other.markRead() : other,
      ],
    );
    widget.onOpen(item.id);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final items = _items;
    final unread = items?.where((item) => item.unread).length ?? 0;
    final visible = items == null
        ? const <AppNotification>[]
        : _unreadOnly
        ? items.where((item) => item.unread).toList()
        : items;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          // Wrap: chữ phóng lớn thì link xuống dòng thay vì tràn
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                header: true,
                child: Text('Thông báo', style: textTheme.headlineSmall),
              ),
              AppLinkButton(
                label: 'Đánh dấu đã đọc',
                onPressed: unread == 0 ? null : _markAllRead,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              AppFilterChip(
                label: 'Tất cả',
                selected: !_unreadOnly,
                onSelected: () => setState(() => _unreadOnly = false),
              ),
              AppFilterChip(
                label: 'Chưa đọc ($unread)',
                selected: _unreadOnly,
                onSelected: () => setState(() => _unreadOnly = true),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          if (_error != null)
            AppErrorState(
              title: 'Chưa tải được thông báo',
              message: 'Kiểm tra kết nối rồi thử lại.',
              onRetry: _load,
            )
          else if (items == null)
            const AppSkeletonList(rows: 4)
          else if (visible.isEmpty)
            AppEmptyState(
              icon: AppIcons.bell,
              title: _unreadOnly
                  ? 'Không có thông báo chưa đọc'
                  : 'Chưa có thông báo',
              message: 'Thông báo mới của nhà trường sẽ hiện ở đây.',
            )
          else
            for (final item in visible) ...[
              _NotificationCard(item: item, onTap: () => _open(item)),
              const SizedBox(height: AppSpacing.space3),
            ],
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final unread = item.unread;
    return Semantics(
      container: true,
      button: true,
      label: [
        if (unread) 'Chưa đọc',
        item.title,
        notificationMeta(item),
      ].join(', '),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.card,
        ),
        child: Material(
          color: unread ? AppColors.primarySoft : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            side: BorderSide(
              color: unread
                  ? AppColors.primaryBorder
                  : AppColors.surface.withValues(alpha: 0.85),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    notificationIcon(item.kind),
                    size: AppSizes.iconTile,
                    color: unread ? AppColors.primary : AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: unread
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space1),
                        Text(
                          notificationMeta(item),
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

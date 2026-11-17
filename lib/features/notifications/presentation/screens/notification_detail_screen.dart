import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_coming_soon.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/account/domain/account_profile.dart';
import 'package:carenest_app/features/notifications/data/fake_notification_source.dart';
import 'package:carenest_app/features/notifications/domain/app_notification.dart';
import 'package:carenest_app/features/notifications/presentation/notification_icons.dart';

/// Chi tiết thông báo — mockup P07. Route chỉ mang ID; nội dung tải lại theo ID.
class NotificationDetailScreen extends StatefulWidget {
  const NotificationDetailScreen({
    super.key,
    required this.role,
    required this.id,
    this.source = const FakeNotificationSource(),
  });

  final AppRole role;
  final String id;
  final NotificationSource source;

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  late Future<AppNotification?> _item = _fetch();

  Future<AppNotification?> _fetch() =>
      widget.source.loadDetail(widget.role, widget.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết thông báo')),
      body: FutureBuilder<AppNotification?>(
        future: _item,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: AppErrorState(
                title: 'Chưa tải được thông báo',
                message: 'Kiểm tra kết nối rồi thử lại.',
                onRetry: () => setState(() => _item = _fetch()),
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonCard(),
            );
          }
          final item = snapshot.data;
          if (item == null) {
            return const Center(
              child: AppEmptyState(
                icon: AppIcons.searchOff,
                title: 'Không tìm thấy thông báo',
                message: 'Thông báo đã bị gỡ hoặc không thuộc tài khoản này.',
              ),
            );
          }
          return _DetailBody(item: item, source: widget.source);
        },
      ),
    );
  }
}

class _DetailBody extends StatefulWidget {
  const _DetailBody({required this.item, required this.source});

  final AppNotification item;
  final NotificationSource source;

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  String? _saving;
  String? _saveError;

  Future<void> _save(NotificationAttachment file) async {
    setState(() {
      _saving = file.id;
      _saveError = null;
    });
    try {
      await widget.source.saveAttachment(file);
    } catch (_) {
      if (mounted) setState(() => _saveError = file.fileName);
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final item = widget.item;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIconTile(icon: notificationIcon(item.kind), size: 48),
              const SizedBox(height: AppSpacing.space4),
              Text(item.title, style: textTheme.titleMedium),
              if (item.typeLabel != null) ...[
                const SizedBox(height: AppSpacing.space2),
                AppStatusBadge(
                  label: item.typeLabel!,
                  tone: AppStatusTone.gray,
                ),
              ],
              const SizedBox(height: AppSpacing.space2),
              Text(
                notificationMeta(item),
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              if (item.body != null) ...[
                const SizedBox(height: AppSpacing.space4),
                Text(
                  item.body!,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (item.tag != null) ...[
          const SizedBox(height: AppSpacing.space3),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space1,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                item.tag!,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.onBrand,
                ),
              ),
            ),
          ),
        ],
        if (item.hasPhoto) ...[
          const SizedBox(height: AppSpacing.space3),
          // Ảnh thật chỉ tải qua URL có auth khi có API; bản giả dùng khối giữ chỗ
          Semantics(
            label: 'Ảnh đính kèm',
            excludeSemantics: true,
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: const Icon(
                  AppIcons.image,
                  size: 56,
                  color: AppColors.primaryBorder,
                ),
              ),
            ),
          ),
        ],
        if (item.attachments.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space4),
          Semantics(
            header: true,
            child: Text('Tệp đính kèm', style: textTheme.titleSmall),
          ),
          const SizedBox(height: AppSpacing.space2),
          if (_saveError != null) ...[
            AppBanner(
              kind: AppBannerKind.danger,
              message: 'Chưa tải được tệp $_saveError. Thử lại sau.',
            ),
            const SizedBox(height: AppSpacing.space2),
          ],
          AppCard(
            flush: true,
            child: AppDividedColumn(
              children: [
                for (final file in item.attachments)
                  AppListRow(
                    title: file.fileName,
                    leading: const Icon(AppIcons.attachment),
                    trailing: Icon(
                      AppIcons.download,
                      semanticLabel: 'Tải ${file.fileName}',
                      color: _saving == file.id
                          ? AppColors.textMuted
                          : AppColors.primary,
                    ),
                    onTap: _saving == null ? () => _save(file) : null,
                  ),
              ],
            ),
          ),
        ],
        if (item.actionLabel != null) ...[
          const SizedBox(height: AppSpacing.space4),
          AppButton(
            label: item.actionLabel!,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () => openComingSoon(context, item.actionLabel!),
          ),
        ],
      ],
    );
  }
}

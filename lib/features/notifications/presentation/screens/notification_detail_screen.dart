import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_coming_soon.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/account/domain/account_profile.dart';
import 'package:carenest_app/features/notifications/data/fake_notification_source.dart';
import 'package:carenest_app/features/notifications/domain/app_notification.dart';
import 'package:carenest_app/features/notifications/presentation/notification_icons.dart';

/// Chi tiết thông báo — mockup P07. Route chỉ mang ID; nội dung tải lại theo ID.
class NotificationDetailScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết thông báo')),
      body: FutureBuilder<List<AppNotification>>(
        future: source.load(role),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonCard(),
            );
          }
          final item = snapshot.data!
              .where((notification) => notification.id == id)
              .firstOrNull;
          if (item == null) {
            return const Center(
              child: AppEmptyState(
                icon: AppIcons.searchOff,
                title: 'Không tìm thấy thông báo',
                message: 'Thông báo đã bị gỡ hoặc không thuộc tài khoản này.',
              ),
            );
          }
          return _DetailBody(item: item);
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
              const SizedBox(height: AppSpacing.space1),
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

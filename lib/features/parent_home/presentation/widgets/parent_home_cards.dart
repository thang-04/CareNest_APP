import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/parent_home/domain/parent_today.dart';
import 'package:carenest_app/features/parent_home/presentation/parent_home_status.dart';

/// Thẻ bé đè lên hero: tên, lớp · tuổi · lối vào hồ sơ, "Đổi bé" khi có nhiều con.
class ChildHeroCard extends StatelessWidget {
  const ChildHeroCard({
    super.key,
    required this.child,
    required this.onOpenProfile,
    this.onSwitchChild,
  });

  final ChildSummary child;
  final VoidCallback onOpenProfile;

  /// Null khi phụ huynh chỉ có một con.
  final VoidCallback? onSwitchChild;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      dense: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIconTile(icon: AppIcons.childFace, size: 52),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bé ${child.fullName}', style: textTheme.titleMedium),
                Semantics(
                  button: true,
                  child: InkWell(
                    onTap: onOpenProfile,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.space1,
                      ),
                      child: Text(
                        'Lớp ${child.className} · ${child.ageLabel} · Xem hồ sơ ›',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onSwitchChild != null)
            AppLinkButton(label: 'Đổi bé', onPressed: onSwitchChild),
        ],
      ),
    );
  }
}

/// Khối "Hôm nay": điểm danh, thực đơn, hoạt động — mỗi dòng mở màn chi tiết.
class TodaySummaryCard extends StatelessWidget {
  const TodaySummaryCard({
    super.key,
    required this.today,
    required this.onOpenAttendance,
    required this.onOpenMenu,
    required this.onOpenActivities,
  });

  final ParentToday today;
  final VoidCallback onOpenAttendance;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenActivities;

  @override
  Widget build(BuildContext context) {
    final status = today.attendance;
    final arrived = today.arrivedAt;
    return AppCard(
      flush: true,
      child: AppDividedColumn(
        children: [
          AppListRow(
            title: 'Điểm danh',
            leading: const _RowIcon(AppIcons.checkCircle),
            trailing: AppStatusBadge(
              label: arrived == null
                  ? status.label
                  : '${status.label} · ${DateLabels.time24(arrived)}',
              tone: status.tone,
            ),
            onTap: onOpenAttendance,
          ),
          AppListRow(
            title: 'Thực đơn',
            leading: const _RowIcon(AppIcons.meal),
            subtitle: today.menuPublished
                ? null
                : const Text('Nhà trường chưa công bố thực đơn hôm nay.'),
            showChevron: true,
            onTap: onOpenMenu,
          ),
          AppListRow(
            title: today.activityTitle == null
                ? 'Hoạt động'
                : 'Hoạt động · ${today.activityTitle}',
            leading: const _RowIcon(AppIcons.image),
            showChevron: true,
            onTap: onOpenActivities,
          ),
        ],
      ),
    );
  }
}

class _RowIcon extends StatelessWidget {
  const _RowIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) =>
      Icon(icon, size: AppSizes.iconTile, color: AppColors.primary);
}

/// Một ô trong lưới "Tiện ích".
@immutable
class UtilityItem {
  const UtilityItem(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Lưới 2 cột; mỗi hàng cao bằng ô cao nhất để chữ dài/chữ lớn không lệch hàng.
class UtilityGrid extends StatelessWidget {
  const UtilityGrid({super.key, required this.items});

  final List<UtilityItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i += 2) ...[
          if (i > 0) const SizedBox(height: AppSpacing.space3),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _UtilityTile(item: items[i])),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: i + 1 < items.length
                      ? _UtilityTile(item: items[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _UtilityTile extends StatelessWidget {
  const _UtilityTile({required this.item});

  final UtilityItem item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: item.onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.icon,
                  size: AppSizes.iconNavigation,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.space3),
                Text(item.label, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

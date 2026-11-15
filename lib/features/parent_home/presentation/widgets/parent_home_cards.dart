import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/parent_home/domain/parent_today.dart';
import 'package:carenest_app/features/parent_home/presentation/parent_home_status.dart';

/// Thẻ bé đang chọn (thẻ trên cùng của "ví"): tên, lớp, điểm danh và ba ô hôm nay.
class ChildWalletCard extends StatelessWidget {
  const ChildWalletCard({
    super.key,
    required this.today,
    required this.onOpenAttendance,
    required this.onOpenMenu,
    required this.onOpenActivities,
    required this.onOpenProfile,
  });

  final ParentToday today;
  final VoidCallback onOpenAttendance;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenActivities;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final child = today.child;
    final status = today.attendance;
    final arrived = today.arrivedAt;
    return AppFeaturedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppAvatar(name: child.fullName, size: 56),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.shortName, style: textTheme.headlineSmall),
                    Text(
                      '${child.className} · ${child.ageLabel}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              AppStatusBadge(
                label: status.label,
                tone: status.tone,
                icon: status.icon,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          _TodayStrip(
            cells: [
              _StripCell(
                label: 'Điểm danh',
                value: arrived == null
                    ? status.label
                    : DateLabels.time24(arrived),
                onTap: onOpenAttendance,
              ),
              _StripCell(
                label: 'Thực đơn',
                value: today.menuPublished ? 'Đã công bố' : 'Chưa công bố',
                onTap: onOpenMenu,
              ),
              _StripCell(
                label: 'Hoạt động',
                value: today.activityTitle ?? 'Chưa có',
                onTap: onOpenActivities,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Align(
            alignment: Alignment.centerLeft,
            child: AppLinkButton(
              label: 'Xem hồ sơ của ${child.shortName} ›',
              onPressed: onOpenProfile,
            ),
          ),
        ],
      ),
    );
  }
}

class _StripCell {
  const _StripCell({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
}

/// Dải ba ô hôm nay; chữ lớn hoặc thẻ hẹp ⇒ xếp dọc thay vì ép ba cột cắt chữ.
class _TodayStrip extends StatelessWidget {
  const _TodayStrip({required this.cells});

  final List<_StripCell> cells;

  // Dưới bề rộng này mỗi cột < 90px, chữ như "Đã công bố" bị cắt
  static const double _minRowWidth = 270;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _build(
        context,
        stacked:
            MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
            constraints.maxWidth < _minRowWidth,
      ),
    );
  }

  Widget _build(BuildContext context, {required bool stacked}) {
    final items = [
      for (final cell in cells)
        _StripItem(cell: cell, maxLines: stacked ? 3 : 2),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(),
                  items[i],
                ],
              ],
            )
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const VerticalDivider(width: 1),
                    Expanded(child: items[i]),
                  ],
                ],
              ),
            ),
    );
  }
}

class _StripItem extends StatelessWidget {
  const _StripItem({required this.cell, required this.maxLines});

  final _StripCell cell;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '${cell.label}: ${cell.value}',
      excludeSemantics: true,
      child: InkWell(
        onTap: cell.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSizes.minimumTapTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space2 + 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cell.label,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cell.value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Phần "ló ra" dưới thẻ bé đang chọn: một bé khác ⇒ chạm để đổi; từ hai bé khác ⇒ "+N bé" mở sheet chọn.
class OtherChildrenPeek extends StatelessWidget {
  const OtherChildrenPeek({
    super.key,
    required this.others,
    required this.onSelect,
    required this.onOpenPicker,
  });

  /// Các con không đang chọn; rỗng ⇒ không vẽ gì.
  final List<ChildSummary> others;
  final ValueChanged<ChildSummary> onSelect;
  final VoidCallback onOpenPicker;

  @override
  Widget build(BuildContext context) {
    if (others.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final single = others.length == 1;
    final first = others.first;
    final label = single
        ? '${first.shortName} · ${first.className}'
        : '+${others.length} bé khác';
    final hint = single ? 'Chạm để xem' : 'Xem tất cả';
    // Chữ phóng lớn ⇒ bỏ chữ gợi ý, chỉ giữ mũi tên để tên bé không bị ép
    final showHint = MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    final tint = AppStatusColors.of(context).tone(AppStatusTone.blue);
    return Semantics(
      button: true,
      label: single
          ? 'Xem bé ${first.fullName}, lớp ${first.className}'
          : 'Chọn trong ${others.length} bé khác',
      excludeSemantics: true,
      child: Material(
        color: tint.background,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xxl),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: single ? () => onSelect(first) : onOpenPicker,
          child: Padding(
            // Mép trên nằm dưới thẻ đang chọn ⇒ chừa thêm chỗ cho phần bị che
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space5,
              AppSpacing.space6 + AppSpacing.space1,
              AppSpacing.space4,
              AppSpacing.space3,
            ),
            child: Row(
              children: [
                single
                    ? AppAvatar(
                        name: first.fullName,
                        size: AppSizes.avatarSmall,
                      )
                    : const Icon(AppIcons.childFace, color: AppColors.primary),
                const SizedBox(width: AppSpacing.space3),
                Expanded(child: Text(label, style: textTheme.titleSmall)),
                if (showHint)
                  Text(
                    hint,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppStatusColors.of(context).link,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const Icon(
                  AppIcons.chevronRight,
                  color: AppColors.primary,
                  size: AppSizes.iconInline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Một ô trong lưới lối tắt.
@immutable
class UtilityItem {
  const UtilityItem(this.icon, this.label, this.onTap, {this.tone});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Tông của ô icon; null ⇒ theo `primary`.
  final AppStatusTone? tone;
}

/// Lưới 2 cột; mỗi hàng cao bằng ô cao nhất để chữ dài/chữ lớn không lệch hàng.
class UtilityGrid extends StatelessWidget {
  const UtilityGrid({super.key, required this.items});

  final List<UtilityItem> items;

  // Ô hẹp hơn mức này ⇒ chữ cạnh icon gãy 3–4 dòng; chuyển sang icon trên, chữ dưới
  static const double _minRowTileWidth = 160;

  @override
  Widget build(BuildContext context) {
    // Đo ở mức lưới: IntrinsicHeight bên dưới không cho dùng LayoutBuilder trong ô
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - AppSpacing.space3) / 2;
        final stacked = tileWidth < _minRowTileWidth;
        return Column(
          children: [
            for (var i = 0; i < items.length; i += 2) ...[
              if (i > 0) const SizedBox(height: AppSpacing.space3),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _UtilityTile(item: items[i], stacked: stacked),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: i + 1 < items.length
                          ? _UtilityTile(item: items[i + 1], stacked: stacked)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Ô lối tắt Clay: ô icon theo tông bên trái, tên bên phải; ô hẹp ⇒ icon trên, tên dưới.
class _UtilityTile extends StatelessWidget {
  const _UtilityTile({required this.item, required this.stacked});

  final UtilityItem item;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final icon = AppIconTile(icon: item.icon, tone: item.tone);
    final label = Text(
      item.label,
      style: Theme.of(context).textTheme.titleSmall,
    );
    return Semantics(
      container: true,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.card,
        ),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: item.onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        icon,
                        const SizedBox(height: AppSpacing.space3),
                        label,
                      ],
                    )
                  : Row(
                      children: [
                        icon,
                        const SizedBox(width: AppSpacing.space3),
                        Expanded(child: label),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

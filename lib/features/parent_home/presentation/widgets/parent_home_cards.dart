import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/features/parent_home/domain/parent_today.dart';
import 'package:carenest_app/features/parent_home/presentation/parent_home_status.dart';

/// Thẻ bé đang chọn đè lên dải đầu màn: tên, lớp, tuổi; chạm để mở hồ sơ, "Đổi bé" khi có nhiều con.
class ChildHeroCard extends StatelessWidget {
  const ChildHeroCard({
    super.key,
    required this.child,
    required this.onOpenProfile,
    this.onSwitchChild,
  });

  final ChildSummary child;
  final VoidCallback onOpenProfile;

  /// Null ⇒ phụ huynh chỉ có một con, không hiện "Đổi bé".
  final VoidCallback? onSwitchChild;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final link = AppStatusColors.of(context).link;
    return AppCard(
      flush: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label:
                  'Bé ${child.fullName}, lớp ${child.className}, '
                  '${child.ageLabel}. Xem hồ sơ',
              excludeSemantics: true,
              child: InkWell(
                onTap: onOpenProfile,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: Row(
                    children: [
                      const AppIconTile(icon: AppIcons.childFace, size: 48),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bé ${child.fullName}',
                              style: textTheme.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text.rich(
                              TextSpan(
                                text:
                                    'Lớp ${child.className} · ${child.ageLabel} · ',
                                children: [
                                  TextSpan(
                                    text: 'Xem hồ sơ ›',
                                    style: TextStyle(
                                      color: link,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
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
          if (onSwitchChild != null)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.space1,
                right: AppSpacing.space1,
              ),
              child: AppLinkButton(label: 'Đổi bé', onPressed: onSwitchChild),
            ),
        ],
      ),
    );
  }
}

/// Card "Hôm nay": mỗi dòng một mục (điểm danh, thực đơn, hoạt động), chạm để mở màn chi tiết.
class TodayCard extends StatelessWidget {
  const TodayCard({
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
    final status = AppStatusColors.of(context);
    final attendance = today.attendance;
    final arrived = today.arrivedAt;
    return AppCard(
      flush: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TodayRow(
              icon: attendance.icon,
              iconColor: status.tone(attendance.tone).main,
              label: 'Điểm danh',
              value: arrived == null
                  ? attendance.label
                  : '${attendance.label} lúc ${DateLabels.time24(arrived)}',
              onTap: onOpenAttendance,
            ),
            _TodayRow(
              icon: AppIcons.meal,
              iconColor: status.link,
              label: 'Thực đơn',
              value: today.menuPublished ? 'Đã công bố' : 'Chưa công bố',
              onTap: onOpenMenu,
            ),
            _TodayRow(
              icon: AppIcons.menuBook,
              iconColor: status.link,
              label: 'Hoạt động',
              value: today.activityTitle ?? 'Chưa có',
              onTap: onOpenActivities,
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayRow extends StatelessWidget {
  const _TodayRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSizes.minimumTapTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space2 + 2,
            ),
            child: Row(
              children: [
                Icon(icon, size: AppSizes.iconInline, color: iconColor),
                const SizedBox(width: AppSpacing.space4),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      children: [
                        TextSpan(
                          text: ' · $value',
                          style: const TextStyle(fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium,
                  ),
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
  const UtilityItem(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Lưới 2 cột; mỗi hàng cao bằng ô cao nhất để chữ dài/chữ lớn không lệch hàng.
class UtilityGrid extends StatelessWidget {
  const UtilityGrid({super.key, required this.items, this.iconOnTop = false});

  final List<UtilityItem> items;

  /// Trang chủ: icon trên, tên dưới; "Bé của tôi": icon cạnh tên.
  final bool iconOnTop;

  // Ô hẹp hơn mức này ⇒ chữ cạnh icon gãy 3–4 dòng; chuyển sang icon trên, chữ dưới
  static const double _minRowTileWidth = 150;

  @override
  Widget build(BuildContext context) {
    // Đo ở mức lưới: IntrinsicHeight bên dưới không cho dùng LayoutBuilder trong ô
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - AppSpacing.space3) / 2;
        final stacked = iconOnTop || tileWidth < _minRowTileWidth;
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

/// Ô lối tắt phẳng: card trắng viền mảnh, icon `primary` không nền.
class _UtilityTile extends StatelessWidget {
  const _UtilityTile({required this.item, required this.stacked});

  final UtilityItem item;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      item.icon,
      size: stacked ? AppSizes.iconNavigation : AppSizes.iconInline,
      color: AppStatusColors.of(context).link,
    );
    final textTheme = Theme.of(context).textTheme;
    // Ô icon cạnh tên hẹp ⇒ chữ nhỏ hơn một bậc cho vừa một dòng như Figma
    final label = Text(
      item.label,
      style: stacked
          ? textTheme.titleSmall
          : textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    );
    final radius = BorderRadius.circular(AppRadius.xxl);
    return Semantics(
      container: true,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: item.onTap,
          child: Padding(
            padding: stacked
                ? const EdgeInsets.all(AppSpacing.space4)
                : const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space3,
                    vertical: AppSpacing.space4,
                  ),
            child: stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      icon,
                      const SizedBox(height: AppSpacing.space2),
                      label,
                    ],
                  )
                : Row(
                    children: [
                      icon,
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(child: label),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

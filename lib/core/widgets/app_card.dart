import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';

/// Card Clay: trắng đặc, bo 28, viền sáng, bóng card; padding 20 (dày 16) (DESIGN.md §7.1).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.dense = false,
    this.flush = false,
    this.borderColor,
  });

  final Widget child;
  final bool dense;

  /// Không padding: dòng danh sách tự lo lề.
  final bool flush;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final padding = flush
        ? EdgeInsets.zero
        : EdgeInsets.all(
            dense ? AppSpacing.cardPaddingDense : AppSpacing.cardPadding,
          );
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.card,
        // Viền trắng mờ làm mép sáng của card clay, thay bóng trong mà Flutter không có
        border: borderColor == null
            ? Border.all(color: AppColors.surface.withValues(alpha: 0.85))
            : Border.all(color: borderColor!, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      padding: padding,
      child: child,
    );
  }
}

/// Card nổi bật của trang chủ (thẻ bé, thẻ lớp, số suất): nền chuyển nhẹ từ màu tông sang trắng,
/// bo 28, bóng card. Mỗi màn tối đa một thẻ này để giữ thứ bậc.
class AppFeaturedCard extends StatelessWidget {
  const AppFeaturedCard({super.key, required this.child, this.tint});

  final Widget child;

  /// Màu phủ góc trên trái; null ⇒ `brand`.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(AppColors.surface, tint ?? AppColors.brand, 0.26)!,
            AppColors.surface,
          ],
          stops: const [0, 0.72],
        ),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.85)),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

/// Đầu card: ô icon + tiêu đề + phần cuối (badge hoặc link).
class AppCardHeader extends StatelessWidget {
  const AppCardHeader({
    super.key,
    required this.title,
    this.icon,
    this.tone,
    this.trailing,
  });

  final String title;
  final IconData? icon;
  final AppStatusTone? tone;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final titleRow = Row(
      children: [
        if (icon != null) ...[
          AppIconTile(icon: icon!, tone: tone),
          const SizedBox(width: AppSpacing.space3),
        ],
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (trailing != null && !_stacked(context)) ...[
          const SizedBox(width: AppSpacing.space2),
          trailing!,
        ],
      ],
    );
    if (trailing == null || !_stacked(context)) return titleRow;
    // Chữ lớn ⇒ đưa badge/link xuống dòng thay vì cắt chữ (DESIGN.md §5.1)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleRow,
        const SizedBox(height: AppSpacing.space2),
        trailing!,
      ],
    );
  }

  static bool _stacked(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) > 1.3;
}

/// Ô icon tròn 40, nền chuyển nhẹ theo tông + quầng màu (Clay); mặc định theo `primary`.
class AppIconTile extends StatelessWidget {
  const AppIconTile({
    super.key,
    required this.icon,
    this.tone,
    this.size = AppSizes.iconTileSize,
  });

  final IconData icon;
  final AppStatusTone? tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final status = AppStatusColors.of(context);
    final colors = tone == null ? null : status.tone(tone!);
    final main = colors?.main ?? status.link;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(AppColors.surface, main, 0.26)!,
            Color.lerp(AppColors.surface, main, 0.09)!,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: AppShadows.tinted(main),
      ),
      child: Icon(
        icon,
        size: size * 0.55,
        color: colors?.foreground ?? status.link,
      ),
    );
  }
}

/// Link chữ trong đầu card; vùng chạm ≥48.
class AppLinkButton extends StatelessWidget {
  const AppLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        textStyle: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: Text(label),
    );
  }
}

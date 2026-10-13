import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';

/// Dòng danh sách cao ≥64; có đích thì cả dòng bấm được (DESIGN.md §7.1).
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.horizontalPadding = AppSpacing.space4,
    this.titleMaxLines = 2,
  });

  final String title;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final double horizontalPadding;
  final int titleMaxLines;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Chữ phóng lớn ⇒ đưa phần cuối (badge) xuống dưới tiêu đề thay vì ép tràn (DESIGN.md §5.1)
    final stackTrailing =
        trailing != null && MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.listRowMinHeight),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: AppSpacing.space3,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.space3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                  if (subtitle != null)
                    DefaultTextStyle.merge(
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                      child: subtitle!,
                    ),
                  if (stackTrailing) ...[
                    const SizedBox(height: AppSpacing.space2),
                    trailing!,
                  ],
                ],
              ),
            ),
            if (trailing != null && !stackTrailing) ...[
              const SizedBox(width: AppSpacing.space3),
              trailing!,
            ],
            if (showChevron) ...[
              const SizedBox(width: AppSpacing.space2),
              const Icon(
                AppIcons.chevronRight,
                size: AppSizes.iconInline,
                color: AppColors.textDisabled,
              ),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

/// Xếp các dòng với kẻ nhạt giữa chúng.
class AppDividedColumn extends StatelessWidget {
  const AppDividedColumn({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(),
          children[i],
        ],
      ],
    );
  }
}

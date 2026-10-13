import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_loading_dots.dart';

enum AppButtonVariant { primary, secondary, text, danger }

/// Nút viên thuốc cao 52 (nhỏ 44), chữ 16/700, không bóng (DESIGN.md §7.1).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.loadingLabel,
    this.expand = false,
    this.small = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final String? loadingLabel;
  final bool expand;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final height = small ? AppSizes.buttonSmallHeight : AppSizes.buttonHeight;
    final textStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontSize: small ? 15 : null);
    // Đang gửi ⇒ khóa nút để chặn gửi trùng
    final handler = isLoading ? null : onPressed;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          const AppLoadingDots(size: 7),
          const SizedBox(width: AppSpacing.space3),
          Flexible(
            child: Text(loadingLabel ?? label, overflow: TextOverflow.ellipsis),
          ),
        ] else ...[
          if (icon != null) ...[
            Icon(icon, size: AppSizes.iconInline),
            const SizedBox(width: AppSpacing.space2),
          ],
          Flexible(
            // Nút chữ được xuống dòng thay vì cắt; nút nền giữ một dòng
            child: variant == AppButtonVariant.text
                ? Text(label, maxLines: 2)
                : Text(label, overflow: TextOverflow.ellipsis),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: AppSpacing.space2),
            Icon(trailingIcon, size: AppSizes.iconInline),
          ],
        ],
      ],
    );
    final minimumSize = Size(expand ? double.infinity : 64, height);

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: handler,
        style: FilledButton.styleFrom(
          minimumSize: minimumSize,
          textStyle: textStyle,
        ),
        child: content,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: handler,
        style: OutlinedButton.styleFrom(
          minimumSize: minimumSize,
          textStyle: textStyle,
        ),
        child: content,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: handler,
        style: TextButton.styleFrom(textStyle: textStyle),
        child: content,
      ),
      AppButtonVariant.danger => _dangerButton(
        context,
        handler,
        minimumSize,
        textStyle,
        content,
      ),
    };
    return button;
  }

  // Danger dùng nền nhạt + chữ đậm, không nền đỏ đặc chữ trắng (§4.2)
  Widget _dangerButton(
    BuildContext context,
    VoidCallback? handler,
    Size minimumSize,
    TextStyle? textStyle,
    Widget content,
  ) {
    final danger = AppStatusColors.of(context).feedbackOf(AppFeedback.danger);
    return FilledButton(
      onPressed: handler,
      style: FilledButton.styleFrom(
        backgroundColor: danger.background,
        foregroundColor: danger.foreground,
        minimumSize: minimumSize,
        textStyle: textStyle,
      ),
      child: content,
    );
  }
}

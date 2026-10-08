import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/sizes.dart';

enum AppButtonVariant { primary, secondary, text, danger }

/// Nút chuẩn (DESIGN.md §7): đang tải ⇒ disabled + vòng tải để không gửi lặp.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final handler = isLoading ? null : onPressed;
    final child = _ButtonContent(
      label: label,
      icon: icon,
      isLoading: isLoading,
    );
    final scheme = Theme.of(context).colorScheme;

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: handler,
        child: child,
      ),
      AppButtonVariant.danger => FilledButton(
        onPressed: handler,
        style: FilledButton.styleFrom(
          backgroundColor: scheme.error,
          foregroundColor: scheme.onError,
        ),
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: handler,
        child: child,
      ),
      AppButtonVariant.text => TextButton(onPressed: handler, child: child),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.isLoading,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final Widget? leading = isLoading
        ? SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              // Theo màu chữ hiện tại của nút (kể cả trạng thái disabled)
              color: IconTheme.of(context).color,
              semanticsLabel: 'Đang xử lý',
            ),
          )
        : icon == null
        ? null
        : Icon(icon, size: 18);
    final text = Flexible(
      child: Text(label, textAlign: TextAlign.center, softWrap: true),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[
          leading,
          const SizedBox(width: AppSpacing.space2),
        ],
        text,
      ],
    );
  }
}

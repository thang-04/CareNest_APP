import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/motion.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';

/// Ô có nhãn nằm trong khung (Figma Bếp 06): nhãn nhỏ trên, giá trị dưới, khung trắng bo 8, lỗi dưới ô.
/// Ô chỉ đọc (giờ hệ thống ghi, ghi chú) dùng viền nhạt hơn ô nhập.
class BoxedField extends StatelessWidget {
  const BoxedField({
    super.key,
    required this.label,
    required this.child,
    this.isRequired = false,
    this.focused = false,
    this.readOnly = false,
    this.errorText,
    this.trailing,
    this.onTap,
    this.minHeight = 56,
  });

  final String label;
  final Widget child;
  final bool isRequired;
  final bool focused;
  final bool readOnly;
  final String? errorText;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final danger = AppStatusColors.of(context).feedbackOf(AppFeedback.danger);
    final hasError = errorText != null;
    final borderColor = hasError
        ? danger.foreground
        : focused
        ? AppColors.primary
        : readOnly
        ? AppColors.border
        : AppColors.borderStrong;
    final radius = BorderRadius.circular(AppRadius.control);
    Widget box = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space3,
        AppSpacing.space2,
        trailing == null ? AppSpacing.space3 : AppSpacing.space2,
        AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(
          color: borderColor,
          width: focused || hasError ? 1.5 : 1,
        ),
      ),
      child: Row(
        // Ô cao hơn nội dung (ghi chú, cặp ô chia đôi) ⇒ nhãn + giá trị bám đỉnh như Figma;
        // ô có icon cuối (chọn món) chỉ một dòng nên căn giữa
        crossAxisAlignment: trailing == null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    text: label,
                    children: [if (isRequired) const TextSpan(text: ' *')],
                  ),
                  style: textTheme.labelMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                DefaultTextStyle.merge(
                  style: textTheme.bodyLarge?.copyWith(fontSize: 15),
                  child: child,
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
    if (onTap != null) {
      box = Material(
        color: Colors.transparent,
        child: InkWell(borderRadius: radius, onTap: onTap, child: box),
      );
    }
    // Nhãn + giá trị (hoặc ô nhập) + thao tác bấm đọc thành một mục cho trình đọc màn hình
    box = MergeSemantics(
      child: Semantics(button: onTap != null, readOnly: readOnly, child: box),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        box,
        if (hasError) ...[
          const SizedBox(height: AppSpacing.space1 + 2),
          Text(
            errorText!,
            style: textTheme.bodyMedium?.copyWith(color: danger.foreground),
          ),
        ],
      ],
    );
  }
}

/// Ô nhập một dòng theo khung [BoxedField]; bấm vào khung là focus ô nhập.
class BoxedTextField extends StatefulWidget {
  const BoxedTextField({
    super.key,
    required this.label,
    required this.controller,
    this.isRequired = false,
    this.hint,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.minHeight = 56,
  });

  final String label;
  final TextEditingController controller;
  final bool isRequired;
  final String? hint;
  final String? errorText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final double minHeight;

  @override
  State<BoxedTextField> createState() => _BoxedTextFieldState();
}

class _BoxedTextFieldState extends State<BoxedTextField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = textTheme.bodyLarge?.copyWith(fontSize: 15);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      onTap: widget.enabled ? _focusNode.requestFocus : null,
      child: BoxedField(
        label: widget.label,
        isRequired: widget.isRequired,
        focused: _focusNode.hasFocus,
        errorText: widget.errorText,
        minHeight: widget.minHeight,
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          style: style,
          decoration: InputDecoration(
            isCollapsed: true,
            // Bỏ lề trong của theme ô nhập: khung ngoài đã có lề
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            hintText: widget.hint,
            hintStyle: style?.copyWith(color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}

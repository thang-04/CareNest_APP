import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/motion.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';

/// Ô nhập: nhãn trên, viên thuốc cao 52 (nhiều dòng bo 20), lỗi dưới ô (DESIGN.md §7.1).
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.labelSuffix,
    this.controller,
    this.hint,
    this.errorText,
    this.helperText,
    this.isPassword = false,
    this.multiline = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.leadingIcon,
    this.maxLength,
    this.inputFormatters,
  });

  final String label;
  final String? labelSuffix;
  final TextEditingController? controller;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final bool isPassword;
  final bool multiline;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;

  /// Icon trái khi mockup có (số điện thoại, mật khẩu).
  final IconData? leadingIcon;

  /// Giới hạn ký tự khi nhập; bộ đếm do màn tự hiện ở `helperText`.
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final _focusNode = FocusNode();
  bool _obscured = true;

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
    final theme = Theme.of(context);
    final textField = TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      obscureText: widget.isPassword && _obscured,
      keyboardType: widget.multiline
          ? TextInputType.multiline
          : widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      minLines: widget.multiline ? 3 : 1,
      maxLines: widget.multiline ? 6 : 1,
      onChanged: widget.onChanged,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        counterText: '',
        hintText: widget.hint,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: AppColors.textMuted,
        ),
      ),
    );

    return AppFieldFrame(
      label: widget.label,
      labelSuffix: widget.labelSuffix,
      errorText: widget.errorText,
      helperText: widget.helperText,
      focused: _focusNode.hasFocus,
      multiline: widget.multiline,
      enabled: widget.enabled,
      leading: widget.leadingIcon == null
          ? null
          : Icon(
              widget.leadingIcon,
              size: AppSizes.iconInline,
              color: AppColors.textMuted,
            ),
      trailing: widget.isPassword
          ? IconButton(
              tooltip: _obscured ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              onPressed: () => setState(() => _obscured = !_obscured),
              icon: Icon(
                _obscured ? AppIcons.eye : AppIcons.eyeOff,
                size: AppSizes.iconInline,
                color: AppColors.textMuted,
              ),
            )
          : null,
      child: textField,
    );
  }
}

/// Ô chọn ngày: cùng khung ô nhập, bấm mở bộ chọn do màn quyết định.
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppFieldFrame(
      label: label,
      compactLabel: true,
      onTap: onTap,
      trailing: const Padding(
        padding: EdgeInsets.only(right: AppSpacing.space4),
        child: Icon(
          AppIcons.calendar,
          size: AppSizes.iconInline,
          color: AppColors.textMuted,
        ),
      ),
      child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

/// Ô chọn một giá trị: cùng khung ô nhập, mũi tên xuống; màn tự mở `AppBottomSheet` để chọn.
class AppSelectField extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.labelSuffix,
  });

  final String label;
  final String? labelSuffix;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: AppFieldFrame(
        label: label,
        labelSuffix: labelSuffix,
        onTap: onTap,
        trailing: const Padding(
          padding: EdgeInsets.only(right: AppSpacing.space4),
          child: Icon(
            AppIcons.chevronDown,
            size: AppSizes.iconInline,
            color: AppColors.textMuted,
          ),
        ),
        child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}

/// Khung chung của ô nhập Clay: nền lõm nhẹ, viền mảnh, focus viền 2 + vòng 3 `focusRing`, nhãn, dòng gợi ý/lỗi.
class AppFieldFrame extends StatelessWidget {
  const AppFieldFrame({
    super.key,
    required this.label,
    required this.child,
    this.labelSuffix,
    this.errorText,
    this.helperText,
    this.focused = false,
    this.multiline = false,
    this.compactLabel = false,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String? labelSuffix;
  final Widget child;
  final String? errorText;
  final String? helperText;
  final bool focused;
  final bool multiline;
  final bool compactLabel;

  /// Khoá (vd. số điện thoại dùng để đăng nhập): nền `surfaceMuted`, không vòng focus.
  final bool enabled;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = AppStatusColors.of(context);
    final hasError = errorText != null;
    final borderColor = hasError
        ? status.feedbackOf(AppFeedback.danger).foreground
        : focused
        ? status.link
        : AppColors.borderStrong;
    final borderWidth = focused || hasError ? 2.0 : 1.0;
    final radius = BorderRadius.circular(
      multiline ? AppRadius.xl : AppRadius.pill,
    );

    Widget box = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      constraints: BoxConstraints(
        minHeight: multiline ? 104 : AppSizes.inputHeight,
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.space5,
        right: trailing == null ? AppSpacing.space5 : AppSpacing.space1,
        top: multiline ? AppSpacing.space3 + 2 : 0,
        bottom: multiline ? AppSpacing.space3 + 2 : 0,
      ),
      decoration: BoxDecoration(
        color: enabled ? null : AppColors.surfaceMuted,
        // Ô lõm vào: mép trên hơi tối, thay bóng trong của wireframe
        gradient: enabled
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.surfaceMuted, AppColors.surface],
                stops: [0, 0.4],
              )
            : null,
        borderRadius: radius,
        border: Border.all(
          color: enabled ? borderColor : AppColors.border,
          width: enabled ? borderWidth : 1,
        ),
        boxShadow: focused && enabled
            ? [BoxShadow(color: status.focusRing, spreadRadius: 3)]
            : null,
      ),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.space3),
          ],
          Expanded(child: child),
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

    final labelStyle = compactLabel
        ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)
        : theme.textTheme.titleSmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: [
              if (labelSuffix != null)
                TextSpan(
                  text: ' $labelSuffix',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: status.textMuted,
                  ),
                ),
            ],
          ),
          style: labelStyle,
        ),
        const SizedBox(height: AppSpacing.space2),
        box,
        if (hasError || helperText != null) ...[
          const SizedBox(height: AppSpacing.space1 + 2),
          Text(
            errorText ?? helperText!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: hasError
                  ? status.feedbackOf(AppFeedback.danger).foreground
                  : status.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

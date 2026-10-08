import 'package:flutter/material.dart';

import 'package:carenest_app/core/widgets/app_text_field.dart';

/// Ô mật khẩu có nút ẩn/hiện; giữ autofill để không chặn password manager.
class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    this.label = 'Mật khẩu',
    this.controller,
    this.errorText,
    this.helperText,
    this.isRequired = true,
    this.enabled = true,
    this.textInputAction,
    this.autofillHints = const [AutofillHints.password],
    this.focusNode,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final String? errorText;
  final String? helperText;
  final bool isRequired;
  final bool enabled;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      controller: widget.controller,
      errorText: widget.errorText,
      helperText: widget.helperText,
      isRequired: widget.isRequired,
      enabled: widget.enabled,
      obscureText: _obscured,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      enableSuggestions: false,
      autocorrect: false,
      focusNode: widget.focusNode,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      suffixIcon: IconButton(
        tooltip: _obscured ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        onPressed: widget.enabled
            ? () => setState(() => _obscured = !_obscured)
            : null,
      ),
    );
  }
}

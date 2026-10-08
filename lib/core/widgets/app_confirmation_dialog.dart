import 'package:flutter/material.dart';

import 'package:carenest_app/core/widgets/app_button.dart';

/// Dialog xác nhận: nút xác nhận ghi đúng tên hành động (vd. "Hủy phiếu"), không "OK".
class AppConfirmationDialog extends StatelessWidget {
  const AppConfirmationDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.message,
    this.cancelLabel = 'Quay lại',
    this.isDestructive = false,
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  /// Trả `true` khi người dùng xác nhận; đóng dialog bằng cách khác ⇒ `false`.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    String? message,
    String cancelLabel = 'Quay lại',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AppConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message!),
      actions: [
        AppButton(
          label: cancelLabel,
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          label: confirmLabel,
          variant: isDestructive
              ? AppButtonVariant.danger
              : AppButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_state_message.dart';

/// Lỗi tải dữ liệu: nêu vấn đề + nút thử lại, không đưa exception kỹ thuật lên UI.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.onRetry,
    this.title = 'Không thể tải dữ liệu',
    this.message = 'Hãy kiểm tra kết nối mạng rồi thử lại.',
    this.retryLabel = 'Thử lại',
    this.icon = Icons.error_outline,
  });

  final VoidCallback onRetry;
  final String title;
  final String? message;
  final String retryLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppStateMessage(
      icon: icon,
      iconColor: Theme.of(context).colorScheme.error,
      title: title,
      message: message,
      action: AppButton(
        label: retryLabel,
        icon: Icons.refresh,
        onPressed: onRetry,
        variant: AppButtonVariant.secondary,
      ),
    );
  }
}

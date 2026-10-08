import 'package:flutter/material.dart';

import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_state_message.dart';

/// Trạng thái rỗng có giải thích; CTA chỉ khi có hành động phù hợp.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppStateMessage(
      icon: icon,
      title: title,
      message: message,
      action: actionLabel != null && onAction != null
          ? AppButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: AppButtonVariant.secondary,
            )
          : null,
    );
  }
}

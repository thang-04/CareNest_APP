import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/features/account/domain/account_profile.dart';

/// Hỏi lại trước khi đăng xuất (mockup P19); trả `true` khi người dùng chọn "Đăng xuất".
Future<bool> confirmLogout(BuildContext context, AppRole role) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _LogoutConfirmDialog(role: role),
  );
  return confirmed ?? false;
}

class _LogoutConfirmDialog extends StatelessWidget {
  const _LogoutConfirmDialog({required this.role});

  final AppRole role;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final message = role == AppRole.parent
        ? 'Bạn sẽ không nhận được thông báo của bé cho đến khi đăng nhập lại.'
        : 'Bạn sẽ không nhận được thông báo cho đến khi đăng nhập lại.';
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(AppIcons.logout, color: AppColors.dangerText),
            ),
            const SizedBox(height: AppSpacing.space4),
            Semantics(
              header: true,
              child: Text(
                'Đăng xuất khỏi CareNest?',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.space5),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Ở lại',
                    variant: AppButtonVariant.secondary,
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: AppButton(
                    label: 'Đăng xuất',
                    variant: AppButtonVariant.danger,
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

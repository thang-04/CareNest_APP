import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/auth/presentation/controllers/auth_state.dart';
import 'package:carenest_app/features/auth/presentation/providers/auth_providers.dart';

/// Tài khoản đăng nhập được nhưng không dùng App: Ban giám hiệu/Admin (BE ADR-0022) hoặc tài khoản
/// bị khóa/chưa có hồ sơ (1015, 1014). Không tự thử lại; chỉ cho đăng xuất.
class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final reason = state is AuthBlocked
        ? state.reason
        : AuthBlockReason.accountUnavailable;
    final (title, message) = switch (reason) {
      AuthBlockReason.webOnlyAccount => (
        'Dùng trên Web',
        'Tài khoản này dùng trên Web CareNest.',
      ),
      AuthBlockReason.accountUnavailable => (
        'Chưa dùng được',
        'Tài khoản chưa dùng được. Vui lòng liên hệ nhà trường.',
      ),
    };
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: AppEmptyState(
              icon: AppIcons.lock,
              title: title,
              message: message,
              actionLabel: 'Đăng xuất',
              onAction: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_loading_dots.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/auth/presentation/controllers/auth_state.dart';
import 'package:carenest_app/features/auth/presentation/providers/auth_providers.dart';

/// Chờ khôi phục phiên lúc mở App; mất mạng hoặc BE/Keycloak tạm lỗi ⇒ "Thử lại", không đăng xuất.
class SessionLoadingScreen extends ConsumerWidget {
  const SessionLoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: state is AuthRetryNeeded
                ? AppErrorState(
                    title: 'Không kết nối được máy chủ',
                    message: 'Kiểm tra kết nối mạng rồi thử lại.',
                    onRetry: () =>
                        ref.read(authControllerProvider.notifier).retry(),
                  )
                : Semantics(label: 'Đang tải', child: const AppLoadingDots()),
          ),
        ),
      ),
    );
  }
}

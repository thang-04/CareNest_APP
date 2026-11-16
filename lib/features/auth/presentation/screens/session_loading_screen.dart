import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/errors/app_failure.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_loading_dots.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/auth/presentation/controllers/auth_state.dart';
import 'package:carenest_app/features/auth/presentation/providers/auth_providers.dart';

/// Chờ khôi phục phiên lúc mở App. Lỗi ⇒ "Thử lại" (giữ token) và "Đăng xuất" để không kẹt
/// khi lỗi kéo dài (máy dùng chung — AUTH-22).
class SessionLoadingScreen extends ConsumerWidget {
  const SessionLoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: state is AuthRetryNeeded
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isNetwork(state.failure)
                          ? AppErrorState(
                              title: 'Không kết nối được máy chủ',
                              message: 'Kiểm tra kết nối mạng rồi thử lại.',
                              onRetry: controller.retry,
                            )
                          : AppErrorState(
                              title: 'Chưa mở được tài khoản',
                              message:
                                  'Máy chủ đang gặp lỗi. Thử lại sau hoặc đăng xuất.',
                              onRetry: controller.retry,
                            ),
                      AppButton(
                        label: 'Đăng xuất',
                        variant: AppButtonVariant.text,
                        onPressed: controller.signOut,
                      ),
                    ],
                  )
                : Semantics(label: 'Đang tải', child: const AppLoadingDots()),
          ),
        ),
      ),
    );
  }

  static bool _isNetwork(AppFailure failure) =>
      failure is NetworkFailure ||
      failure is TimeoutFailure ||
      failure is ServiceUnavailableFailure;
}

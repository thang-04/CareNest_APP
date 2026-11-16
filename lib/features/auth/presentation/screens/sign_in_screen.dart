import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:carenest_app/core/config/app_info.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/brand/app_logo.dart';
import 'package:carenest_app/features/auth/presentation/controllers/auth_state.dart';
import 'package:carenest_app/features/auth/presentation/providers/auth_providers.dart';

/// Đăng nhập với BE thật: SĐT + mật khẩu nhập ở trang Keycloak (PKCE — BE AUTH_CONTRACT).
/// Bố cục giống màn Đăng nhập giả (Clay, logo giữa, card). Chưa có "Quên mật khẩu" (chờ BE, plan 16/11).
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key, this.onActivate});

  /// Mở "Kích hoạt tài khoản" (phụ huynh nhận mã SMS — ADR-0026).
  final VoidCallback? onActivate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(authControllerProvider);
    final notice = state is AuthSignedOut ? state.notice : null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ảnh logo có nền trắng: bo góc để không lộ khối vuông trên nền màn
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                      child: const ColoredBox(
                        color: AppColors.surface,
                        child: AppLogo(size: 140),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    AppInfo.schoolName,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space6),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          header: true,
                          child: Text('Đăng nhập', style: textTheme.titleLarge),
                        ),
                        const SizedBox(height: AppSpacing.space4),
                        if (notice != null) ...[
                          _NoticeBanner(notice: notice),
                          const SizedBox(height: AppSpacing.space4),
                        ],
                        Text(
                          'Tên đăng nhập là số điện thoại 10 số, bắt đầu bằng 0.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space4),
                        AppButton(
                          label: 'Đăng nhập',
                          loadingLabel: 'Đang mở trang đăng nhập...',
                          isLoading: state is AuthSigningIn,
                          expand: true,
                          onPressed: () => ref
                              .read(authControllerProvider.notifier)
                              .signIn(),
                        ),
                        if (onActivate != null) ...[
                          const SizedBox(height: AppSpacing.space2),
                          AppButton(
                            label: 'Kích hoạt tài khoản',
                            variant: AppButtonVariant.text,
                            expand: true,
                            onPressed: state is AuthSigningIn
                                ? null
                                : onActivate,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.notice});

  final AuthNotice notice;

  @override
  Widget build(BuildContext context) {
    return switch (notice) {
      AuthNotice.sessionExpired => const AppBanner(
        kind: AppBannerKind.warning,
        message: 'Phiên đăng nhập đã hết. Vui lòng đăng nhập lại.',
      ),
      AuthNotice.signInCancelled => const AppBanner(
        message: 'Bạn đã đóng trang đăng nhập.',
      ),
      AuthNotice.signInFailed => const AppBanner(
        kind: AppBannerKind.danger,
        message: 'Không đăng nhập được. Thử lại sau.',
      ),
    };
  }
}

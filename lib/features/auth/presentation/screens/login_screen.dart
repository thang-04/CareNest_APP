import 'package:flutter/material.dart';

import 'package:carenest_app/core/config/app_info.dart';
import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/core/widgets/brand/app_logo.dart';
import 'package:carenest_app/features/auth/presentation/widgets/auth_not_connected.dart';

/// Đăng nhập — Figma PH01 bản sửa: logo + tên trường, form ngay trên nền màn, ghi chú SMS, phiên bản ở đáy.
/// Chưa có AUTH_CONTRACT ⇒ `onSubmit`/`onForgotPassword` do tầng auth nối sau.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onSubmit,
    this.onForgotPassword,
    this.onOpenPreview,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final void Function(String account, String password)? onSubmit;
  final VoidCallback? onForgotPassword;

  /// Có giá trị chỉ ở bản debug: lối "Xem thử theo vai trò".
  final VoidCallback? onOpenPreview;
  final bool isSubmitting;
  final String? errorMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _account = TextEditingController();
  final _passwordInput = TextEditingController();
  String? _accountError;
  String? _passwordError;
  bool _showNotConnected = false;

  @override
  void dispose() {
    _account.dispose();
    _passwordInput.dispose();
    super.dispose();
  }

  // Chỉ kiểm bắt buộc để hỗ trợ nhập; đúng/sai tài khoản do BE quyết định
  void _submit() {
    setState(() {
      _accountError = _account.text.trim().isEmpty
          ? 'Nhập số điện thoại.'
          : null;
      _passwordError = _passwordInput.text.isEmpty ? 'Nhập mật khẩu.' : null;
      _showNotConnected = false;
    });
    if (_accountError != null || _passwordError != null) return;
    final onSubmit = widget.onSubmit;
    if (onSubmit == null) {
      setState(() => _showNotConnected = true);
      return;
    }
    onSubmit(_account.text.trim(), _passwordInput.text);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.space6),
            child: ConstrainedBox(
              // Đủ cao ⇒ dòng phiên bản nằm sát đáy như Figma; màn thấp hoặc chữ lớn ⇒ cuộn
              constraints: BoxConstraints(
                minHeight: viewport.maxHeight - AppSpacing.space6 * 2,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AutofillGroup(
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpacing.space4),
                          // Ảnh logo nền trắng: nhân với màu nền ⇒ khối trắng hòa vào nền màn
                          const Center(
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                AppColors.background,
                                BlendMode.multiply,
                              ),
                              child: AppLogo(size: 136),
                            ),
                          ),
                          Text(
                            AppInfo.schoolName,
                            textAlign: TextAlign.center,
                            style: muted,
                          ),
                          const SizedBox(height: AppSpacing.space8),
                          if (widget.errorMessage != null) ...[
                            AppBanner(
                              kind: AppBannerKind.danger,
                              message: widget.errorMessage!,
                            ),
                            const SizedBox(height: AppSpacing.space4),
                          ],
                          if (_showNotConnected) ...[
                            authNotConnectedBanner,
                            const SizedBox(height: AppSpacing.space4),
                          ],
                          AppTextField(
                            label: 'Số điện thoại',
                            hint: 'Nhập số điện thoại',
                            leadingIcon: AppIcons.phone,
                            controller: _account,
                            errorText: _accountError,
                            enabled: !widget.isSubmitting,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username],
                          ),
                          const SizedBox(height: AppSpacing.space4),
                          AppTextField(
                            label: 'Mật khẩu',
                            hint: 'Nhập mật khẩu',
                            leadingIcon: AppIcons.lock,
                            controller: _passwordInput,
                            errorText: _passwordError,
                            isPassword: true,
                            enabled: !widget.isSubmitting,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: AppButton(
                              label: 'Quên mật khẩu?',
                              variant: AppButtonVariant.text,
                              onPressed:
                                  widget.onForgotPassword ??
                                  () =>
                                      setState(() => _showNotConnected = true),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space2),
                          AppButton(
                            label: 'Đăng nhập',
                            loadingLabel: 'Đang đăng nhập',
                            isLoading: widget.isSubmitting,
                            expand: true,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: AppSpacing.space6),
                          const AppBanner(
                            message:
                                'Tài khoản do nhà trường cấp qua SMS. Lần đầu đăng nhập: đổi mật khẩu.',
                          ),
                          const Spacer(),
                          const SizedBox(height: AppSpacing.space6),
                          if (widget.onOpenPreview != null) ...[
                            Center(
                              child: AppButton(
                                label: 'Xem thử theo vai trò',
                                variant: AppButtonVariant.text,
                                onPressed: widget.onOpenPreview,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space2),
                          ],
                          Text(
                            'Phiên bản v${AppInfo.version}',
                            textAlign: TextAlign.center,
                            style: muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

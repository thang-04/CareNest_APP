import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_otp_field.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/auth/data/activation_api.dart';

/// Kích hoạt tài khoản phụ huynh bằng mã SMS (BE AUTH-18, ADR-0026): đặt mật khẩu rồi đăng nhập Keycloak
/// với tên đăng nhập BE trả. Kiểm ở App chỉ hỗ trợ nhập; BE kiểm lại mã và mật khẩu.
class ActivationScreen extends StatefulWidget {
  const ActivationScreen({
    super.key,
    required this.api,
    required this.signInAs,
  });

  final ActivationGateway api;

  /// Mở trang Keycloak có sẵn tên đăng nhập BE trả.
  final Future<void> Function(String username) signInAs;

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  static final _phonePattern = RegExp(r'^0\d{9}$');
  static final _codePattern = RegExp(r'^\d{6}$');

  final _phone = TextEditingController();
  final _pwInput = TextEditingController();
  final _pwConfirmInput = TextEditingController();
  String _code = '';

  String? _phoneError;
  String? _codeError;
  String? _pwError;
  String? _confirmError;
  String? _banner;
  bool _submitting = false;
  bool _signingIn = false;
  String? _signInError;
  String? _activatedUsername;

  @override
  void dispose() {
    _phone.dispose();
    _pwInput.dispose();
    _pwConfirmInput.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Chặn gửi trùng: mã kích hoạt chỉ dùng được một lần
    if (_submitting) return;
    final phone = _phone.text.replaceAll(RegExp(r'[\s.\-()]'), '');
    final pw = _pwInput.text;
    setState(() {
      _banner = null;
      _phoneError = _phonePattern.hasMatch(phone)
          ? null
          : 'Nhập số điện thoại 10 số, bắt đầu bằng 0.';
      _codeError = _codePattern.hasMatch(_code)
          ? null
          : 'Nhập đủ 6 số của mã kích hoạt.';
      _pwError = pw.length >= 8 && pw.length <= 128
          ? null
          : 'Mật khẩu từ 8 đến 128 ký tự.';
      _confirmError = _pwConfirmInput.text == pw
          ? null
          : 'Hai mật khẩu chưa khớp.';
    });
    if ([
      _phoneError,
      _codeError,
      _pwError,
      _confirmError,
    ].any((error) => error != null)) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final username = await widget.api.activate(
        phone: phone,
        code: _code,
        newPassword: pw,
        confirmPassword:
            _pwConfirmInput.text, // carenest:allow-secret — tên tham số API
      );
      if (!mounted) return;
      // Xong form ⇒ xóa mật khẩu khỏi bộ nhớ (CODING_GUIDE §5.3)
      _pwInput.clear();
      _pwConfirmInput.clear();
      setState(() {
        _submitting = false;
        _activatedUsername = username;
      });
      await _signIn(username);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _showFailure(error);
      });
    }
  }

  Future<void> _signIn(String username) async {
    // Trang Keycloak đang mở ⇒ bỏ lượt bấm thêm (AppAuth Android từ chối 2 lượt cùng lúc)
    if (_signingIn) return;
    setState(() {
      _signingIn = true;
      _signInError = null;
    });
    try {
      await widget.signInAs(username);
    } on FlutterAppAuthUserCancelledException {
      // Người dùng tự đóng trang Keycloak ⇒ không báo lỗi
    } catch (_) {
      if (mounted) {
        setState(
          () => _signInError =
              'Chưa mở được trang đăng nhập. Kiểm tra mạng rồi bấm Đăng nhập.',
        );
      }
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  // Phân nhánh theo status + errorCode BE, không theo nội dung desc
  void _showFailure(Object error) {
    switch (error) {
      case ApiFailure(status: 400, errorCode: 1006):
        _banner =
            'Mã kích hoạt sai hoặc đã hết hạn. Liên hệ nhà trường để gửi lại mã.';
      case ApiFailure(status: 400, errorCode: 1009, :final message):
        _pwError = message;
      case ApiFailure(:final status) when status >= 500:
        _banner = 'Không kết nối được máy chủ. Thử lại sau.';
      case ApiFailure(:final message):
        _banner = message;
      default:
        _banner = 'Không kết nối được máy chủ. Thử lại sau.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = _activatedUsername;
    return Scaffold(
      appBar: AppBar(title: const Text('Kích hoạt tài khoản')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            if (username == null) _form(context) else _done(context, username),
          ],
        ),
      ),
    );
  }

  Widget _done(BuildContext context, String username) {
    final textTheme = Theme.of(context).textTheme;
    final signingIn = _signingIn;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tài khoản đã kích hoạt', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.space2),
          Text(
            'Tên đăng nhập: $username. Đăng nhập bằng mật khẩu bạn vừa đặt.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (_signInError != null) ...[
            const SizedBox(height: AppSpacing.space4),
            AppBanner(kind: AppBannerKind.danger, message: _signInError!),
          ],
          const SizedBox(height: AppSpacing.space4),
          AppButton(
            label: 'Đăng nhập',
            loadingLabel: 'Đang mở trang đăng nhập...',
            isLoading: signingIn,
            expand: true,
            onPressed: () => _signIn(username),
          ),
        ],
      ),
    );
  }

  Widget _form(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final danger = AppStatusColors.of(context).feedbackOf(AppFeedback.danger);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Nhập mã 6 số trong tin nhắn nhà trường gửi.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.space4),
        if (_banner != null) ...[
          AppBanner(kind: AppBannerKind.danger, message: _banner!),
          const SizedBox(height: AppSpacing.space4),
        ],
        AppTextField(
          label: 'Số điện thoại',
          hint: 'Nhập số điện thoại',
          controller: _phone,
          errorText: _phoneError,
          enabled: !_submitting,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
        ),
        const SizedBox(height: AppSpacing.space4),
        Text('Mã kích hoạt', style: textTheme.labelLarge),
        const SizedBox(height: AppSpacing.space2),
        AppOtpField(onChanged: (value) => _code = value),
        if (_codeError != null) ...[
          const SizedBox(height: AppSpacing.space1),
          Text(
            _codeError!,
            style: textTheme.bodySmall?.copyWith(color: danger.foreground),
          ),
        ],
        const SizedBox(height: AppSpacing.space4),
        AppTextField(
          label: 'Mật khẩu mới',
          hint: 'Từ 8 ký tự',
          controller: _pwInput,
          errorText: _pwError,
          isPassword: true,
          enabled: !_submitting,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
        ),
        const SizedBox(height: AppSpacing.space4),
        AppTextField(
          label: 'Nhập lại mật khẩu mới',
          controller: _pwConfirmInput,
          errorText: _confirmError,
          isPassword: true,
          enabled: !_submitting,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
        ),
        const SizedBox(height: AppSpacing.space5),
        AppButton(
          label: 'Kích hoạt',
          loadingLabel: 'Đang kích hoạt...',
          isLoading: _submitting,
          expand: true,
          onPressed: _submit,
        ),
      ],
    );
  }
}

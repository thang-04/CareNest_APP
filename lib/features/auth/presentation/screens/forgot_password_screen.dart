import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/auth/presentation/widgets/auth_not_connected.dart';

/// Quên mật khẩu — mockup P15. Gửi mã OTP là việc của BE (AUTH_CONTRACT chưa có).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.onSendCode});

  /// Null ⇒ chưa nối máy chủ: hiện banner thay vì giả vờ đã gửi.
  final ValueChanged<String>? onSendCode;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phone = TextEditingController();
  String? _error;
  bool _showNotConnected = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  // Chỉ kiểm bắt buộc; số có thuộc trường không do BE trả lời
  void _submit() {
    final phone = _phone.text.trim();
    setState(() {
      _error = phone.isEmpty ? 'Nhập số điện thoại.' : null;
      _showNotConnected = false;
    });
    if (_error != null) return;
    final onSendCode = widget.onSendCode;
    if (onSendCode == null) {
      setState(() => _showNotConnected = true);
      return;
    }
    onSendCode(phone);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Quên mật khẩu')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Text(
            'Nhập số điện thoại đã đăng ký với nhà trường. CareNest sẽ gửi mã OTP gồm 6 số qua SMS.',
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          if (_showNotConnected) ...[
            authNotConnectedBanner,
            const SizedBox(height: AppSpacing.space4),
          ],
          AppTextField(
            label: 'Số điện thoại',
            labelSuffix: '*',
            hint: 'Nhập số điện thoại',
            controller: _phone,
            errorText: _error,
            leadingIcon: AppIcons.phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
          ),
        ],
      ),
      bottomNavigationBar: AppBottomDock(
        children: [
          AppButton(label: 'Gửi mã OTP', expand: true, onPressed: _submit),
        ],
      ),
    );
  }
}

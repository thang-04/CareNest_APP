import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/auth/presentation/widgets/auth_not_connected.dart';

/// Đặt / đổi mật khẩu — mockup P17. Dùng sau OTP, lần đầu đăng nhập,
/// hoặc từ Tài khoản (`requireCurrent`). Chính sách mật khẩu thật do BE kiểm lại.
class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({
    super.key,
    this.requireCurrent = false,
    this.onSave,
  });

  final bool requireCurrent;

  /// (mật khẩu hiện tại hoặc null, mật khẩu mới). Null ⇒ chưa nối máy chủ.
  final void Function(String? current, String next)? onSave;

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _showNotConnected = false;
  String? _currentError;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  // Gợi ý định dạng để hỗ trợ nhập (format), không thay kiểm tra ở BE
  bool get _longEnough => _next.text.length >= 8;
  bool get _hasLetterAndDigit =>
      RegExp(r'[A-Za-zÀ-ỹ]').hasMatch(_next.text) &&
      RegExp(r'\d').hasMatch(_next.text);
  bool get _matches => _next.text.isNotEmpty && _next.text == _confirm.text;

  void _save() {
    setState(() {
      _currentError = widget.requireCurrent && _current.text.isEmpty
          ? 'Nhập mật khẩu hiện tại.'
          : null;
      _showNotConnected = false;
    });
    if (_currentError != null) return;
    final onSave = widget.onSave;
    if (onSave == null) {
      setState(() => _showNotConnected = true);
      return;
    }
    onSave(widget.requireCurrent ? _current.text : null, _next.text);
  }

  @override
  Widget build(BuildContext context) {
    final ready = _longEnough && _hasLetterAndDigit && _matches;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.requireCurrent ? 'Đổi mật khẩu' : 'Đặt mật khẩu mới',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          AppBanner(
            message: widget.requireCurrent
                ? 'Nhập mật khẩu hiện tại rồi đặt mật khẩu mới.'
                : 'Đặt mật khẩu mới để tiếp tục dùng CareNest.',
          ),
          const SizedBox(height: AppSpacing.space5),
          if (_showNotConnected) ...[
            authNotConnectedBanner,
            const SizedBox(height: AppSpacing.space4),
          ],
          if (widget.requireCurrent) ...[
            AppTextField(
              label: 'Mật khẩu hiện tại',
              labelSuffix: '*',
              controller: _current,
              errorText: _currentError,
              isPassword: true,
              autofillHints: const [AutofillHints.password],
            ),
            const SizedBox(height: AppSpacing.space4),
          ],
          AppTextField(
            label: 'Mật khẩu mới',
            labelSuffix: '*',
            controller: _next,
            isPassword: true,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.space4),
          AppTextField(
            label: 'Nhập lại mật khẩu',
            labelSuffix: '*',
            controller: _confirm,
            isPassword: true,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.space3),
          _Requirement(label: 'Ít nhất 8 ký tự', met: _longEnough),
          _Requirement(label: 'Có cả chữ và số', met: _hasLetterAndDigit),
          _Requirement(label: 'Hai mật khẩu trùng khớp', met: _matches),
        ],
      ),
      bottomNavigationBar: AppBottomDock(
        children: [
          AppButton(
            label: 'Lưu mật khẩu',
            expand: true,
            onPressed: ready ? _save : null,
          ),
        ],
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final success = AppStatusColors.of(context).feedbackOf(AppFeedback.success);
    final color = met ? success.foreground : AppColors.textMuted;
    return Semantics(
      container: true,
      label: '$label: ${met ? 'đạt' : 'chưa đạt'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.space1),
        child: Row(
          children: [
            Icon(
              met ? AppIcons.check : AppIcons.circle,
              size: AppSizes.iconBadge,
              color: color,
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

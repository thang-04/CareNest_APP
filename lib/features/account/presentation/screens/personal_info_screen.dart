import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/account/data/fake_account_source.dart';
import 'package:carenest_app/features/account/domain/account_profile.dart';

/// Thông tin cá nhân — mockup P18. Số điện thoại là tài khoản đăng nhập ⇒ khoá.
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({
    super.key,
    required this.role,
    this.source = const FakeAccountSource(),
    this.onSave,
  });

  final AppRole role;
  final AccountSource source;

  /// (họ tên, email). Null ⇒ chưa nối máy chủ.
  final void Function(String fullName, String email)? onSave;

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  bool _loaded = false;
  bool _showNotConnected = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    widget.source.loadProfile(widget.role).then((profile) {
      if (!mounted) return;
      setState(() {
        _name.text = profile.fullName;
        _phone.text = profile.phone;
        _email.text = profile.email ?? '';
        _loaded = true;
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _save() {
    setState(() {
      _nameError = _name.text.trim().isEmpty ? 'Nhập họ và tên.' : null;
      _showNotConnected = false;
    });
    if (_nameError != null) return;
    final onSave = widget.onSave;
    if (onSave == null) {
      setState(() => _showNotConnected = true);
      return;
    }
    onSave(_name.text.trim(), _email.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin cá nhân')),
      body: !_loaded
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonCard(),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                if (_showNotConnected) ...[
                  const AppBanner(
                    message:
                        'Lưu thông tin chưa được kết nối với máy chủ trong bản này.',
                  ),
                  const SizedBox(height: AppSpacing.space4),
                ],
                AppTextField(
                  label: 'Họ và tên',
                  controller: _name,
                  errorText: _nameError,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: AppSpacing.space4),
                AppTextField(
                  label: 'Số điện thoại',
                  labelSuffix: '(dùng để đăng nhập)',
                  controller: _phone,
                  enabled: false,
                ),
                const SizedBox(height: AppSpacing.space4),
                AppTextField(
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                ),
              ],
            ),
      bottomNavigationBar: AppBottomDock(
        children: [
          AppButton(
            label: 'Lưu thay đổi',
            expand: true,
            onPressed: _loaded ? _save : null,
          ),
        ],
      ),
    );
  }
}

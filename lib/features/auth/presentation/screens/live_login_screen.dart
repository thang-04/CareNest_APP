import 'package:flutter/material.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/brand/app_logo.dart';

class LiveLoginScreen extends StatefulWidget {
  const LiveLoginScreen({
    super.key,
    required this.signIn,
    this.onPreview,
    this.onActivate,
  });
  final Future<void> Function() signIn;
  final VoidCallback? onPreview;

  /// Phụ huynh nhận mã kích hoạt qua SMS (AUTH-18, ADR-0026).
  final VoidCallback? onActivate;
  @override
  State<LiveLoginScreen> createState() => _LiveLoginScreenState();
}

class _LiveLoginScreenState extends State<LiveLoginScreen> {
  bool busy = false;
  Object? error;
  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.signIn();
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 140),
                  const SizedBox(height: AppSpacing.space4),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Đăng nhập',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.space4),
                        const Text(
                          'Đăng nhập bằng tài khoản nhà trường qua trang đăng nhập bảo mật.',
                        ),
                        const SizedBox(height: AppSpacing.space4),
                        if (error != null)
                          Text(
                            '$error',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        AppButton(
                          label: 'Đăng nhập',
                          loadingLabel: 'Đang đăng nhập…',
                          isLoading: busy,
                          expand: true,
                          onPressed: submit,
                        ),
                        if (widget.onActivate != null)
                          AppLinkButton(
                            label: 'Kích hoạt tài khoản',
                            onPressed: busy ? null : widget.onActivate,
                          ),
                      ],
                    ),
                  ),
                  if (widget.onPreview != null)
                    TextButton(
                      onPressed: widget.onPreview,
                      child: const Text('Xem thử theo vai trò'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

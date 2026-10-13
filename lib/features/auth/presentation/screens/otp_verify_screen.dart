import 'dart:async';

import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_otp_field.dart';
import 'package:carenest_app/features/auth/presentation/widgets/auth_not_connected.dart';

/// Xác thực OTP — mockup P16. Mã đúng/sai và hạn gửi lại do BE quyết định.
class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({
    super.key,
    this.maskedPhone,
    this.resendAfter = const Duration(seconds: 45),
    this.onVerify,
    this.onResend,
  });

  /// Số đã che bớt BE trả, vd. "091•••••678"; không có ⇒ câu chung.
  final String? maskedPhone;

  /// Thời gian chờ gửi lại; số thật lấy từ BE.
  final Duration resendAfter;

  /// Null ⇒ chưa nối máy chủ.
  final ValueChanged<String>? onVerify;
  final VoidCallback? onResend;

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  String _code = '';
  late Duration _remaining = widget.resendAfter;
  Timer? _timer;
  bool _showNotConnected = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _remaining = widget.resendAfter;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds <= 1) timer.cancel();
      setState(() => _remaining -= const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _verify() {
    final onVerify = widget.onVerify;
    if (onVerify == null) {
      setState(() => _showNotConnected = true);
      return;
    }
    onVerify(_code);
  }

  void _resend() {
    widget.onResend?.call();
    setState(_startCountdown);
  }

  String get _countdownLabel {
    final minutes = _remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canResend = _remaining.inSeconds <= 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực OTP')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Text.rich(
            TextSpan(
              text: 'Nhập mã 6 số đã gửi qua SMS đến ',
              children: [
                TextSpan(
                  text: widget.maskedPhone ?? 'số điện thoại của bạn',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          if (_showNotConnected) ...[
            authNotConnectedBanner,
            const SizedBox(height: AppSpacing.space4),
          ],
          AppOtpField(
            autofocus: true,
            onChanged: (value) => setState(() => _code = value),
          ),
          const SizedBox(height: AppSpacing.space4),
          Center(
            child: canResend
                ? AppButton(
                    label: 'Gửi lại mã',
                    variant: AppButtonVariant.text,
                    onPressed: _resend,
                  )
                : Text.rich(
                    TextSpan(
                      text: 'Gửi lại mã sau ',
                      children: [
                        TextSpan(
                          text: _countdownLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomDock(
        children: [
          AppButton(
            label: 'Xác nhận mã',
            expand: true,
            onPressed: _code.length == 6 ? _verify : null,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_bottom_sheet.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/teacher/pickup/data/fake_pickup_source.dart';
import 'package:carenest_app/features/teacher/pickup/domain/pickup.dart';

/// Trả trẻ một bé — mockup T06, field theo BE `PickupChildResponse` / `PickupRequest` (PCK-02):
/// GV so người đón với ảnh phụ huynh trên hồ sơ. Khớp ⇒ "Trả trẻ" (PHOTO_MATCH). Không khớp hoặc
/// chưa có ảnh ⇒ gọi phụ huynh rồi ghi nội dung cuộc gọi: trả (PHONE_CONFIRMED) hoặc không trả
/// (PHONE_DECLINED). Giờ trả lấy giờ hiện tại; BE ghi người đón và báo phụ huynh (PCK-04).
class PickupVerifyScreen extends StatefulWidget {
  const PickupVerifyScreen({
    super.key,
    required this.childId,
    required this.onDone,
    this.source,
    this.now,
  });

  final String childId;
  final VoidCallback onDone;
  final PickupSource? source;

  /// Đồng hồ cho test; mặc định giờ máy (BE vẫn kiểm tra giờ trả không sau hiện tại).
  final DateTime Function()? now;

  @override
  State<PickupVerifyScreen> createState() => _PickupVerifyScreenState();
}

class _PickupVerifyScreenState extends State<PickupVerifyScreen> {
  late final PickupSource _source = widget.source ?? FakePickupSource.shared;
  PickupChild? _child;
  Object? _error;
  bool _saving = false;
  String? _saveError;
  String? _callError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final child = await _source.loadChild(widget.childId);
      if (mounted) setState(() => _child = child);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  String _handoverTime() {
    final now = (widget.now ?? DateTime.now)();
    return DateLabels.time24(now);
  }

  Future<void> _submit(PickupRequest request) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await _source.record(request);
      if (!mounted) return;
      widget.onDone();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'Chưa ghi nhận được. Kiểm tra mạng rồi thử lại.';
      });
    }
  }

  /// Mở trình quay số của máy; không gọi được (máy tính bảng không SIM…) ⇒ báo và hiện số để gọi tay.
  Future<void> _call(PickupGuardian guardian) async {
    final uri = Uri(scheme: 'tel', path: guardian.phone);
    setState(() => _callError = null);
    final opened = await canLaunchUrl(uri) && await launchUrl(uri);
    if (!opened && mounted) {
      setState(
        () => _callError =
            'Không mở được trình gọi. Gọi tay số ${guardian.phone}.',
      );
    }
  }

  void _handOver(PickupGuardian guardian) => _submit(
    PickupRequest(
      childId: widget.childId,
      verification: PickupVerification.photoMatch,
      guardianPosition: guardian.position,
      handoverTime: _handoverTime(),
    ),
  );

  Future<void> _recordCall() async {
    final result = await showAppBottomSheet<(PickupVerification, String)>(
      context: context,
      title: 'Ghi kết quả gọi phụ huynh',
      builder: (_) => const _CallOutcomeForm(),
    );
    if (result == null) return;
    final (verification, note) = result;
    await _submit(
      PickupRequest(
        childId: widget.childId,
        verification: verification,
        handoverTime: verification.handedOver ? _handoverTime() : null,
        note: note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = _child;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Trả trẻ')),
      body: _error != null
          ? Center(
              child: AppErrorState(
                title: 'Chưa tải được thông tin bé',
                message: 'Kiểm tra kết nối mạng rồi thử lại.',
                onRetry: _load,
              ),
            )
          : child == null
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 3),
            )
          : child.row.status != PickupStatus.waiting
          ? const Center(
              child: AppEmptyState(
                icon: AppIcons.checkCircle,
                title: 'Không có bé chờ trả',
                message: 'Bé đã được đón hoặc không có mặt hôm nay.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                AppCard(
                  dense: true,
                  child: Row(
                    children: [
                      const _Photo(size: 64),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child.row.fullName,
                              style: textTheme.titleMedium,
                            ),
                            Text(
                              '${child.className} · chờ đón',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Text('Phụ huynh', style: textTheme.titleSmall),
                const SizedBox(height: AppSpacing.space3),
                if (child.guardians.isEmpty)
                  const AppBanner(
                    kind: AppBannerKind.warning,
                    message:
                        'Hồ sơ bé chưa có phụ huynh. Liên hệ BGH trước khi trả trẻ.',
                  ),
                for (final guardian in child.guardians) ...[
                  _GuardianCard(
                    guardian: guardian,
                    enabled: !_saving,
                    onHandOver: () => _handOver(guardian),
                    onCall: () => _call(guardian),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                ],
                AppButton(
                  label: 'Ghi kết quả gọi',
                  icon: AppIcons.call,
                  variant: AppButtonVariant.secondary,
                  expand: true,
                  onPressed: _saving ? null : _recordCall,
                ),
                if (_saveError != null) ...[
                  const SizedBox(height: AppSpacing.space3),
                  AppBanner(kind: AppBannerKind.danger, message: _saveError!),
                ],
                if (_callError != null) ...[
                  const SizedBox(height: AppSpacing.space3),
                  AppBanner(kind: AppBannerKind.warning, message: _callError!),
                ],
              ],
            ),
    );
  }
}

/// Ảnh giữ chỗ: bản giả không dùng ảnh người thật; ảnh thật chỉ tải qua URL có auth.
class _Photo extends StatelessWidget {
  const _Photo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(AppIcons.person, size: size * 0.55, color: AppColors.primary),
    );
  }
}

class _GuardianCard extends StatelessWidget {
  const _GuardianCard({
    required this.guardian,
    required this.enabled,
    required this.onHandOver,
    required this.onCall,
  });

  final PickupGuardian guardian;
  final bool enabled;
  final VoidCallback onHandOver;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasPhoto = guardian.photoUrl != null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _Photo(size: 96),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${guardian.relationship.label} – ${guardian.fullName}',
                      style: textTheme.titleSmall,
                    ),
                    Text(
                      guardian.phone,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (!hasPhoto)
                      Text(
                        'Chưa có ảnh',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Gọi',
                  icon: AppIcons.call,
                  variant: AppButtonVariant.secondary,
                  small: true,
                  onPressed: enabled ? onCall : null,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Semantics(
                  label:
                      'Trả trẻ cho ${guardian.relationship.label} ${guardian.fullName}',
                  excludeSemantics: true,
                  button: true,
                  child: AppButton(
                    label: 'Trả trẻ',
                    small: true,
                    // Chưa có ảnh thì không đối chiếu được ⇒ phải gọi (PCK-02)
                    onPressed: enabled && hasPhoto ? onHandOver : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sheet ghi kết quả cuộc gọi: ghi chú bắt buộc ở cả hai lựa chọn (BE `PickupRequest`).
class _CallOutcomeForm extends StatefulWidget {
  const _CallOutcomeForm();

  @override
  State<_CallOutcomeForm> createState() => _CallOutcomeFormState();
}

class _CallOutcomeFormState extends State<_CallOutcomeForm> {
  final _note = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _finish(PickupVerification verification) {
    final note = _note.text.trim();
    if (note.isEmpty) {
      setState(() => _error = 'Ghi nội dung cuộc gọi với phụ huynh.');
      return;
    }
    Navigator.of(context).pop((verification, note));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Nội dung cuộc gọi',
          hint: 'Mẹ xác nhận nhờ cô Hoa (hàng xóm) đón',
          controller: _note,
          errorText: _error,
          multiline: true,
          maxLength: 500,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: AppSpacing.space3),
        AppButton(
          label: 'Trả trẻ',
          expand: true,
          onPressed: () => _finish(PickupVerification.phoneConfirmed),
        ),
        const SizedBox(height: AppSpacing.space2),
        AppButton(
          label: 'Không trả',
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: () => _finish(PickupVerification.phoneDeclined),
        ),
      ],
    );
  }
}

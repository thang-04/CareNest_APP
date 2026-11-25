import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_bottom_sheet.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
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
  int? _selectedGuardianPosition;

  /// Giờ trả GV chọn; null = giờ hiện tại (PCK-04: bắt buộc, không sau giờ hiện tại).
  TimeOfDay? _pickedTime;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final child = await _source.loadChild(widget.childId);
      if (mounted) {
        setState(() {
          _child = child;
          final guardiansWithPhoto = child.guardians
              .where((guardian) => guardian.photoUrl != null)
              .toList();
          _selectedGuardianPosition = guardiansWithPhoto.length == 1
              ? guardiansWithPhoto.single.position
              : null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  DateTime _now() => (widget.now ?? DateTime.now)();

  String _handoverTime() {
    final now = _now();
    final picked = _pickedTime;
    if (picked == null) return DateLabels.time24(now);
    return DateLabels.time24(
      DateTime(now.year, now.month, now.day, picked.hour, picked.minute),
    );
  }

  Future<void> _chooseTime() async {
    final now = _now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _pickedTime ?? TimeOfDay.fromDateTime(now),
      helpText: 'Giờ trả trẻ',
    );
    if (picked == null || !mounted) return;
    // Không cho giờ sau hiện tại (BE kiểm tra lại)
    final late = picked.hour * 60 + picked.minute > now.hour * 60 + now.minute;
    setState(() => _pickedTime = late ? TimeOfDay.fromDateTime(now) : picked);
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
    final selectedGuardian = child?.guardians
        .where((guardian) => guardian.position == _selectedGuardianPosition)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Trả trẻ')),
      bottomNavigationBar:
          child?.row.status == PickupStatus.waiting &&
              child!.guardians.isNotEmpty
          ? AppBottomDock(
              children: [
                AppButton(
                  label: 'Trả trẻ',
                  icon: AppIcons.walk,
                  expand: true,
                  onPressed: !_saving && selectedGuardian?.photoUrl != null
                      ? () => _handOver(selectedGuardian!)
                      : null,
                ),
              ],
            )
          : null,
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
                const SizedBox(height: AppSpacing.space3),
                AppCard(
                  flush: true,
                  child: AppListRow(
                    leading: const Icon(AppIcons.clock),
                    title: 'Giờ trả: ${_handoverTime()}',
                    showChevron: true,
                    onTap: _saving ? null : _chooseTime,
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
                    selected: guardian.position == _selectedGuardianPosition,
                    onSelect: () => setState(
                      () => _selectedGuardianPosition = guardian.position,
                    ),
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
  const _Photo({required this.size, this.url});

  final double size;

  /// URL ảnh có hạn BE trả (`photoUrl`); null/lỗi tải ⇒ icon, GV phải gọi xác nhận (PCK-02).
  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Icon(
      AppIcons.person,
      size: size * 0.55,
      color: AppColors.primary,
    );
    final photoUrl = url;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      // TODO(G94-385): gắn header Authorization khi có HTTP client (ảnh chỉ tải qua auth)
      child: photoUrl == null || !photoUrl.startsWith('http')
          ? placeholder
          : Image.network(
              photoUrl,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}

class _GuardianCard extends StatelessWidget {
  const _GuardianCard({
    required this.guardian,
    required this.enabled,
    required this.selected,
    required this.onSelect,
    required this.onCall,
  });

  final PickupGuardian guardian;
  final bool enabled;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasPhoto = guardian.photoUrl != null;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${guardian.relationship.label} ${guardian.fullName}${selected ? ', đã chọn' : ''}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onSelect : null,
        child: AppCard(
          borderColor: selected ? AppColors.primary : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _Photo(size: 96, url: guardian.photoUrl),
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
                  if (selected)
                    const Icon(
                      AppIcons.checkCircle,
                      color: AppColors.primary,
                      size: AppSizes.iconInline,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              AppButton(
                label: 'Gọi',
                icon: AppIcons.call,
                variant: AppButtonVariant.secondary,
                small: true,
                expand: true,
                onPressed: enabled ? onCall : null,
              ),
            ],
          ),
        ),
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

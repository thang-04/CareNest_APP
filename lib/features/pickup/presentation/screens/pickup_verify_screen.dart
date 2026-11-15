import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/pickup/data/fake_pickup_source.dart';
import 'package:carenest_app/features/pickup/domain/pickup.dart';

/// Xác minh người đón — Figma GV06 (bản sửa). Ảnh người đón chỉ tải qua URL có auth khi có API;
/// bản giả dùng icon (không dùng ảnh người thật). Không khớp ⇒ ghi cuộc gọi rồi trả / không trả (PCK-02).
class PickupVerifyScreen extends StatefulWidget {
  const PickupVerifyScreen({
    super.key,
    required this.childId,
    required this.onDone,
    this.classId = FakeClassRosterSource.classId,
    this.source,
  });

  final String childId;
  final VoidCallback onDone;
  final String classId;
  final PickupSource? source;

  @override
  State<PickupVerifyScreen> createState() => _PickupVerifyScreenState();
}

class _PickupVerifyScreenState extends State<PickupVerifyScreen> {
  late final PickupSource _source = widget.source ?? FakePickupSource.shared;
  PickupKid? _kid;
  bool _loaded = false;
  String? _selectedId;
  bool _saving = false;
  bool _mismatch = false;
  final _callNote = TextEditingController();
  final _pickupPerson = TextEditingController();
  String? _callNoteError;
  String? _pickupPersonError;

  @override
  void initState() {
    super.initState();
    _source.loadClass(widget.classId).then((kids) {
      if (!mounted) return;
      final kid = kids
          .where((item) => item.childId == widget.childId)
          .firstOrNull;
      setState(() {
        _kid = kid;
        _loaded = true;
        _selectedId = kid?.guardians.firstOrNull?.id;
      });
    });
  }

  @override
  void dispose() {
    _callNote.dispose();
    _pickupPerson.dispose();
    super.dispose();
  }

  Future<void> _recordCall({required bool handOver}) async {
    final note = _callNote.text.trim();
    final person = _pickupPerson.text.trim();
    setState(() {
      _callNoteError = note.isEmpty ? 'Ghi nội dung cuộc gọi.' : null;
      _pickupPersonError = handOver && person.isEmpty
          ? 'Ghi người đến đón.'
          : null;
    });
    if (_callNoteError != null || _pickupPersonError != null) return;
    setState(() => _saving = true);
    await _source.recordCall(
      PickupCall(
        childId: _kid!.childId,
        callNote: note,
        handedOver: handOver,
        pickupPerson: handOver ? person : null,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onDone();
  }

  Future<void> _handOver() async {
    final kid = _kid!;
    final guardian = kid.guardians.firstWhere((g) => g.id == _selectedId);
    setState(() => _saving = true);
    await _source.handOver(kid.childId, guardian);
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final kid = _kid;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Xác minh người đón')),
      body: !_loaded
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 3),
            )
          : kid == null || kid.pickedUp
          ? const Center(
              child: AppEmptyState(
                icon: AppIcons.checkCircle,
                title: 'Không có bé chờ giao',
                message: 'Bé đã được đón hoặc không có mặt hôm nay.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                AppCard(
                  dense: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${kid.fullName} · ${FakeClassRosterSource.className}',
                        style: textTheme.titleSmall,
                      ),
                      Text(
                        'Đang chờ giao bé',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Semantics(
                  header: true,
                  child: Text(
                    'Người đón đã đăng ký',
                    style: textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, guardian) in kid.guardians.indexed) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.space3),
                        Expanded(
                          child: _GuardianCard(
                            guardian: guardian,
                            selected: guardian.id == _selectedId,
                            tone: i.isEven ? null : AppStatusTone.green,
                            onTap: () =>
                                setState(() => _selectedId = guardian.id),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                const _QuestionBox(
                  text: 'Người đón có đúng là người trong ảnh đã đăng ký?',
                ),
                const SizedBox(height: AppSpacing.space3),
                _ToneButtons(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppButton(
                        label: 'Đúng – giao bé',
                        loadingLabel: 'Đang ghi nhận',
                        isLoading: _saving,
                        expand: true,
                        onPressed: _selectedId == null || _mismatch
                            ? null
                            : _handOver,
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      AppButton(
                        label: 'Không khớp – gọi phụ huynh',
                        icon: AppIcons.call,
                        variant: AppButtonVariant.secondary,
                        expand: true,
                        onPressed: _saving || _mismatch
                            ? null
                            : () => setState(() => _mismatch = true),
                      ),
                    ],
                  ),
                ),
                if (_mismatch) ...[
                  const SizedBox(height: AppSpacing.space4),
                  // Gọi điện cần plugin quay số ⇒ chưa thêm thư viện, GV gọi bằng máy
                  AppBanner(
                    kind: AppBannerKind.warning,
                    title: 'Gọi phụ huynh',
                    message: [
                      for (final guardian in kid.guardians)
                        '${guardian.relation}: ${guardian.phone}',
                    ].join(' · '),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  AppTextField(
                    label: 'Nội dung cuộc gọi',
                    labelSuffix: '*',
                    hint: 'Ví dụ: mẹ nhờ chú Tâm đón, đã xác nhận',
                    controller: _callNote,
                    multiline: true,
                    enabled: !_saving,
                    errorText: _callNoteError,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  AppTextField(
                    label: 'Người đến đón',
                    hint: 'Ví dụ: Chú Tâm (em của mẹ)',
                    controller: _pickupPerson,
                    enabled: !_saving,
                    errorText: _pickupPersonError,
                    helperText: 'Bắt buộc khi trả bé.',
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Không trả bé',
                          variant: AppButtonVariant.secondary,
                          onPressed: _saving
                              ? null
                              : () => _recordCall(handOver: false),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: AppButton(
                          label: 'Trả bé',
                          loadingLabel: 'Đang ghi',
                          isLoading: _saving,
                          onPressed: () => _recordCall(handOver: true),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.space3),
                Text(
                  'Không khớp: gọi phụ huynh, ghi nội dung cuộc gọi rồi chọn Trả bé / Không trả bé. Hệ thống ghi người đón, giờ đón và báo phụ huynh.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
    );
  }
}

class _GuardianCard extends StatelessWidget {
  const _GuardianCard({
    required this.guardian,
    required this.selected,
    required this.tone,
    required this.onTap,
  });

  final RegisteredGuardian guardian;
  final bool selected;
  final AppStatusTone? tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = tone == null
        ? null
        : AppStatusColors.of(context).tone(tone!);
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: '${guardian.relation} ${guardian.fullName}, ${guardian.phone}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space3),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1.2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors?.background ?? AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      AppIcons.person,
                      size: 48,
                      color: colors?.foreground ?? AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  '${guardian.relation} – ${guardian.fullName}',
                  textAlign: TextAlign.center,
                  style: textTheme.titleSmall,
                ),
                Text(
                  guardian.phone,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                if (selected)
                  Text(
                    'Đang so sánh',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Câu hỏi xác minh: nền `primarySoft`, chữ xanh căn giữa (Figma GV06).
class _QuestionBox extends StatelessWidget {
  const _QuestionBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Màu riêng của hai nút xác minh (Figma GV06): giao bé nền xanh lá, không khớp viền cam.
class _ToneButtons extends StatelessWidget {
  const _ToneButtons({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.successText,
            foregroundColor: AppColors.onBrand,
            disabledBackgroundColor: AppColors.borderStrong,
            disabledForegroundColor: AppColors.surface,
          ).merge(theme.filledButtonTheme.style),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.warningSoft,
            foregroundColor: AppColors.warningText,
            side: const BorderSide(color: AppColors.warning),
          ).merge(theme.outlinedButtonTheme.style),
        ),
      ),
      child: child,
    );
  }
}

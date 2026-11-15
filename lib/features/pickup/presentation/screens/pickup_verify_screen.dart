import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_coming_soon.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/pickup/data/fake_pickup_source.dart';
import 'package:carenest_app/features/pickup/domain/pickup.dart';

/// Xác minh người đón — mockup T06. Ảnh người đón chỉ tải qua URL có auth khi có API;
/// bản giả dùng icon (không dùng ảnh người thật).
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
                        'Chờ giao bé',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Text('Người đón đã đăng ký', style: textTheme.titleSmall),
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
                const AppBanner(
                  icon: AppIcons.person,
                  message: 'Người đón có đúng là người trong ảnh đã đăng ký?',
                ),
                const SizedBox(height: AppSpacing.space4),
                AppButton(
                  label: 'Đúng – giao bé',
                  loadingLabel: 'Đang ghi nhận',
                  isLoading: _saving,
                  expand: true,
                  onPressed: _selectedId == null ? null : _handOver,
                ),
                const SizedBox(height: AppSpacing.space2),
                // Gọi điện cần plugin quay số ⇒ chưa thêm thư viện
                AppButton(
                  label: 'Không khớp – gọi phụ huynh',
                  icon: AppIcons.call,
                  variant: AppButtonVariant.secondary,
                  expand: true,
                  onPressed: _saving
                      ? null
                      : () => openComingSoon(context, 'Gọi phụ huynh'),
                ),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  'Chỉ giao bé khi phụ huynh đồng ý qua điện thoại. Hệ thống ghi người đón, giờ đón và gửi thông báo cho phụ huynh.',
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
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
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

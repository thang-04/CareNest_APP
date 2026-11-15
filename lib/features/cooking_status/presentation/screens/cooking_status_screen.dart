import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/features/cooking_status/data/fake_cooking_status_source.dart';
import 'package:carenest_app/features/cooking_status/domain/cooking_status.dart';
import 'package:carenest_app/features/school_menu/domain/meal_slot.dart';

/// Trạng thái nấu — mockup K07 (bếp cập nhật) và V05 (Phó HT chỉ xem). NUT-14 PROPOSED.
class CookingStatusScreen extends StatefulWidget {
  const CookingStatusScreen({
    super.key,
    this.readOnly = false,
    this.title = 'Trạng thái nấu',
    this.header,
    this.notice,
    this.footerNote =
        'Phó hiệu trưởng xem trạng thái này. Giáo viên không cần thao tác nhận suất.',
    this.source,
  });

  /// Phó HT chỉ xem ⇒ không có nút chuyển bước.
  final bool readOnly;
  final String title;

  /// Khối đầu màn theo vai trò (vd. Phó HT: bếp nào, phiếu xuất kho).
  final Widget? header;

  /// Khối sau các bước (vd. Phó HT: banner báo thiếu từ bếp).
  final Widget? notice;
  final String footerNote;
  final CookingStatusSource? source;

  @override
  State<CookingStatusScreen> createState() => _CookingStatusScreenState();
}

class _CookingStatusScreenState extends State<CookingStatusScreen> {
  late final CookingStatusSource _source =
      widget.source ?? FakeCookingStatusSource.shared;
  Map<MealSlot, MealCooking>? _meals;
  MealSlot _slot = MealSlot.lunch;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _source.loadToday().then((meals) {
      if (mounted) setState(() => _meals = meals);
    });
  }

  Future<void> _advance() async {
    setState(() => _saving = true);
    final updated = await _source.advance(_slot);
    if (!mounted) return;
    setState(() {
      _meals = {...?_meals, _slot: updated};
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final meal = _meals?[_slot];
    final textTheme = Theme.of(context).textTheme;
    final next = meal == null || meal.stage == CookingStage.delivered
        ? null
        : CookingStage.values[meal.stage.index + 1];
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: meal == null
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 4),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                if (widget.header != null) ...[
                  widget.header!,
                  const SizedBox(height: AppSpacing.space3),
                ],
                AppSegmented<MealSlot>(
                  segments: [
                    for (final slot in MealSlot.values) (slot, slot.label),
                  ],
                  selected: _slot,
                  onChanged: (value) => setState(() => _slot = value),
                ),
                const SizedBox(height: AppSpacing.space3),
                for (final stage in CookingStage.values) ...[
                  _StageCard(
                    stage: stage,
                    current: meal.stage,
                    note:
                        meal.notes[stage] ??
                        FakeCookingStatusSource.hintOf(stage),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                ],
                if (widget.notice != null) ...[
                  const SizedBox(height: AppSpacing.space2),
                  widget.notice!,
                ],
                const SizedBox(height: AppSpacing.space2),
                Text(
                  widget.footerNote,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
      bottomNavigationBar: widget.readOnly || meal == null
          ? null
          : AppBottomDock(
              children: [
                AppButton(
                  label: next == null
                      ? 'Bữa này đã giao xong'
                      : 'Chuyển sang “${next.label}”',
                  loadingLabel: 'Đang cập nhật',
                  isLoading: _saving,
                  expand: true,
                  onPressed: next == null ? null : _advance,
                ),
              ],
            ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stage,
    required this.current,
    required this.note,
  });

  final CookingStage stage;
  final CookingStage current;
  final String note;

  @override
  Widget build(BuildContext context) {
    final done = stage.index < current.index;
    final active = stage == current;
    final success = AppStatusColors.of(context).feedbackOf(AppFeedback.success);
    final textTheme = Theme.of(context).textTheme;
    final state = done
        ? 'đã xong'
        : active
        ? 'đang ở bước này'
        : 'chưa tới';
    return Semantics(
      container: true,
      label: '${stage.label}, $state. $note',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: active
                ? AppColors.primary
                : AppColors.surface.withValues(alpha: 0.85),
            width: active ? 1.5 : 1,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? success.main
                    : active
                    ? AppColors.primary
                    : AppColors.surface,
                border: done || active
                    ? null
                    : Border.all(color: AppColors.borderStrong, width: 2),
              ),
              child: done
                  ? const Icon(
                      AppIcons.check,
                      size: 18,
                      color: AppColors.surface,
                    )
                  : active
                  ? const Center(
                      child: CircleAvatar(
                        radius: 5,
                        backgroundColor: AppColors.surface,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stage.label, style: textTheme.titleSmall),
                  Text(
                    note,
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
    );
  }
}

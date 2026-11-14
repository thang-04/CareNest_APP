import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_photo_placeholder.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/kitchen_meal_samples/data/fake_meal_sample_source.dart';
import 'package:carenest_app/features/kitchen_meal_samples/domain/meal_samples.dart';

/// Ảnh mẫu bữa của bếp (NUT-16). Chưa chọn thư viện camera ⇒ khung ngắm tĩnh,
/// nút chụp chỉ thêm ảnh giữ chỗ; chỉ chụp suất ăn, không chụp trẻ.
class MealSampleScreen extends StatefulWidget {
  const MealSampleScreen({super.key, required this.onSaved, this.source});

  final VoidCallback onSaved;
  final MealSampleSource? source;

  @override
  State<MealSampleScreen> createState() => _MealSampleScreenState();
}

class _MealSampleScreenState extends State<MealSampleScreen> {
  late final MealSampleSource _source =
      widget.source ?? FakeMealSampleSource.shared;
  late final Future<MealSampleDay> _day = _source.loadDay();
  MealSlot _slot = MealSlot.lunch;
  bool _saving = false;

  SampleKind? _next(MealSampleDay day) {
    final captured = _source.captured(_slot);
    return day.kinds.where((kind) => !captured.contains(kind)).firstOrNull;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _source.save(_slot);
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<MealSampleDay>(
      future: _day,
      builder: (context, snapshot) {
        final day = snapshot.data;
        final captured = _source.captured(_slot);
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ảnh mẫu bữa'),
                if (day != null)
                  Text(
                    '${day.kitchenLabel} · ${DateLabels.weekdayDayMonth(day.date)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          body: day == null
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.pagePadding),
                  child: AppSkeletonList(rows: 3),
                )
              : _buildBody(day, captured),
          bottomNavigationBar: day == null
              ? null
              : AppBottomDock(
                  children: [
                    AppButton(
                      label: 'Lưu ảnh mẫu',
                      loadingLabel: 'Đang lưu',
                      isLoading: _saving,
                      expand: true,
                      onPressed: captured.isEmpty ? null : _save,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildBody(MealSampleDay day, Set<SampleKind> captured) {
    final textTheme = Theme.of(context).textTheme;
    final window = day.windows[_slot];
    final next = _next(day);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        AppSegmented<MealSlot>(
          segments: [for (final slot in MealSlot.values) (slot, slot.label)],
          selected: _slot,
          onChanged: (value) => setState(() => _slot = value),
        ),
        if (window != null) ...[
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              const Icon(
                AppIcons.clock,
                size: AppSizes.iconInline,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  'Chụp trong ${DateLabels.time24(window.opensAt)}–${DateLabels.time24(window.closesAt)}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.space3),
        AppCard(
          dense: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                AppIcons.meal,
                size: AppSizes.iconTile,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thực đơn ${_slot.label.toLowerCase()} · đã công bố',
                      style: textTheme.titleSmall,
                    ),
                    Text(
                      day.menus[_slot] ?? '',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        _Viewfinder(
          target: next,
          onCapture: next == null || _saving
              ? null
              : () => setState(() => _source.capture(_slot, next)),
        ),
        const SizedBox(height: AppSpacing.space3),
        Text(
          'Đã chụp (${captured.length}/${day.kinds.length})',
          style: textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.space2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, kind) in day.kinds.indexed) ...[
              if (i > 0) const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: captured.contains(kind)
                    ? AppPhotoPlaceholder(caption: kind.label)
                    : _EmptySlot(label: kind.label),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppStatusBadge(
              label: '${day.alternativeCount} suất thay thế',
              tone: AppStatusTone.teal,
            ),
            Text(
              'Theo món thay thế, không tên trẻ',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}

/// Khung ngắm tĩnh + nút chụp cho ảnh mẫu kế tiếp.
class _Viewfinder extends StatelessWidget {
  const _Viewfinder({required this.target, required this.onCapture});

  final SampleKind? target;
  final VoidCallback? onCapture;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final target = this.target;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.space4),
          const ExcludeSemantics(
            child: Icon(AppIcons.meal, size: 48, color: AppColors.textDisabled),
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            'Đưa suất ăn mẫu vào khung',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.surface),
          ),
          const SizedBox(height: AppSpacing.space3),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: AppColors.textSecondary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              target?.label ?? 'Đã chụp đủ ảnh mẫu',
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(color: AppColors.surface),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          _ShutterButton(
            label: target == null ? 'Chụp ảnh' : 'Chụp ${target.label}',
            onPressed: onCapture,
          ),
        ],
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$label, chưa chụp',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.borderStrong),
              ),
              child: const Icon(AppIcons.camera, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        radius: 36,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surface, width: 4),
          ),
          padding: const EdgeInsets.all(AppSpacing.space1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? AppColors.primary : AppColors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_coming_soon.dart';
import 'package:carenest_app/core/widgets/app_photo_placeholder.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/meal_photos/data/fake_meal_photo_source.dart';
import 'package:carenest_app/features/meal_photos/domain/meal_photos.dart';

/// Chụp ảnh bữa ăn — mockup T15. Chưa chọn thư viện camera (quyết định 6) ⇒ khung ngắm tĩnh,
/// nút chụp chỉ thêm ảnh giữ chỗ để xem luồng.
class MealPhotoCaptureScreen extends StatefulWidget {
  const MealPhotoCaptureScreen({
    super.key,
    required this.onNext,
    this.classId = FakeClassRosterSource.classId,
    this.source,
  });

  final ValueChanged<MealSlot> onNext;
  final String classId;
  final MealPhotoSource? source;

  @override
  State<MealPhotoCaptureScreen> createState() => _MealPhotoCaptureScreenState();
}

class _MealPhotoCaptureScreenState extends State<MealPhotoCaptureScreen> {
  late final MealPhotoSource _source =
      widget.source ?? FakeMealPhotoSource.shared;
  late final Future<MealPhotoDay> _day = _source.loadDay(widget.classId);
  MealSlot _slot = MealSlot.lunch;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<MealPhotoDay>(
      future: _day,
      builder: (context, snapshot) {
        final day = snapshot.data;
        final count = _source.capturedCount(_slot);
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ảnh bữa ăn'),
                if (day != null)
                  Text(
                    '${day.className} · ${DateLabels.weekdayDayMonth(day.date)}',
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
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  children: [
                    AppSegmented<MealSlot>(
                      segments: [
                        for (final slot in MealSlot.values) (slot, slot.label),
                      ],
                      selected: _slot,
                      onChanged: (value) => setState(() => _slot = value),
                    ),
                    if (day.sentNotes[_slot] case final sent?) ...[
                      const SizedBox(height: AppSpacing.space2),
                      Text(
                        '${_slot.label}: $sent',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppStatusColors.of(
                            context,
                          ).feedbackOf(AppFeedback.success).foreground,
                        ),
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
                    _Viewfinder(regularCount: day.regularCount),
                    const SizedBox(height: AppSpacing.space3),
                    Text(
                      'Đã chụp ($count/${FakeMealPhotoSource.maxPhotos})',
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.space2),
                          Expanded(
                            child: i < count
                                ? const AppPhotoPlaceholder(aspectRatio: 1)
                                : const _EmptySlot(),
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
                          day.alternativeNote,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          bottomNavigationBar: day == null
              ? null
              : DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pagePadding,
                        vertical: AppSpacing.space3,
                      ),
                      child: Row(
                        children: [
                          IconButton.outlined(
                            tooltip: 'Chọn ảnh có sẵn',
                            onPressed: () =>
                                openComingSoon(context, 'Chọn ảnh có sẵn'),
                            icon: const Icon(AppIcons.gallery),
                          ),
                          const Spacer(),
                          _ShutterButton(
                            enabled: count < FakeMealPhotoSource.maxPhotos,
                            onPressed: () =>
                                setState(() => _source.capture(_slot)),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: count == 0
                                ? null
                                : () => widget.onNext(_slot),
                            child: const Text('Tiếp ›'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder({required this.regularCount});

  final int regularCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label:
          'Khung ngắm: đưa khay suất ăn vào khung. Suất thường $regularCount bé.',
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1.1,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                AppIcons.meal,
                size: 48,
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                'Đưa khay suất ăn vào khung',
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
                  'Suất thường · $regularCount bé',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.surface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: const Icon(AppIcons.plus, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: 'Chụp ảnh',
      excludeSemantics: true,
      child: InkResponse(
        onTap: enabled ? onPressed : null,
        radius: 36,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 4),
          ),
          padding: const EdgeInsets.all(4),
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

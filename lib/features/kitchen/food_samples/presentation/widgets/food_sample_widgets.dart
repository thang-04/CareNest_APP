import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/kitchen/food_samples/domain/food_samples.dart';
import 'package:carenest_app/features/kitchen/food_samples/presentation/food_samples_status.dart';

/// Ô nhập Mẫu 5 của một món; giữ chữ đã nhập khi lưu lỗi.
class DishNoteControllers {
  DishNoteControllers(SampleDish dish)
    : weight = TextEditingController(text: dish.weight),
      container = TextEditingController(text: dish.container),
      temperature = TextEditingController(text: dish.temperature);

  final TextEditingController weight;
  final TextEditingController container;
  final TextEditingController temperature;

  DishNoteInput input(int dishId) => DishNoteInput(
    dishId: dishId,
    weight: weight.text.trim(),
    container: container.text.trim(),
    temperature: temperature.text.trim(),
  );

  void dispose() {
    weight.dispose();
    container.dispose();
    temperature.dispose();
  }
}

/// Khung thẻ một bữa: tên bữa, nhãn trạng thái, dòng phụ. [muted] cho bữa chưa tới.
class SampleCardFrame extends StatelessWidget {
  const SampleCardFrame({
    super.key,
    required this.title,
    required this.badge,
    required this.subtitle,
    required this.children,
    this.muted = false,
  });

  final String title;
  final (String, AppStatusTone) badge;
  final String subtitle;
  final List<Widget> children;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (label, tone) = badge;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nhãn dài ("Chờ duyệt lưu mẫu") xuống dòng khi máy hẹp hay chữ lớn
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: textTheme.titleMedium),
            ),
            AppStatusBadge(label: label, tone: tone),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        ...children,
      ],
    );
    if (!muted) return AppCard(dense: true, child: content);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingDense),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.border),
      ),
      child: content,
    );
  }
}

/// Món đã lưu mẫu: tên và ghi chú Mẫu 5.
class SampleDishLine extends StatelessWidget {
  const SampleDishLine({super.key, required this.dish});

  final SampleDish dish;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final note = FoodSamplesStatus.dishNote(dish);
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(FoodSamplesStatus.dishName(dish), style: textTheme.titleSmall),
          Text(
            note ?? 'Chưa ghi khối lượng, dụng cụ chứa, nhiệt độ',
            style: textTheme.bodyMedium?.copyWith(
              color: note == null
                  ? AppColors.toneOrangeText
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ba ô Mẫu 5 của một món. Độ dài tối đa theo BE `DishDetailInput`.
class DishNoteFields extends StatelessWidget {
  const DishNoteFields({
    super.key,
    required this.dish,
    required this.controllers,
  });

  final SampleDish dish;
  final DishNoteControllers controllers;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardGap),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(FoodSamplesStatus.dishName(dish), style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.space3),
          AppTextField(
            label: 'Khối lượng / thể tích',
            hint: 'vd. 150 g hoặc 150 ml',
            controller: controllers.weight,
            maxLength: 50,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.space3),
          AppTextField(
            label: 'Dụng cụ chứa',
            hint: 'vd. Hộp inox có nắp',
            controller: controllers.container,
            maxLength: 100,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.space3),
          AppTextField(
            label: 'Nhiệt độ bảo quản (°C)',
            hint: 'vd. 0–5',
            controller: controllers.temperature,
            maxLength: 50,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}

/// Mẫu ngày trước chưa xong hủy: ghi hủy khi đến hạn, chờ PHT duyệt hủy.
class DisposalCard extends StatelessWidget {
  const DisposalCard({
    super.key,
    required this.sample,
    required this.busy,
    required this.onDispose,
    this.error,
  });

  final FoodSample sample;
  final bool busy;
  final VoidCallback onDispose;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canDispose =
        sample.disposalStatus == SampleDisposalStatus.none &&
        sample.disposableNow;
    final badge = switch (sample.disposalStatus) {
      SampleDisposalStatus.none when sample.disposableNow =>
        FoodSamplesStatus.disposalDue,
      SampleDisposalStatus.none => FoodSamplesStatus.notYetDisposable,
      final status => FoodSamplesStatus.disposal(status),
    };
    return SampleCardFrame(
      title: FoodSamplesStatus.pastTitle(sample),
      badge: badge,
      subtitle: FoodSamplesStatus.disposalWindow(sample),
      children: [
        const SizedBox(height: AppSpacing.space2),
        Text(
          sample.dishes.map(FoodSamplesStatus.dishName).join(', '),
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        if (error case final error?) ...[
          const SizedBox(height: AppSpacing.space2),
          Semantics(
            liveRegion: true,
            child: Text(
              error,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.dangerText,
              ),
            ),
          ),
        ],
        if (canDispose) ...[
          const SizedBox(height: AppSpacing.space3),
          AppButton(
            label: 'Ghi hủy mẫu',
            icon: AppIcons.checkCircle,
            variant: AppButtonVariant.secondary,
            expand: true,
            isLoading: busy,
            loadingLabel: 'Đang ghi…',
            onPressed: onDispose,
          ),
        ],
      ],
    );
  }
}

/// "Thứ Hai, 12/10 · Cơ sở chính"
String sampleDayLabel(FoodSampleDay day) => [
  'Hôm nay',
  DateLabels.weekdayDayMonth(day.date),
  if (day.campusLabel.isNotEmpty) day.campusLabel,
].join(' · ');

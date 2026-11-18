import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';
import 'package:carenest_app/features/kitchen/meal_photos/presentation/meal_photos_status.dart';

/// Ô chọn nhóm tuổi: tên, độ tuổi, số bữa đã có ảnh / số bữa nhóm ăn, một vạch mỗi bữa.
class AgeGroupTile extends StatelessWidget {
  const AgeGroupTile({
    super.key,
    required this.group,
    required this.selected,
    required this.onTap,
  });

  final AgeGroupMeals group;
  final bool selected;
  final VoidCallback onTap;

  /// Vạch mỗi bữa cao 6px như canvas
  static const _segmentHeight = AppSpacing.space1 * 1.5;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = group.meals.length;
    final label =
        '${group.name}, ${group.ageRange.replaceAll('–', ' đến ')}, '
        '${group.doneMeals} trên $total bữa có ảnh';
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: selected ? AppShadows.tinted(AppColors.brand) : null,
        ),
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            side: selected
                ? const BorderSide(color: AppColors.brand, width: 2)
                : const BorderSide(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardGap),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(group.name, style: textTheme.titleSmall),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Text(
                        '${group.doneMeals}/$total',
                        style: textTheme.labelLarge?.copyWith(
                          color: MealPhotosStatus.groupCount(group),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    group.ageRange,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: AppSpacing.space2),
                  Row(
                    children: [
                      for (final (i, meal) in group.meals.indexed) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.space1),
                        Expanded(
                          child: Container(
                            height: _segmentHeight,
                            decoration: BoxDecoration(
                              color: MealPhotosStatus.color(meal.status),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Một mục trên dòng thời gian các bữa: chấm màu theo trạng thái, đường nối xuống bữa sau.
class MealTimelineItem extends StatelessWidget {
  const MealTimelineItem({
    super.key,
    required this.status,
    required this.isLast,
    required this.child,
  });

  final MealPhotoStatus status;
  final bool isLast;
  final Widget child;

  static const _railWidth = 2.0;

  // Chấm ngang tiêu đề thẻ bữa
  static const _dotTop = AppSpacing.space5;

  @override
  Widget build(BuildContext context) {
    final color = MealPhotosStatus.color(status);
    final filled = status == MealPhotoStatus.done;
    return Stack(
      children: [
        if (!isLast)
          const Positioned(
            top: _dotTop + AppSizes.iconBadge + AppSpacing.space1,
            bottom: 0,
            left: (AppSpacing.space4 - _railWidth) / 2,
            width: _railWidth,
            child: ColoredBox(color: AppColors.border),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: AppSpacing.space4,
                  child: Column(
                    children: [
                      const SizedBox(height: _dotTop),
                      Container(
                        width: AppSizes.iconBadge,
                        height: AppSizes.iconBadge,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? color : AppColors.surface,
                          border: filled
                              ? null
                              : Border.all(color: color, width: 3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(child: child),
              ],
            ),
            if (!isLast) const SizedBox(height: AppSpacing.space4),
          ],
        ),
      ],
    );
  }
}

/// Thẻ một bữa của nhóm đang chọn: trạng thái, giờ đăng, ảnh đã đăng, vùng chụp.
/// Chỉ chụp được trong giờ đăng (NUT-16); hết giờ mà chưa có ảnh chỉ báo đỏ.
class MealPhotoCard extends StatelessWidget {
  const MealPhotoCard({
    super.key,
    required this.groupName,
    required this.meal,
    required this.posting,
    required this.onCapture,
    required this.onRetry,
    this.error,
    this.unsent,
  });

  final String groupName;
  final SampleMeal meal;

  /// Đang mở camera hoặc đang đăng: khoá nút để không đăng trùng
  final bool posting;
  final VoidCallback onCapture;
  final VoidCallback onRetry;
  final String? error;

  /// Ảnh vừa chụp mà đăng lỗi, giữ để đăng lại
  final Uint8List? unsent;

  String get _note => switch (meal.window) {
    PhotoWindow.notSet =>
      'Chưa đăng được ảnh ${MealPhotosStatus.inSentence(meal)}. Báo Hiệu trưởng đặt giờ đăng ảnh trong Cấu hình thời gian.',
    PhotoWindow.upcoming => 'Đăng được ${meal.windowLabel}',
    PhotoWindow.open => [
      'Đăng được ${meal.windowLabel}',
      if (meal.minutesLeft case final minutes?) 'còn $minutes phút',
    ].join(' · '),
    PhotoWindow.closed =>
      meal.photos.isEmpty
          ? 'Hết giờ đăng (${meal.windowLabel}). Ảnh bữa này không đăng thêm được.'
          : 'Đăng được ${meal.windowLabel} · đã qua',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = meal.status;
    final muted =
        status == MealPhotoStatus.upcoming ||
        status == MealPhotoStatus.noWindow;
    final canCapture = meal.window == PhotoWindow.open && unsent == null;
    final (badge, tone, icon) = MealPhotosStatus.badge(meal);
    final noteStyle = textTheme.bodyMedium?.copyWith(
      color: status == MealPhotoStatus.missed || muted
          ? AppColors.textSecondary
          : AppColors.textMuted,
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nhãn dài ("Quá giờ, chưa có ảnh") xuống dòng khi máy hẹp hay chữ lớn
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            Text(meal.name, style: textTheme.titleMedium),
            AppStatusBadge(label: badge, tone: tone, icon: icon),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        _IconLine(
          icon: meal.window == PhotoWindow.open ? AppIcons.clock : null,
          text: _note,
          style: noteStyle,
        ),
        if (status == MealPhotoStatus.upcoming && meal.opensAt != null) ...[
          const SizedBox(height: AppSpacing.space2),
          _IconLine(
            icon: AppIcons.lock,
            text: 'Nút chụp mở lúc ${meal.opensAt}',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (meal.photos.isNotEmpty || unsent != null) ...[
          const SizedBox(height: AppSpacing.space3),
          _PhotoGrid(
            meal: meal,
            unsent: unsent,
            addTile: canCapture && meal.photos.isNotEmpty
                ? _AddPhotoTile(meal: meal, posting: posting, onTap: onCapture)
                : null,
          ),
        ],
        if (canCapture && meal.photos.isEmpty) ...[
          const SizedBox(height: AppSpacing.space3),
          _CaptureZone(
            title: 'Chụp ảnh mẫu ${MealPhotosStatus.inSentence(meal)}',
            subtitle: 'Ảnh đăng cho nhóm $groupName',
            posting: posting,
            onTap: onCapture,
          ),
        ],
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
        if (unsent != null) ...[
          const SizedBox(height: AppSpacing.space3),
          AppButton(
            label: 'Đăng lại ảnh',
            icon: AppIcons.refresh,
            expand: true,
            isLoading: posting,
            loadingLabel: 'Đang đăng ảnh…',
            onPressed: onRetry,
          ),
        ],
      ],
    );
    if (!muted) return AppCard(dense: true, child: content);
    // Bữa chưa tới giờ hoặc chưa có giờ đăng: thẻ chìm, không có gì để bấm
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

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text, this.style});

  final IconData? icon;
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    if (icon == null) return Text(text, style: style);
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconBadge, color: style?.color),
        const SizedBox(width: AppSpacing.space2),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}

/// Vùng lớn viền nét đứt: bấm cả vùng để mở camera.
class _CaptureZone extends StatelessWidget {
  const _CaptureZone({
    required this.title,
    required this.subtitle,
    required this.posting,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool posting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final heading = posting ? 'Đang đăng ảnh…' : title;
    return Semantics(
      button: true,
      enabled: !posting,
      label: '$heading. $subtitle',
      excludeSemantics: true,
      child: _DashedFrame(
        child: InkWell(
          onTap: posting ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sectionGap),
            child: Column(
              children: [
                Container(
                  width: AppSizes.buttonHeight,
                  height: AppSizes.buttonHeight,
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.tinted(AppColors.brand),
                  ),
                  alignment: Alignment.center,
                  child: posting
                      ? const SizedBox.square(
                          dimension: AppSizes.iconNavigation,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.onBrand,
                          ),
                        )
                      : const Icon(
                          AppIcons.camera,
                          size: AppSizes.iconNavigation,
                          color: AppColors.onBrand,
                        ),
                ),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  heading,
                  textAlign: TextAlign.center,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.onBrand,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
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

/// Ô "Chụp thêm" cuối lưới ảnh khi bữa còn trong giờ đăng.
class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({
    required this.meal,
    required this.posting,
    required this.onTap,
  });

  final SampleMeal meal;
  final bool posting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = posting ? 'Đang đăng ảnh…' : 'Chụp thêm';
    return Semantics(
      button: true,
      enabled: !posting,
      label: posting
          ? label
          : 'Chụp thêm ảnh mẫu ${MealPhotosStatus.inSentence(meal)}',
      excludeSemantics: true,
      child: _DashedFrame(
        radius: AppRadius.lg,
        child: InkWell(
          onTap: posting ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardGap),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: AppSizes.iconTileSize,
                  height: AppSizes.iconTileSize,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: posting
                      ? const SizedBox.square(
                          dimension: AppSizes.iconInline,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(
                          AppIcons.camera,
                          size: AppSizes.iconInline,
                          color: AppColors.primary,
                        ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.onBrand),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lưới ảnh 2 cột 4:3 kèm giờ đăng; ảnh vừa chụp mà đăng lỗi có viền đỏ "Chưa đăng".
class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.meal, this.unsent, this.addTile});

  final SampleMeal meal;
  final Uint8List? unsent;
  final Widget? addTile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - AppSpacing.space2) / 2;
        // Giải mã ảnh ở cỡ ô, không giữ ảnh 1600 px trong bộ nhớ
        final cacheWidth = (width * MediaQuery.devicePixelRatioOf(context))
            .round();
        final mealName = MealPhotosStatus.inSentence(meal);
        final tiles = [
          for (final (i, photo) in meal.photos.indexed)
            _PhotoTile(
              bytes: photo.bytes,
              cacheWidth: cacheWidth,
              semanticLabel: 'Ảnh ${i + 1} $mealName, đăng ${photo.postedAt}',
              chip: AppStatusBadge(
                label: photo.postedAt,
                tone: AppStatusTone.gray,
              ),
            ),
          if (unsent case final bytes?)
            _PhotoTile(
              bytes: bytes,
              cacheWidth: cacheWidth,
              semanticLabel: 'Ảnh $mealName vừa chụp, chưa đăng',
              failed: true,
              chip: const AppStatusBadge(
                label: 'Chưa đăng',
                tone: AppStatusTone.red,
              ),
            ),
        ];
        return Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: width,
                child: AspectRatio(aspectRatio: 4 / 3, child: tile),
              ),
            // Ô chụp thêm cao theo chữ khi chữ lớn, không bó cứng 4:3
            if (addTile case final addTile?)
              SizedBox(
                width: width,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: width * 3 / 4),
                  child: addTile,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.bytes,
    required this.cacheWidth,
    required this.semanticLabel,
    required this.chip,
    this.failed = false,
  });

  /// Null với ảnh giả có sẵn (chưa có URL): hiện ô giữ chỗ
  final Uint8List? bytes;
  final int cacheWidth;
  final String semanticLabel;
  final Widget chip;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final bytes = this.bytes;
    return Semantics(
      image: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        foregroundDecoration: failed
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.toneRed, width: 2),
              )
            : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bytes != null)
                Image.memory(bytes, fit: BoxFit.cover, cacheWidth: cacheWidth)
              else
                const ColoredBox(
                  color: AppColors.primarySoft,
                  child: Icon(
                    AppIcons.meal,
                    size: AppSizes.iconNavigation,
                    color: AppColors.primaryBorder,
                  ),
                ),
              Positioned(
                left: AppSpacing.space2,
                bottom: AppSpacing.space2,
                child: chip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Khung bo góc viền nét đứt màu thương hiệu, nền xanh rất nhạt.
class _DashedFrame extends StatelessWidget {
  const _DashedFrame({required this.child, this.radius = AppRadius.xl});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedRRectPainter(radius: radius),
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.radius});

  final double radius;

  static const _stroke = 2.0;
  static const _dash = 7.0;
  static const _gap = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final paint = Paint()
      ..color = AppColors.primaryBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    for (final metric in path.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += _dash + _gap) {
        canvas.drawPath(metric.extractPath(start, start + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter oldDelegate) =>
      oldDelegate.radius != radius;
}

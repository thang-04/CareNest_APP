import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/kitchen_meal_samples/data/fake_meal_sample_source.dart';
import 'package:carenest_app/features/kitchen_meal_samples/domain/meal_samples.dart';

/// Ảnh mẫu bữa của bếp (NUT-16) — Figma Bếp 05. Chưa chọn thư viện camera ⇒ khung ngắm tĩnh,
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
        final next = day == null ? null : _next(day);
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Ảnh mẫu bữa'),
                if (day != null)
                  Text(
                    '${day.kitchenLabel} · ${DateLabels.weekdayDayMonth(day.date)}',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w400,
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
              : _buildBody(day, captured, next),
          bottomNavigationBar: day == null
              ? null
              : AppBottomDock(
                  children: [
                    _CaptureBar(
                      shutterLabel: next == null
                          ? 'Chụp ảnh'
                          : 'Chụp ${next.label}',
                      onCapture: next == null || _saving
                          ? null
                          : () => setState(() => _source.capture(_slot, next)),
                      saving: _saving,
                      onSave: captured.isEmpty ? null : _save,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildBody(
    MealSampleDay day,
    Set<SampleKind> captured,
    SampleKind? next,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final window = day.windows[_slot];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        AppSegmented<MealSlot>(
          segments: [for (final slot in MealSlot.values) (slot, slot.label)],
          selected: _slot,
          onChanged: (value) => setState(() => _slot = value),
        ),
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
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
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
          hint: window == null
              ? 'Đưa suất ăn mẫu vào khung'
              : 'Chụp trong ${DateLabels.time24(window.opensAt)}–${DateLabels.time24(window.closesAt)}',
          target: next,
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          'Đã chụp (${captured.length}/${day.kinds.length})',
          style: textTheme.labelMedium,
        ),
        const SizedBox(height: AppSpacing.space2),
        Row(
          children: [
            for (final kind in day.kinds) ...[
              _SampleTile(
                label: kind.label,
                captured: captured.contains(kind),
                isNext: kind == next,
              ),
              const SizedBox(width: AppSpacing.space2),
            ],
            if (day.kinds.contains(SampleKind.alternative))
              Expanded(
                child: Column(
                  children: [
                    AppStatusBadge(
                      label: SampleKind.alternative.label,
                      tone: AppStatusTone.teal,
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      'Theo món thay thế, không tên trẻ',
                      textAlign: TextAlign.center,
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Khung ngắm tĩnh: nền tối, 4 góc trắng, khung giờ chụp và loại ảnh mẫu kế tiếp.
class _Viewfinder extends StatelessWidget {
  const _Viewfinder({required this.hint, required this.target});

  final String hint;
  final SampleKind? target;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) => ConstrainedBox(
        // Gần vuông như Figma; chữ phóng lớn thì khung cao thêm, không tràn
        constraints: BoxConstraints(minHeight: constraints.maxWidth * 0.9),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: CustomPaint(
            foregroundPainter: const _CornerPainter(color: AppColors.surface),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.textMuted,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          AppIcons.meal,
                          size: 28,
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    Text(
                      hint,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.borderStrong,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space4,
                        vertical: AppSpacing.space1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        target?.label ?? 'Đã chụp đủ ảnh mẫu',
                        textAlign: TextAlign.center,
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Vẽ 4 góc chữ L của khung ngắm.
class _CornerPainter extends CustomPainter {
  const _CornerPainter({required this.color});

  final Color color;

  static const double _inset = 16;
  static const double _length = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final right = size.width - _inset;
    final bottom = size.height - _inset;
    for (final (x, y, dx, dy) in [
      (_inset, _inset, 1.0, 1.0),
      (right, _inset, -1.0, 1.0),
      (_inset, bottom, 1.0, -1.0),
      (right, bottom, -1.0, -1.0),
    ]) {
      final path = Path()
        ..moveTo(x, y + dy * _length)
        ..lineTo(x, y)
        ..lineTo(x + dx * _length, y);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => oldDelegate.color != color;
}

/// Ô ảnh mẫu đã chụp / đang chờ chụp, không ảnh trẻ.
class _SampleTile extends StatelessWidget {
  const _SampleTile({
    required this.label,
    required this.captured,
    required this.isNext,
  });

  final String label;
  final bool captured;

  /// Ô sẽ nhận ảnh khi bấm chụp ⇒ tô `primarySoft`.
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final (background, border, icon, iconColor) = captured
        ? (
            AppColors.track,
            AppColors.border,
            AppIcons.image,
            AppColors.textMuted,
          )
        : isNext
        ? (
            AppColors.primarySoft,
            AppColors.primaryBorder,
            AppIcons.camera,
            AppColors.primary,
          )
        : (
            AppColors.surface,
            AppColors.borderStrong,
            AppIcons.camera,
            AppColors.textMuted,
          );
    return Semantics(
      container: true,
      label: '$label, ${captured ? 'đã chụp' : 'chưa chụp'}',
      excludeSemantics: true,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: border),
        ),
        child: Icon(icon, size: AppSizes.iconInline, color: iconColor),
      ),
    );
  }
}

/// Hàng điều khiển đáy kiểu camera: nút chụp giữa, "Lưu ảnh mẫu" bên phải.
class _CaptureBar extends StatelessWidget {
  const _CaptureBar({
    required this.shutterLabel,
    required this.onCapture,
    required this.saving,
    required this.onSave,
  });

  final String shutterLabel;
  final VoidCallback? onCapture;
  final bool saving;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        _ShutterButton(label: shutterLabel, onPressed: onCapture),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: 'Lưu ảnh mẫu',
              loadingLabel: 'Đang lưu',
              variant: AppButtonVariant.text,
              isLoading: saving,
              onPressed: onSave,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = onPressed == null ? AppColors.borderStrong : AppColors.brand;
    return Semantics(
      container: true,
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        radius: 36,
        child: Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(AppSpacing.space1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: color, width: 3),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ),
      ),
    );
  }
}

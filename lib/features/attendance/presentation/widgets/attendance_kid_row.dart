import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/motion.dart';
import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/attendance/domain/attendance.dart';

/// Một trẻ — mockup T02: tên + ghi chú · hai nút Có mặt / Vắng; có mặt thì nhập nhiệt độ đầu ngày.
/// Bé có đơn nghỉ khóa ở "Có phép (theo đơn)", không có nút đổi (ATT-04, ATT-09).
class AttendanceKidRow extends StatelessWidget {
  const AttendanceKidRow({
    super.key,
    required this.kid,
    required this.onPresent,
    required this.onAbsent,
    required this.onTemperatureChanged,
    this.enabled = true,
  });

  final KidAttendance kid;
  final VoidCallback onPresent;
  final VoidCallback onAbsent;
  final ValueChanged<double?> onTemperatureChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final nameBlock = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kid.fullName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall,
          ),
          if (kid.note case final note?)
            Text(
              note,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
        ],
      ),
    );
    final Widget actions = kid.hasLeaveNotice
        ? Semantics(
            container: true,
            label: '${kid.fullName}: có phép theo đơn, không đổi được',
            excludeSemantics: true,
            child: const AppStatusBadge(
              label: 'Có phép (theo đơn)',
              tone: AppStatusTone.blue,
              icon: AppIcons.lock,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Toggle(
                label: 'Có mặt',
                semanticLabel: '${kid.fullName}: có mặt',
                tone: AppStatusTone.green,
                selected: kid.status == AttendanceStatus.present,
                onTap: enabled ? onPresent : null,
              ),
              const SizedBox(width: AppSpacing.space2),
              _Toggle(
                label: 'Vắng',
                semanticLabel: '${kid.fullName}: vắng',
                tone: AppStatusTone.red,
                selected: kid.status == AttendanceStatus.unexcused,
                onTap: enabled ? onAbsent : null,
              ),
            ],
          );
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final showTemperature =
        !kid.hasLeaveNotice && kid.status == AttendanceStatus.present;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.85)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chữ lớn ⇒ nút xuống dòng dưới tên thay vì ép tràn
          if (stacked) ...[
            nameBlock,
            const SizedBox(height: AppSpacing.space2),
            actions,
          ] else
            Row(
              children: [
                Expanded(child: nameBlock),
                const SizedBox(width: AppSpacing.space2),
                actions,
              ],
            ),
          if (showTemperature) ...[
            const SizedBox(height: AppSpacing.space2),
            TemperatureField(
              key: ValueKey('temperature-${kid.childId}'),
              childName: kid.fullName,
              value: kid.temperature,
              enabled: enabled,
              onChanged: onTemperatureChanged,
            ),
          ],
        ],
      ),
    );
  }
}

/// Ô nhiệt độ đầu ngày: số có 1 chữ số thập phân, hiển thị dấu phẩy ("36,6 °C").
class TemperatureField extends StatefulWidget {
  const TemperatureField({
    super.key,
    required this.childName,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String childName;
  final double? value;
  final ValueChanged<double?> onChanged;
  final bool enabled;

  /// Khoảng hỗ trợ nhập để bắt gõ nhầm; BE kiểm tra lại.
  static const min = 34.0;
  static const max = 42.0;

  static String format(double value) =>
      value.toStringAsFixed(1).replaceAll('.', ',');

  static double? parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  @override
  State<TemperatureField> createState() => _TemperatureFieldState();
}

class _TemperatureFieldState extends State<TemperatureField> {
  late final _controller = TextEditingController(
    text: widget.value == null ? '' : TemperatureField.format(widget.value!),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    final value = TemperatureField.parse(text);
    final outOfRange =
        value != null &&
        (value < TemperatureField.min || value > TemperatureField.max);
    setState(() {
      _error = text.trim().isEmpty || (value != null && !outOfRange)
          ? null
          : 'Nhập từ 34,0 đến 42,0';
    });
    widget.onChanged(outOfRange ? null : value);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.space3),
          child: Text('Nhiệt độ:', style: textTheme.bodyMedium),
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Semantics(
            label: 'Nhiệt độ đầu ngày của ${widget.childName}',
            child: TextField(
              controller: _controller,
              enabled: widget.enabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              // Chỉ số và một dấu thập phân, tối đa 1 chữ số sau dấu
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d{0,2}([.,]\d?)?'),
                ),
              ],
              onChanged: _onChanged,
              decoration: InputDecoration(
                isDense: true,
                hintText: '36,6',
                suffixText: '°C',
                errorText: _error,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.semanticLabel,
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final AppStatusTone tone;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppStatusColors.of(context).tone(tone);
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          constraints: const BoxConstraints(
            minHeight: AppSizes.minimumTapTarget - 4,
            minWidth: 64,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
          // Clay: nút chưa chọn trắng nổi gờ đáy; nút đã chọn nền tông + viền tông + quầng
          decoration: BoxDecoration(
            color: selected ? colors.background : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? colors.main : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? AppShadows.tinted(colors.main, strength: 0.35)
                : AppShadows.buttonSecondary,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? colors.foreground : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

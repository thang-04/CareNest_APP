import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/features/attendance/domain/arrival_health.dart';
import 'package:carenest_app/features/attendance/presentation/arrival_health_labels.dart';

/// Sức khỏe đầu ngày của bé có mặt, như form Web (HLT-07): thân nhiệt tùy chọn, quan sát bắt buộc;
/// có dấu hiệu thì ghi biểu hiện, việc đã làm, ghi chú. Trẻ vẫn được nhận (P-22); APP không tự chọn quan sát.
class ArrivalHealthSection extends StatefulWidget {
  const ArrivalHealthSection({
    super.key,
    required this.childId,
    required this.childName,
    required this.health,
    required this.onChanged,
    this.errors = const {},
    this.enabled = true,
  });

  final String childId;
  final String childName;
  final ArrivalHealth health;
  final ValueChanged<ArrivalHealth> onChanged;
  final Map<ArrivalHealthField, String> errors;
  final bool enabled;

  @override
  State<ArrivalHealthSection> createState() => _ArrivalHealthSectionState();
}

class _ArrivalHealthSectionState extends State<ArrivalHealthSection> {
  late final _note = TextEditingController(text: widget.health.note);
  late final _place = TextEditingController(text: widget.health.referral.place);
  late final _time = TextEditingController(text: widget.health.referral.time);
  late final _escort = TextEditingController(
    text: widget.health.referral.escort,
  );

  @override
  void dispose() {
    _note.dispose();
    _place.dispose();
    _time.dispose();
    _escort.dispose();
    super.dispose();
  }

  ArrivalHealth get _health => widget.health;

  void _toggleSymptom(HealthSymptom symptom) {
    final next = {..._health.symptoms};
    next.contains(symptom) ? next.remove(symptom) : next.add(symptom);
    widget.onChanged(_health.copyWith(symptoms: next));
  }

  void _toggleAction(HealthAction action) {
    final next = {..._health.actions};
    next.contains(action) ? next.remove(action) : next.add(action);
    widget.onChanged(_health.copyWith(actions: next));
  }

  void _setReferral({String? place, String? time, String? escort}) =>
      widget.onChanged(
        _health.copyWith(
          referral: _health.referral.copyWith(
            place: place,
            time: time,
            escort: escort,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final errorStyle = textTheme.bodySmall?.copyWith(
      color: AppColors.dangerText,
    );
    final enabled = widget.enabled;
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space2),
      child: Text(text, style: textTheme.labelLarge),
    );
    Widget error(ArrivalHealthField field) => widget.errors[field] == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space1),
            child: Text(widget.errors[field]!, style: errorStyle),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TemperatureField(
          key: ValueKey('temperature-${widget.childId}'),
          childName: widget.childName,
          value: _health.temperature,
          enabled: enabled,
          onChanged: (value) =>
              widget.onChanged(_health.copyWith(temperature: () => value)),
        ),
        label('Quan sát ban đầu *'),
        Wrap(
          spacing: AppSpacing.space2,
          children: [
            for (final value in HealthObservation.values)
              AppFilterChip(
                key: ValueKey('observation-${widget.childId}-${value.name}'),
                label: value.label,
                selected: _health.observation == value,
                onSelected: enabled
                    ? () => widget.onChanged(_health.withObservation(value))
                    : null,
              ),
          ],
        ),
        error(ArrivalHealthField.observation),
        if (_health.isNoted) ...[
          label('Biểu hiện ghi nhận'),
          Wrap(
            spacing: AppSpacing.space2,
            children: [
              for (final symptom in HealthSymptom.values)
                AppFilterChip(
                  label: symptom.label,
                  selected: _health.symptoms.contains(symptom),
                  onSelected: enabled ? () => _toggleSymptom(symptom) : null,
                ),
            ],
          ),
          label('Xử trí'),
          Wrap(
            spacing: AppSpacing.space2,
            children: [
              for (final action in HealthAction.values)
                AppFilterChip(
                  label: action.label,
                  selected: _health.actions.contains(action),
                  onSelected: enabled ? () => _toggleAction(action) : null,
                ),
            ],
          ),
          if (_health.actions.contains(HealthAction.referral)) ...[
            const SizedBox(height: AppSpacing.space2),
            TextField(
              controller: _place,
              enabled: enabled,
              maxLength: 150,
              onChanged: (value) => _setReferral(place: value),
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Nơi chuyển đến *',
                hintText: 'Ví dụ: Trạm y tế phường',
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Row(
              children: [
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _time,
                    enabled: enabled,
                    keyboardType: TextInputType.datetime,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d:]')),
                      LengthLimitingTextInputFormatter(5),
                    ],
                    onChanged: (value) => _setReferral(time: value),
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Giờ *',
                      hintText: 'hh:mm',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: TextField(
                    controller: _escort,
                    enabled: enabled,
                    maxLength: 100,
                    onChanged: (value) => _setReferral(escort: value),
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Người đi kèm',
                      counterText: '',
                    ),
                  ),
                ),
              ],
            ),
            error(ArrivalHealthField.referral),
          ],
          const SizedBox(height: AppSpacing.space2),
          TextField(
            controller: _note,
            enabled: enabled,
            maxLength: ArrivalHealth.maxNoteLength,
            minLines: 1,
            maxLines: 3,
            onChanged: (value) =>
                widget.onChanged(_health.copyWith(note: value)),
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Ghi chú',
              counterText: '',
            ),
          ),
          error(ArrivalHealthField.note),
        ],
      ],
    );
  }
}

/// Ô thân nhiệt đầu ngày: không bắt buộc, số có 1 chữ số thập phân, hiển thị dấu phẩy ("36,6 °C").
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
        (value < ArrivalHealth.minTemperature ||
            value > ArrivalHealth.maxTemperature);
    setState(() {
      _error = outOfRange ? 'Thân nhiệt phải từ 20,0 đến 45,0 °C' : null;
    });
    // Giá trị ngoài khoảng vẫn chuyển lên để chặn lưu, ô báo lỗi ngay
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    // Nhãn nằm trong ô (không đặt cạnh ô) để chữ phóng lớn không tràn ngang
    return Semantics(
      label: 'Thân nhiệt đầu ngày của ${widget.childName}',
      child: TextField(
        controller: _controller,
        enabled: widget.enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        // Chỉ số và một dấu thập phân, tối đa 1 chữ số sau dấu
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}([.,]\d?)?')),
        ],
        onChanged: _onChanged,
        decoration: InputDecoration(
          isDense: true,
          labelText: 'Thân nhiệt (không bắt buộc)',
          suffixText: '°C',
          errorText: _error,
        ),
      ),
    );
  }
}

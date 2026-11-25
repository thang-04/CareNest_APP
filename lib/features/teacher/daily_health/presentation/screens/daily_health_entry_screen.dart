import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/teacher/daily_health/domain/daily_health.dart';

/// Ghi sức khỏe một bé — field theo BE `DailyHealthRequest`. Validation chỉ hỗ trợ nhập
/// (khoảng thân nhiệt, độ dài); BE kiểm tra lại và quyết định báo phụ huynh (HLT-14).
class DailyHealthEntryScreen extends StatefulWidget {
  const DailyHealthEntryScreen({
    super.key,
    required this.sheet,
    required this.kid,
    required this.source,
  });

  final DailyHealthSheet sheet;
  final DailyHealthKid kid;
  final DailyHealthSource source;

  @override
  State<DailyHealthEntryScreen> createState() => _DailyHealthEntryScreenState();
}

class _DailyHealthEntryScreenState extends State<DailyHealthEntryScreen> {
  final _temperature = TextEditingController();
  final _note = TextEditingController();
  final _place = TextEditingController();
  final _time = TextEditingController();
  final _escort = TextEditingController();
  HealthObservation _observation = HealthObservation.noConcern;
  final Set<HealthSymptom> _symptoms = {};
  final Set<HealthAction> _actions = {};
  String? _temperatureError;
  String? _timeError;
  String? _placeError;
  String? _notedError;
  bool _saving = false;
  String? _saveError;

  /// Một requestId cho một lần nhập; bấm lưu lại sau lỗi mạng gửi cùng id ⇒ BE không ghi trùng.
  late final String _requestId =
      '${widget.kid.childId}-${DateTime.now().microsecondsSinceEpoch}';

  @override
  void dispose() {
    for (final controller in [_temperature, _note, _place, _time, _escort]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Rỗng ⇒ null (thân nhiệt tùy chọn). Nhận cả "37,5" và "37.5".
  double? _parseTemperature() {
    final text = _temperature.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  bool _validate() {
    final text = _temperature.text.trim();
    final value = _parseTemperature();
    String? temperatureError;
    if (text.isNotEmpty) {
      final oneDecimal = RegExp(r'^\d{2}([.,]\d)?$').hasMatch(text);
      if (value == null || !oneDecimal || value < 20 || value > 45) {
        temperatureError = 'Thân nhiệt từ 20,0 đến 45,0 °C, tối đa 1 số lẻ.';
      }
    }
    String? timeError;
    String? placeError;
    final time = _time.text.trim();
    // Chuyển cơ sở y tế: bắt buộc nơi chuyển và giờ (BE DailyHealthServiceImpl, Web dailyHealthValidation)
    final referral =
        _observation == HealthObservation.noted &&
        _actions.contains(HealthAction.referral);
    if (referral && _place.text.trim().isEmpty) {
      placeError = 'Nhập nơi chuyển.';
    }
    if (referral && time.isEmpty) {
      timeError = 'Nhập giờ chuyển.';
    } else if (referral &&
        !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(time)) {
      timeError = 'Nhập giờ dạng HH:mm, ví dụ 09:30.';
    }
    // Cần lưu ý phải có ít nhất một biểu hiện hoặc ghi chú (giống Web)
    final notedError =
        _observation == HealthObservation.noted &&
            _symptoms.isEmpty &&
            _note.text.trim().isEmpty
        ? 'Chọn biểu hiện hoặc ghi chú.'
        : null;
    setState(() {
      _temperatureError = temperatureError;
      _timeError = timeError;
      _placeError = placeError;
      _notedError = notedError;
    });
    return temperatureError == null &&
        timeError == null &&
        placeError == null &&
        notedError == null;
  }

  Future<void> _save() async {
    if (_saving || !_validate()) return;
    final noted = _observation == HealthObservation.noted;
    final referral = noted && _actions.contains(HealthAction.referral);
    String? optional(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.source.save(
        DailyHealthEntry(
          requestId: _requestId,
          classId: widget.sheet.classId,
          childId: widget.kid.childId,
          date: widget.sheet.date,
          temperature: _parseTemperature(),
          observation: _observation,
          symptoms: noted ? _symptoms.toList() : const [],
          actions: noted ? _actions.toList() : const [],
          note: optional(_note),
          referral: referral
              ? HealthReferral(
                  place: optional(_place),
                  time: optional(_time),
                  escort: optional(_escort),
                )
              : null,
          recordedAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      // Giữ nguyên dữ liệu đang nhập để lưu lại
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'Chưa lưu được. Kiểm tra mạng rồi lưu lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final noted = _observation == HealthObservation.noted;
    return Scaffold(
      appBar: AppBar(title: Text(widget.kid.fullName)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          AppTextField(
            label: 'Thân nhiệt (°C)',
            labelSuffix: 'không bắt buộc',
            controller: _temperature,
            hint: '36,8',
            errorText: _temperatureError,
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              LengthLimitingTextInputFormatter(4),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          Text('Quan sát', style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.space2),
          AppSegmented<HealthObservation>(
            segments: [
              for (final value in HealthObservation.values)
                (value, value.label),
            ],
            selected: _observation,
            onChanged: (value) {
              if (_saving) return;
              setState(() => _observation = value);
            },
          ),
          if (noted) ...[
            const SizedBox(height: AppSpacing.space4),
            Text('Biểu hiện', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.space2),
            _chips(HealthSymptom.values, _symptoms, (s) => s.label),
            if (_notedError != null) ...[
              const SizedBox(height: AppSpacing.space2),
              AppBanner(kind: AppBannerKind.danger, message: _notedError!),
            ],
            const SizedBox(height: AppSpacing.space4),
            Text('Đã xử trí', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.space2),
            _chips(HealthAction.values, _actions, (a) => a.label),
            if (_actions.contains(HealthAction.referral)) ...[
              const SizedBox(height: AppSpacing.space3),
              AppTextField(
                label: 'Nơi chuyển',
                controller: _place,
                errorText: _placeError,
                maxLength: 150,
                enabled: !_saving,
              ),
              const SizedBox(height: AppSpacing.space3),
              AppTextField(
                label: 'Giờ chuyển',
                controller: _time,
                hint: 'HH:mm',
                errorText: _timeError,
                keyboardType: TextInputType.datetime,
                enabled: !_saving,
              ),
              const SizedBox(height: AppSpacing.space3),
              AppTextField(
                label: 'Người đi kèm',
                controller: _escort,
                maxLength: 100,
                enabled: !_saving,
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.space4),
          AppTextField(
            label: 'Ghi chú',
            labelSuffix: 'không bắt buộc',
            controller: _note,
            multiline: true,
            maxLength: 500,
            enabled: !_saving,
          ),
          const SizedBox(height: AppSpacing.space3),
          const AppBanner(
            icon: AppIcons.info,
            message: 'Không phải chẩn đoán y tế',
          ),
          if (_saveError != null) ...[
            const SizedBox(height: AppSpacing.space3),
            AppBanner(kind: AppBannerKind.danger, message: _saveError!),
          ],
        ],
      ),
      bottomNavigationBar: AppBottomDock(
        children: [
          AppButton(
            label: _saveError == null ? 'Lưu' : 'Lưu lại',
            loadingLabel: 'Đang lưu',
            isLoading: _saving,
            expand: true,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Widget _chips<T>(List<T> values, Set<T> selected, String Function(T) label) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space1,
      children: [
        for (final value in values)
          AppFilterChip(
            label: label(value),
            selected: selected.contains(value),
            onSelected: _saving
                ? null
                : () => setState(() {
                    if (!selected.remove(value)) selected.add(value);
                  }),
          ),
      ],
    );
  }
}

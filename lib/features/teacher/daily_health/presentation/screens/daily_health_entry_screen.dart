import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/teacher/daily_health/domain/daily_health.dart';

/// Ghi sức khỏe một trẻ + lịch sử trong ngày như khung bên phải của Web — field theo BE `DailyHealthRequest`.
/// Validation chỉ hỗ trợ nhập (khoảng thân nhiệt, độ dài); BE kiểm tra lại và quyết định báo phụ huynh (HLT-14).
/// [readOnly] hoặc BE trả `canRecord = false` ⇒ chỉ xem lịch sử.
class DailyHealthEntryScreen extends StatefulWidget {
  const DailyHealthEntryScreen({
    super.key,
    required this.sheet,
    required this.kid,
    required this.source,
    this.readOnly = false,
  });

  final DailyHealthSheet sheet;
  final DailyHealthKid kid;
  final DailyHealthSource source;
  final bool readOnly;

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

  DailyHealthChildDay? _day;
  bool _historyLoading = true;
  bool _historyFailed = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _historyLoading = true;
      _historyFailed = false;
    });
    try {
      final day = await widget.source.loadChildDay(
        widget.sheet.classId,
        widget.kid.childId,
        date: widget.sheet.date,
      );
      if (!mounted) return;
      setState(() {
        _day = day;
        _historyLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _historyFailed = true;
        _historyLoading = false;
      });
    }
  }

  /// Form chỉ khi màn cho ghi và BE không báo ngược lại (đã trả trẻ, ngày đã qua…).
  bool get _canWrite => !widget.readOnly && (_day?.canRecord ?? true);

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
          if (_day?.handedOverAt case final at?) ...[
            AppBanner(
              icon: AppIcons.lock,
              message:
                  'Đã trả trẻ lúc ${DateLabels.time24(at)}, không ghi thêm.',
            ),
            const SizedBox(height: AppSpacing.space3),
          ] else if (widget.readOnly) ...[
            const AppBanner(
              icon: AppIcons.lock,
              message: 'Đang xem lịch sử, không sửa được',
            ),
            const SizedBox(height: AppSpacing.space3),
          ],
          if (_canWrite) ..._formChildren(textTheme, noted),
          if (_canWrite) const SizedBox(height: AppSpacing.sectionGap),
          Text('Lịch sử trong ngày', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.space3),
          _buildHistory(textTheme),
        ],
      ),
      bottomNavigationBar: !_canWrite
          ? null
          : AppBottomDock(
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

  Widget _buildHistory(TextTheme textTheme) {
    if (_historyLoading) return const AppSkeletonList(rows: 2);
    if (_historyFailed) {
      return AppBanner(
        kind: AppBannerKind.warning,
        message: 'Chưa tải được lịch sử trong ngày.',
        icon: AppIcons.refresh,
      );
    }
    final entries = _day?.entries ?? const <DailyHealthEntry>[];
    if (entries.isEmpty) {
      return Text(
        'Chưa có lần ghi nhận. Lần kiểm tra đã lưu sẽ hiển thị tại đây.',
        style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
      );
    }
    return Column(
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.cardGap),
            child: _HistoryCard(entry: entry),
          ),
      ],
    );
  }

  List<Widget> _formChildren(TextTheme textTheme, bool noted) {
    return [
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
          for (final value in HealthObservation.values) (value, value.label),
        ],
        selected: _observation,
        onChanged: (value) {
          if (_saving) return;
          setState(() => _observation = value);
        },
      ),
      if (noted) ...[
        const SizedBox(height: AppSpacing.space4),
        Text('Biểu hiện ghi nhận', style: textTheme.titleSmall),
        const SizedBox(height: AppSpacing.space2),
        _chips(HealthSymptom.values, _symptoms, (s) => s.label),
        if (_notedError != null) ...[
          const SizedBox(height: AppSpacing.space2),
          AppBanner(kind: AppBannerKind.danger, message: _notedError!),
        ],
        const SizedBox(height: AppSpacing.space4),
        Text('Xử trí', style: textTheme.titleSmall),
        const SizedBox(height: AppSpacing.space2),
        _chips(HealthAction.values, _actions, (a) => a.label),
        if (_actions.contains(HealthAction.referral)) ...[
          const SizedBox(height: AppSpacing.space3),
          AppTextField(
            label: 'Nơi chuyển đến',
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
            label: 'Người đi cùng',
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
    ];
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

/// Một lần ghi đã lưu: giờ, thân nhiệt, quan sát, biểu hiện, xử trí, ghi chú, người ghi.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final DailyHealthEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);
    final referral = entry.referral;
    final lines = [
      if (entry.symptoms.isNotEmpty)
        'Biểu hiện: ${entry.symptoms.map((s) => s.label).join(', ')}',
      if (entry.actions.isNotEmpty)
        'Xử trí: ${entry.actions.map((a) => a.label).join(', ')}',
      if (referral != null)
        'Chuyển đến: ${[if (referral.place?.isNotEmpty ?? false) referral.place!, if (referral.time?.isNotEmpty ?? false) referral.time!, if (referral.escort?.isNotEmpty ?? false) 'đi cùng ${referral.escort}'].join(' · ')}',
      if (entry.note?.isNotEmpty ?? false) 'Ghi chú: ${entry.note}',
    ];
    return AppCard(
      dense: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (entry.recordedAt case final at?)
                Text(DateLabels.time24(at), style: textTheme.titleSmall),
              Text(
                entry.temperature == null
                    ? 'Chưa đo thân nhiệt'
                    : '${entry.temperature!.toStringAsFixed(1).replaceAll('.', ',')} °C',
                style: textTheme.bodyMedium,
              ),
              AppStatusBadge(
                label: entry.observation.label,
                tone: entry.observation == HealthObservation.noted
                    ? AppStatusTone.orange
                    : AppStatusTone.green,
              ),
            ],
          ),
          for (final line in lines) ...[
            const SizedBox(height: AppSpacing.space1),
            Text(line, style: textTheme.bodyMedium),
          ],
          if (entry.recordedByName?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.space1),
            Text('Người ghi: ${entry.recordedByName}', style: muted),
          ],
        ],
      ),
    );
  }
}

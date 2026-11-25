import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/health_measure/data/fake_health_measure_source.dart';
import 'package:carenest_app/features/teacher/health_measure/domain/health_measure.dart';

/// Cân đo một bé: GV nhập lớp mình (HLT-09), lưu là công bố (HLT-11),
/// sửa bắt buộc lý do (HLT-13). Kết quả do BE tính, APP không chẩn đoán.
class HealthMeasureDetailScreen extends StatefulWidget {
  const HealthMeasureDetailScreen({
    super.key,
    required this.childId,
    this.classId = FakeClassRosterSource.classId,
    this.source,
  });

  final String childId;
  final String classId;
  final HealthMeasureSource? source;

  @override
  State<HealthMeasureDetailScreen> createState() =>
      _HealthMeasureDetailScreenState();
}

class _HealthMeasureDetailScreenState extends State<HealthMeasureDetailScreen> {
  late final HealthMeasureSource _source =
      widget.source ?? FakeHealthMeasureSource.shared;
  MeasureMonth? _month;
  MeasureKid? _kid;
  MeasureResult? _result;
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _initializedFields = false;
  bool _saving = false;
  bool _saved = false;
  String? _heightError;
  String? _weightError;
  String? _noteError;
  String? _reasonError;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _noteController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final month = await _source.loadMonth(widget.classId);
    if (!mounted) return;
    final kid = month.kids
        .where((k) => k.childId == widget.childId)
        .firstOrNull;
    MeasureResult? result;
    if (kid?.state == MeasureState.measured) {
      result = await _source.preview(kid!.childId, kid.height!, kid.weight!);
    }
    if (!mounted) return;
    if (!_initializedFields && kid != null) {
      _heightController.text = kid.height ?? '';
      _weightController.text = kid.weight ?? '';
      _noteController.text = kid.note ?? '';
      _initializedFields = true;
    }
    setState(() {
      _month = month;
      _kid = kid;
      _result = result;
    });
  }

  double? _number(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  bool get _changed {
    final kid = _kid;
    if (kid == null) return false;
    if (kid.state != MeasureState.measured) return true;
    return _heightController.text.trim() != (kid.height ?? '') ||
        _weightController.text.trim() != (kid.weight ?? '') ||
        _noteController.text.trim() != (kid.note ?? '');
  }

  bool _validate() {
    final heightText = _heightController.text.trim();
    final weightText = _weightController.text.trim();
    final height = _number(heightText);
    final weight = _number(weightText);
    final decimalPattern = RegExp(r'^\d{1,3}([,.]\d)?$');
    setState(() {
      _heightError = heightText.isEmpty
          ? 'Nhập chiều cao.'
          : !decimalPattern.hasMatch(heightText) ||
                height == null ||
                height < 40 ||
                height > 150
          ? 'Chiều cao từ 40,0 đến 150,0 cm.'
          : null;
      _weightError = weightText.isEmpty
          ? 'Nhập cân nặng.'
          : !decimalPattern.hasMatch(weightText) ||
                weight == null ||
                weight < 3 ||
                weight > 60
          ? 'Cân nặng từ 3,0 đến 60,0 kg.'
          : null;
      _noteError = _noteController.text.length > 500
          ? 'Ghi chú tối đa 500 ký tự.'
          : null;
      _reasonError =
          _kid?.state == MeasureState.measured &&
              _changed &&
              _reasonController.text.trim().isEmpty
          ? 'Nhập lý do sửa số đo.'
          : _reasonController.text.length > 300
          ? 'Lý do tối đa 300 ký tự.'
          : null;
      _submitError = null;
      _saved = false;
    });
    return _heightError == null &&
        _weightError == null &&
        _noteError == null &&
        _reasonError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      await _source.saveMeasurement(
        childId: widget.childId,
        height: _heightController.text.trim(),
        weight: _weightController.text.trim(),
        note: _noteController.text.trim(),
        reason: _reasonController.text.trim(),
      );
      _reasonController.clear();
      _initializedFields = false;
      await _load();
      if (mounted) setState(() => _saved = true);
    } catch (_) {
      if (mounted) {
        setState(() => _submitError = 'Chưa lưu được số đo. Thử lại nhé.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final month = _month;
    final kid = _kid;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(kid?.fullName ?? 'Cân đo')),
      body: month == null
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 3),
            )
          : kid == null
          ? const Center(
              child: AppEmptyState(
                icon: AppIcons.searchOff,
                title: 'Không tìm thấy bé',
                message: 'Bé không có trong lớp được phân công.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                if (kid.state == MeasureState.absent)
                  AppEmptyState(
                    icon: AppIcons.heart,
                    title: 'Bé vắng hôm nay',
                    message: kid.previous == null
                        ? 'Chưa thể nhập số đo.'
                        : 'Số đo gần nhất: ${kid.previous}.',
                  )
                else ...[
                  const AppBanner(
                    icon: AppIcons.info,
                    message: 'Lưu số đo là phụ huynh xem được ngay.',
                  ),
                  if (_saved) ...[
                    const SizedBox(height: AppSpacing.space3),
                    const AppBanner(
                      kind: AppBannerKind.success,
                      message: 'Đã lưu chiều cao và cân nặng.',
                    ),
                  ],
                  if (_submitError != null) ...[
                    const SizedBox(height: AppSpacing.space3),
                    AppBanner(
                      kind: AppBannerKind.danger,
                      message: _submitError!,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.space4),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Số đo', style: textTheme.titleMedium),
                        if (kid.previous != null) ...[
                          const SizedBox(height: AppSpacing.space1),
                          Text(
                            'Gần nhất: ${kid.previous}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.space4),
                        AppTextField(
                          label: 'Chiều cao',
                          labelSuffix: 'cm',
                          controller: _heightController,
                          hint: 'Ví dụ: 104',
                          errorText: _heightError,
                          helperText: '40,0–150,0 cm',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9,.]'),
                            ),
                          ],
                          onChanged: (_) => setState(() {
                            _heightError = null;
                            _saved = false;
                          }),
                        ),
                        const SizedBox(height: AppSpacing.space4),
                        AppTextField(
                          label: 'Cân nặng',
                          labelSuffix: 'kg',
                          controller: _weightController,
                          hint: 'Ví dụ: 17,2',
                          errorText: _weightError,
                          helperText: '3,0–60,0 kg',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9,.]'),
                            ),
                          ],
                          onChanged: (_) => setState(() {
                            _weightError = null;
                            _saved = false;
                          }),
                        ),
                        const SizedBox(height: AppSpacing.space4),
                        AppTextField(
                          label: 'Ghi chú',
                          labelSuffix: 'không bắt buộc',
                          controller: _noteController,
                          hint: 'Thông tin cần lưu ý',
                          multiline: true,
                          maxLength: 500,
                          errorText: _noteError,
                          onChanged: (_) => setState(() {
                            _noteError = null;
                            _saved = false;
                          }),
                        ),
                        if (kid.state == MeasureState.measured && _changed) ...[
                          const SizedBox(height: AppSpacing.space4),
                          AppTextField(
                            label: 'Lý do sửa',
                            controller: _reasonController,
                            hint: 'Ví dụ: Nhập nhầm cân nặng',
                            maxLength: 300,
                            errorText: _reasonError,
                            onChanged: (_) =>
                                setState(() => _reasonError = null),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.space5),
                        AppButton(
                          label: kid.state == MeasureState.measured
                              ? 'Lưu thay đổi'
                              : 'Lưu số đo',
                          loadingLabel: 'Đang lưu…',
                          isLoading: _saving,
                          expand: true,
                          icon: AppIcons.check,
                          onPressed: _changed && !_saving ? _save : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  if (_result case final result?)
                    AppCard(
                      dense: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Kết quả tính theo quy tắc của trường',
                            style: textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.space2),
                          Wrap(
                            spacing: AppSpacing.space2,
                            runSpacing: AppSpacing.space1,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              AppStatusBadge(
                                label: result.label,
                                tone: AppStatusTone.green,
                              ),
                              Text(
                                result.detail,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.space3),
                          _ResultScale(position: result.position),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: AppSpacing.space3),
                Text(
                  'Kết quả do hệ thống tính, không phải chẩn đoán y tế. Mọi lần sửa đều được lưu.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Thang Thiếu cân – Bình thường – Thừa cân; vị trí chấm do BE trả, có nhãn chữ bên dưới.
class _ResultScale extends StatelessWidget {
  const _ResultScale({required this.position});

  final double position;

  @override
  Widget build(BuildContext context) {
    final green = AppStatusColors.of(context).tone(AppStatusTone.green);
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: AppColors.textMuted,
      fontWeight: FontWeight.w500,
    );
    return ExcludeSemantics(
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: 16,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.track,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  Positioned(
                    left: constraints.maxWidth / 3,
                    width: constraints.maxWidth / 3,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: green.border,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (constraints.maxWidth - 14) * position.clamp(0, 1),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: green.foreground,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Row(
            children: [
              Expanded(child: Text('Thiếu cân', style: labelStyle)),
              Expanded(
                child: Text(
                  'Bình thường',
                  textAlign: TextAlign.center,
                  style: labelStyle,
                ),
              ),
              Expanded(
                child: Text(
                  'Thừa cân',
                  textAlign: TextAlign.end,
                  style: labelStyle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

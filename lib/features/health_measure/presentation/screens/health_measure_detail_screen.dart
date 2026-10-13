import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/health_measure/data/fake_health_measure_source.dart';
import 'package:carenest_app/features/health_measure/domain/health_measure.dart';

/// Đo chiều cao, cân nặng — một bé (mockup T07.1). Kết quả xếp loại do BE tính (P-13 PENDING),
/// APP không tự so chuẩn; không chẩn đoán (HLT-04).
class HealthMeasureDetailScreen extends StatefulWidget {
  const HealthMeasureDetailScreen({
    super.key,
    required this.childId,
    required this.onSaved,
    this.classId = FakeClassRosterSource.classId,
    this.source,
  });

  final String childId;
  final VoidCallback onSaved;
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
  final _height = TextEditingController();
  final _weight = TextEditingController();
  MeasureResult? _result;
  bool _publish = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _source.loadMonth(widget.classId).then((month) {
      if (!mounted) return;
      final kid = month.kids
          .where((k) => k.childId == widget.childId)
          .firstOrNull;
      setState(() {
        _month = month;
        _kid = kid;
        _height.text = kid?.height ?? '';
        _weight.text = kid?.weight ?? '';
        _publish = kid?.published ?? true;
      });
      _preview();
    });
  }

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _preview() async {
    final kid = _kid;
    if (kid == null) return;
    final result = await _source.preview(
      kid.childId,
      _height.text,
      _weight.text,
    );
    if (mounted) setState(() => _result = result);
  }

  Future<void> _save() async {
    final kid = _kid!;
    if (_height.text.trim().isEmpty || _weight.text.trim().isEmpty) {
      setState(() => _error = 'Nhập đủ chiều cao và cân nặng.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await _source.save(
      MeasureKid(
        childId: kid.childId,
        fullName: kid.fullName,
        ageLabel: kid.ageLabel,
        state: MeasureState.measured,
        height: _height.text.trim(),
        weight: _weight.text.trim(),
        measuredWhen: 'vừa xong',
        previous: kid.previous,
        published: _publish,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final month = _month;
    final kid = _kid;
    final textTheme = Theme.of(context).textTheme;
    final measured = month?.kids
        .where((k) => k.state == MeasureState.measured)
        .length;
    // Chỉ cho nhập số, dấu phẩy/chấm thập phân; kiểm khoảng hợp lệ là việc của BE
    final numberOnly = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    return Scaffold(
      appBar: AppBar(
        title: Text(month?.title ?? 'Đo sức khỏe'),
        actions: [
          if (measured != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.space4),
              child: Center(
                child: Text(
                  '$measured/${month!.kids.length} bé',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: kid == null
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 3),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                AppCard(
                  dense: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${kid.fullName} · ${kid.ageLabel}',
                        style: textTheme.titleSmall,
                      ),
                      if (kid.previous != null)
                        Text(
                          'Lần trước ${kid.previous}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                AppTextField(
                  label: 'Chiều cao (cm)',
                  labelSuffix: '*',
                  controller: _height,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: numberOnly,
                  onChanged: (_) => _preview(),
                ),
                const SizedBox(height: AppSpacing.space3),
                AppTextField(
                  label: 'Cân nặng (kg)',
                  labelSuffix: '*',
                  controller: _weight,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: numberOnly,
                  onChanged: (_) => _preview(),
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
                const SizedBox(height: AppSpacing.space3),
                AppCard(
                  flush: true,
                  // ListTile vẽ hiệu ứng chạm lên Material gần nhất ⇒ cần Material trong suốt trong card
                  child: Material(
                    type: MaterialType.transparency,
                    child: SwitchListTile(
                      value: _publish,
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _publish = value),
                      title: Text(
                        'Công bố cho phụ huynh',
                        style: textTheme.titleSmall,
                      ),
                      subtitle: const Text('Phụ huynh xem ở mục Sức khỏe'),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.space3),
                  AppBanner(kind: AppBannerKind.danger, message: _error!),
                ],
                const SizedBox(height: AppSpacing.space3),
                Text(
                  'Không phải chẩn đoán y tế. Lịch sử chỉnh sửa được lưu lại.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
      bottomNavigationBar: kid == null
          ? null
          : AppBottomDock(
              children: [
                AppButton(
                  label: 'Lưu & về danh sách',
                  loadingLabel: 'Đang lưu',
                  isLoading: _saving,
                  expand: true,
                  onPressed: _save,
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

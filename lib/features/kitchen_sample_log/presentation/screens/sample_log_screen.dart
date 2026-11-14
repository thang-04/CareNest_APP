import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_bottom_sheet.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/features/kitchen_sample_log/data/fake_sample_log_source.dart';
import 'package:carenest_app/features/kitchen_sample_log/domain/sample_log.dart';
import 'package:carenest_app/features/kitchen_sample_log/presentation/widgets/boxed_field.dart';

/// Sổ lưu mẫu thức ăn mỗi bữa (NUT-21) — Figma Bếp 06: bếp ghi, PHT dinh dưỡng duyệt; giờ lấy mẫu do hệ thống ghi.
class SampleLogScreen extends StatefulWidget {
  const SampleLogScreen({super.key, required this.onSaved, this.source});

  final VoidCallback onSaved;
  final SampleLogSource? source;

  @override
  State<SampleLogScreen> createState() => _SampleLogScreenState();
}

class _SampleLogScreenState extends State<SampleLogScreen> {
  late final SampleLogSource _source =
      widget.source ?? FakeSampleLogSource.shared;
  SampleLogForm? _form;
  SampleDish? _dish;
  final _amount = TextEditingController();
  final _temperature = TextEditingController();
  bool _saving = false;
  String? _amountError;
  String? _temperatureError;

  @override
  void initState() {
    super.initState();
    _source.loadForm().then((form) {
      if (!mounted) return;
      setState(() {
        _form = form;
        _dish =
            form.dishes
                .where((dish) => dish.id == form.suggestedDishId)
                .firstOrNull ??
            form.dishes.firstOrNull;
      });
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _temperature.dispose();
    super.dispose();
  }

  void _pickDish(List<SampleDish> dishes) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Bữa · món lưu mẫu',
      builder: (sheetContext) => Column(
        children: [
          for (final dish in dishes)
            AppSheetOption(
              selected: dish.id == _dish?.id,
              onTap: () {
                Navigator.of(sheetContext).pop();
                setState(() => _dish = dish);
              },
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(dish.label),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _amountError = _amount.text.trim().isEmpty
          ? 'Nhập khối lượng và dụng cụ chứa.'
          : null;
      _temperatureError = _temperature.text.trim().isEmpty
          ? 'Nhập nhiệt độ bảo quản.'
          : null;
    });
    final dish = _dish;
    if (_amountError != null || _temperatureError != null || dish == null) {
      return;
    }
    setState(() => _saving = true);
    await _source.record(
      SampleLogEntry(
        dishId: dish.id,
        amountAndContainer: _amount.text.trim(),
        storageTemperature: _temperature.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final form = _form;
    return Scaffold(
      appBar: AppBar(title: const Text('Sổ lưu mẫu')),
      body: form == null
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 4),
            )
          : _buildForm(form),
      bottomNavigationBar: form == null
          ? null
          : AppBottomDock(
              children: [
                AppButton(
                  label: 'Ghi lưu mẫu',
                  loadingLabel: 'Đang ghi',
                  isLoading: _saving,
                  expand: true,
                  onPressed: _save,
                ),
              ],
            ),
    );
  }

  Widget _buildForm(SampleLogForm form) {
    // Chữ phóng lớn ⇒ hai ô xếp dọc thay vì chia đôi hàng (DESIGN.md §5.1)
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    // Chia đôi hàng: nhãn khối lượng xuống 2 dòng ⇒ hai ô cùng cao cho thẳng hàng
    final pairHeight = stacked ? 56.0 : 74.0;
    final amount = BoxedTextField(
      label: 'Khối lượng · dụng cụ chứa',
      isRequired: true,
      hint: '150 g · hộp inox có nắp',
      controller: _amount,
      errorText: _amountError,
      enabled: !_saving,
      minHeight: pairHeight,
      onChanged: (_) {
        if (_amountError != null) setState(() => _amountError = null);
      },
    );
    final temperature = BoxedTextField(
      label: 'Nhiệt độ bảo quản',
      isRequired: true,
      hint: '0–5 °C',
      controller: _temperature,
      errorText: _temperatureError,
      enabled: !_saving,
      minHeight: pairHeight,
      onChanged: (_) {
        if (_temperatureError != null) {
          setState(() => _temperatureError = null);
        }
      },
    );
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        BoxedField(
          label: 'Bữa · món lưu mẫu',
          isRequired: true,
          onTap: _saving || form.dishes.isEmpty
              ? null
              : () => _pickDish(form.dishes),
          trailing: const Icon(
            AppIcons.chevronDown,
            size: AppSizes.iconInline,
            color: AppColors.textMuted,
          ),
          child: Text(_dish?.label ?? 'Chọn món'),
        ),
        const SizedBox(height: AppSpacing.space3),
        if (stacked) ...[
          amount,
          const SizedBox(height: AppSpacing.space3),
          temperature,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: amount),
              const SizedBox(width: AppSpacing.space2),
              Expanded(child: temperature),
            ],
          ),
        const SizedBox(height: AppSpacing.space3),
        BoxedField(
          label: 'Giờ lấy mẫu',
          readOnly: true,
          child: Text(
            '${DateLabels.time24(form.sampledAt)} · hủy sau ít nhất 24 giờ',
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        // Domain chưa có trường ghi chú ⇒ chỉ hiện lời nhắc, không cho nhập
        const BoxedField(
          label: 'Ghi chú',
          readOnly: true,
          minHeight: 72,
          child: Text('Mẫu đủ món theo thực đơn đã công bố.'),
        ),
        const SizedBox(height: AppSpacing.space3),
        const AppBanner(
          kind: AppBannerKind.warning,
          message: 'PHT dinh dưỡng duyệt; sau ít nhất 24 giờ bếp ghi hủy mẫu.',
        ),
      ],
    );
  }
}

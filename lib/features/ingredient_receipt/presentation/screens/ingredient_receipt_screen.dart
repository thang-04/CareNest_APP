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
import 'package:carenest_app/features/ingredient_receipt/data/fake_ingredient_receipt_source.dart';
import 'package:carenest_app/features/ingredient_receipt/domain/ingredient_receipt.dart';

/// Nhận nguyên liệu — mockup K05 (nghiệp vụ mới, PROPOSED). Bếp nhập số thực nhận theo phiếu;
/// BE ghi chênh lệch và báo Phó HT khi xác nhận.
class IngredientReceiptScreen extends StatefulWidget {
  const IngredientReceiptScreen({
    super.key,
    required this.onReportShortage,
    required this.onConfirmed,
    this.source,
  });

  final VoidCallback onReportShortage;
  final VoidCallback onConfirmed;
  final IngredientReceiptSource? source;

  @override
  State<IngredientReceiptScreen> createState() =>
      _IngredientReceiptScreenState();
}

class _IngredientReceiptScreenState extends State<IngredientReceiptScreen> {
  late final IngredientReceiptSource _source =
      widget.source ?? FakeIngredientReceiptSource.shared;
  List<ReceiptLot>? _lots;
  final Map<String, TextEditingController> _inputs = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _source.loadLots().then((lots) {
      if (!mounted) return;
      setState(() {
        _lots = lots;
        for (final item in lots.first.items) {
          _inputs[item.food] = TextEditingController(
            text: item.received == null ? '' : formatQuantity(item.received!),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    for (final controller in _inputs.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // So số nhập với số phiếu chỉ để nhắc khi nhập; chênh lệch chính thức do BE ghi
  double? _shortBy(ReceiptItem item) {
    final received = parseQuantity(_inputs[item.food]!.text);
    if (received == null || received >= item.expected) return null;
    return item.expected - received;
  }

  Future<void> _confirm() async {
    final lot = _lots!.first;
    setState(() => _saving = true);
    await _source.confirm(lot.id, {
      for (final item in lot.items)
        item.food: parseQuantity(_inputs[item.food]!.text) ?? 0,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    final lots = _lots;
    final textTheme = Theme.of(context).textTheme;
    final lot = lots?.first;
    final shortCount =
        lot?.items.where((item) => _shortBy(item) != null).length ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhận nguyên liệu'),
        actions: [
          if (lots != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.space4),
              child: Center(
                child: Text(
                  '${lots.length} lô',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: lot == null
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 5),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                AppCard(
                  dense: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lot.title, style: textTheme.titleSmall),
                      Text(
                        lot.subtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                for (final item in lot.items) ...[
                  _ItemRow(
                    item: item,
                    controller: _inputs[item.food]!,
                    shortBy: _shortBy(item),
                    enabled: !_saving,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                ],
                if (shortCount > 0) ...[
                  const SizedBox(height: AppSpacing.space1),
                  AppBanner(
                    kind: AppBannerKind.danger,
                    message:
                        'Có $shortCount chênh lệch. Hệ thống tự báo cho Phó hiệu trưởng khi xác nhận.',
                  ),
                ],
                for (final other in lots!.skip(1)) ...[
                  const SizedBox(height: AppSpacing.space3),
                  AppCard(
                    dense: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(other.title, style: textTheme.titleSmall),
                        Text(
                          other.subtitle,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: lot == null
          ? null
          : AppBottomDock(
              children: [
                AppButton(
                  label: 'Báo thiếu thực phẩm',
                  variant: AppButtonVariant.danger,
                  expand: true,
                  onPressed: _saving ? null : widget.onReportShortage,
                ),
                AppButton(
                  label: 'Xác nhận số thực nhận',
                  loadingLabel: 'Đang xác nhận',
                  isLoading: _saving,
                  expand: true,
                  onPressed: _confirm,
                ),
              ],
            ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.controller,
    required this.shortBy,
    required this.enabled,
    required this.onChanged,
  });

  final ReceiptItem item;
  final TextEditingController controller;
  final double? shortBy;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final danger = AppStatusColors.of(context).feedbackOf(AppFeedback.danger);
    final short = shortBy != null;
    final expected =
        'Theo phiếu: ${formatQuantity(item.expected)} ${item.unit}';
    final hint = short
        ? '$expected · Thiếu ${formatQuantity(shortBy!)} ${item.unit}'
        : expected;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: short ? danger.main : AppColors.border,
          width: short ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.food, style: textTheme.titleSmall),
                Text(
                  hint,
                  style: textTheme.bodyMedium?.copyWith(
                    color: short ? danger.foreground : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          SizedBox(
            width: 96,
            child: TextField(
              controller: controller,
              enabled: enabled,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              onChanged: (_) => onChanged(),
              style: textTheme.titleSmall,
              decoration: InputDecoration(
                isDense: true,
                labelText: item.unit,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                semanticCounterText: '',
                hintText: '0',
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space3,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide(
                    color: short ? danger.main : AppColors.borderStrong,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

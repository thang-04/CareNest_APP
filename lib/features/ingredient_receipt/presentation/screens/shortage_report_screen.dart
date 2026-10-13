import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_bottom_sheet.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/ingredient_receipt/data/fake_ingredient_receipt_source.dart';
import 'package:carenest_app/features/ingredient_receipt/domain/ingredient_receipt.dart';

/// Báo thiếu thực phẩm — mockup K06 (nghiệp vụ mới, PROPOSED). Gửi cho Phó HT để bổ sung hoặc đổi món.
class ShortageReportScreen extends StatefulWidget {
  const ShortageReportScreen({super.key, required this.onSent, this.source});

  final VoidCallback onSent;
  final IngredientReceiptSource? source;

  @override
  State<ShortageReportScreen> createState() => _ShortageReportScreenState();
}

class _ShortageReportScreenState extends State<ShortageReportScreen> {
  late final IngredientReceiptSource _source =
      widget.source ?? FakeIngredientReceiptSource.shared;
  List<ReceiptItem> _items = const [];
  String? _food;
  final _amount = TextEditingController();
  final _neededBy = TextEditingController(text: '10:00 hôm nay');
  final _impact = TextEditingController();
  final _note = TextEditingController();
  bool _sending = false;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    _source.loadLots().then((lots) {
      if (!mounted) return;
      final items = lots.first.items;
      // Gợi ý sẵn món đang nhận thiếu ở màn trước; bếp sửa được
      final short = items
          .where((i) => i.received != null && i.received! < i.expected)
          .firstOrNull;
      setState(() {
        _items = items;
        _food = short?.food ?? items.firstOrNull?.food;
        if (short != null) {
          _amount.text =
              '${formatQuantity(short.expected - short.received!)} ${short.unit}';
          _impact.text = 'Thiếu khoảng 13 suất cá sốt cà (bữa trưa)';
        }
      });
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _neededBy.dispose();
    _impact.dispose();
    _note.dispose();
    super.dispose();
  }

  void _pickFood() {
    showAppBottomSheet<void>(
      context: context,
      title: 'Thực phẩm bị thiếu',
      builder: (sheetContext) => Column(
        children: [
          for (final item in _items)
            AppSheetOption(
              selected: item.food == _food,
              onTap: () {
                Navigator.of(sheetContext).pop();
                setState(() => _food = item.food);
              },
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(item.food),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    setState(
      () => _amountError = _amount.text.trim().isEmpty
          ? 'Nhập số lượng thiếu.'
          : null,
    );
    if (_amountError != null || _food == null) return;
    setState(() => _sending = true);
    await _source.reportShortage(
      ShortageReport(
        food: _food!,
        amount: _amount.text.trim(),
        neededBy: _neededBy.text.trim(),
        impact: _impact.text.trim(),
        note: _note.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    widget.onSent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo thiếu thực phẩm')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          AppSelectField(
            label: 'Thực phẩm bị thiếu',
            labelSuffix: '*',
            value: _food ?? 'Chọn thực phẩm',
            onTap: _sending || _items.isEmpty ? null : _pickFood,
          ),
          const SizedBox(height: AppSpacing.space4),
          AppTextField(
            label: 'Số lượng thiếu',
            labelSuffix: '*',
            controller: _amount,
            errorText: _amountError,
            enabled: !_sending,
          ),
          const SizedBox(height: AppSpacing.space4),
          AppTextField(
            label: 'Cần trước',
            controller: _neededBy,
            enabled: !_sending,
          ),
          const SizedBox(height: AppSpacing.space4),
          AppTextField(
            label: 'Ảnh hưởng',
            controller: _impact,
            multiline: true,
            enabled: !_sending,
          ),
          const SizedBox(height: AppSpacing.space4),
          AppTextField(
            label: 'Ghi chú',
            hint: 'Ví dụ: nhà cung cấp giao thiếu, đã gọi bổ sung',
            controller: _note,
            multiline: true,
            enabled: !_sending,
          ),
          const SizedBox(height: AppSpacing.space4),
          const AppBanner(
            kind: AppBannerKind.warning,
            message:
                'Gửi ngay cho Phó HT để bổ sung hàng hoặc đổi món thay thế.',
          ),
        ],
      ),
      bottomNavigationBar: AppBottomDock(
        children: [
          AppButton(
            label: 'Gửi báo thiếu cho Phó HT',
            loadingLabel: 'Đang gửi',
            isLoading: _sending,
            expand: true,
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}

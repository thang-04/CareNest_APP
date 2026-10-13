import 'package:flutter/foundation.dart';

/// Nhận nguyên liệu theo phiếu xuất kho — nghiệp vụ mới, PROPOSED (plan quyết định 7, Q2–Q3).
/// Chênh lệch và "báo Phó HT" do BE xử lý; APP chỉ so số nhập với số phiếu để nhắc khi nhập.
@immutable
class ReceiptItem {
  const ReceiptItem({
    required this.food,
    required this.expected,
    required this.unit,
    this.received,
  });

  final String food;
  final double expected;

  /// "kg", "quả"
  final String unit;
  final double? received;
}

@immutable
class ReceiptLot {
  const ReceiptLot({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.items,
    this.arrived = true,
  });

  final String id;

  /// "Lô 1 · Theo phiếu PXK-1012"
  final String title;

  /// "Giao từ kho lúc 07:30 · nhập số thực nhận"
  final String subtitle;
  final List<ReceiptItem> items;

  /// Lô chưa giao ⇒ chỉ hiện dòng tóm tắt.
  final bool arrived;
}

@immutable
class ShortageReport {
  const ShortageReport({
    required this.food,
    required this.amount,
    required this.neededBy,
    required this.impact,
    this.note = '',
  });

  final String food;
  final String amount;
  final String neededBy;
  final String impact;
  final String note;
}

abstract interface class IngredientReceiptSource {
  Future<List<ReceiptLot>> loadLots();
  Future<void> confirm(String lotId, Map<String, double> received);
  Future<void> reportShortage(ShortageReport report);
}

/// Số thập phân kiểu Việt Nam: "9,8" ⇄ 9.8.
double? parseQuantity(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

String formatQuantity(double value) =>
    value.toStringAsFixed(1).replaceAll('.', ',');

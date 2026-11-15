import 'package:carenest_app/features/food_quantities/data/fake_food_quantity_source.dart';
import 'package:carenest_app/features/ingredient_receipt/domain/ingredient_receipt.dart';

/// Dữ liệu giả mockup K05/K06, khớp phiếu ở màn Định lượng (K04); cá basa nhận thiếu 0,7 kg.
class FakeIngredientReceiptSource implements IngredientReceiptSource {
  FakeIngredientReceiptSource();

  static final shared = FakeIngredientReceiptSource();

  final List<ShortageReport> reports = [];

  @override
  Future<List<ReceiptLot>> loadLots() async => const [
    ReceiptLot(
      id: 'lot-1',
      title: 'Lô 1 · Theo phiếu ${FakeFoodQuantitySource.slipCode}',
      subtitle: 'Giao từ kho lúc 07:30 · nhập số thực nhận',
      items: [
        ReceiptItem(
          food: 'Thịt lợn nạc',
          expected: 9.1,
          unit: 'kg',
          received: 9.1,
        ),
        ReceiptItem(
          food: 'Cá basa phi lê',
          expected: 10.5,
          unit: 'kg',
          received: 9.8,
        ),
        ReceiptItem(food: 'Bí đỏ', expected: 12.0, unit: 'kg', received: 12.0),
        ReceiptItem(food: 'Cà chua', expected: 3.0, unit: 'kg', received: 3.0),
        ReceiptItem(food: 'Thịt gà', expected: 0.7, unit: 'kg', received: 0.7),
      ],
    ),
    ReceiptLot(
      id: 'lot-2',
      title: 'Lô 2 · Rau, quả tươi',
      subtitle: 'Nhà cung cấp giao dự kiến 09:30 · chưa giao',
      items: [],
      arrived: false,
    ),
  ];

  @override
  Future<void> confirm(String lotId, Map<String, double> received) async {}

  @override
  Future<void> reportShortage(ShortageReport report) async =>
      reports.add(report);
}

import 'package:carenest_app/features/approvals/domain/meal_adjustment.dart';

/// Dữ liệu giả mockup V02–V03: hai yêu cầu sau giờ chốt 08:30 ở cơ sở chính.
/// Mầm 3A +1 khớp K03 (Mầm 3A xin +1 suất, chờ Phó HT duyệt). Bản dùng chung để danh sách thấy quyết định.
class FakeMealAdjustmentSource implements MealAdjustmentSource {
  FakeMealAdjustmentSource();

  static final shared = FakeMealAdjustmentSource();

  final List<MealAdjustment> _items = [
    MealAdjustment(
      id: 'adj-mam-3a',
      className: 'Mầm 3A',
      fromCount: 24,
      toCount: 25,
      deltaLabel: '+1 suất',
      senderName: 'Cô Trần Thu Hà',
      sentAt: DateTime(2026, 10, 12, 9, 5),
      reason: 'bé đến muộn, GV sửa điểm danh',
      summary: 'GV sửa điểm danh 09:05',
      cutoffLabel: 'sau giờ chốt 08:30',
      statusLabel: 'Chờ Phó HT',
      childrenTitle: 'Bé được thêm suất',
      children: const [
        AdjustmentChild(
          fullName: 'Nguyễn Minh Anh',
          note: 'Đến lớp 08:52 · suất thường · không dị ứng',
        ),
      ],
      kitchenTitle: 'Bữa trưa: Đang nấu',
      kitchenNote: 'Bắt đầu 09:10 · còn kịp chia thêm 1 suất',
      kitchenBadge: 'Kịp',
      totalNow: 182,
      totalAfter: 183,
      splitAfter: '176 / 7',
    ),
    MealAdjustment(
      id: 'adj-choi-2',
      className: 'Chồi 2',
      fromCount: 31,
      toCount: 29,
      deltaLabel: '−2 suất',
      senderName: 'Cô Lê Thị Nga',
      sentAt: DateTime(2026, 10, 12, 9, 10),
      reason: 'hai bé được đón về sau khi điểm danh',
      summary: 'GV báo về sớm 09:10',
      cutoffLabel: 'sau giờ chốt 08:30',
      statusLabel: 'Chờ Phó HT',
      childrenTitle: 'Bé bớt suất',
      children: const [
        AdjustmentChild(
          fullName: 'Nguyễn Hải Đăng',
          note: 'Về lúc 09:00 · suất thường',
        ),
        AdjustmentChild(
          fullName: 'Trần Khả Hân',
          note: 'Về lúc 09:05 · suất thường',
        ),
      ],
      kitchenTitle: 'Bữa trưa: Đang nấu',
      kitchenNote: 'Bắt đầu 09:10 · đã chia phần, bớt được 2 suất',
      kitchenBadge: 'Kịp',
      totalNow: 182,
      totalAfter: 180,
      splitAfter: '173 / 7',
    ),
  ];

  @override
  Future<List<MealAdjustment>> loadPending() async =>
      _items.where((item) => item.decision == RequestDecision.pending).toList();

  @override
  Future<MealAdjustment?> loadOne(String id) async =>
      _items.where((item) => item.id == id).firstOrNull;

  @override
  Future<void> decide(
    String id, {
    required bool approve,
    String? reason,
  }) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Không tìm thấy yêu cầu');
    _items[index] = _items[index].decided(
      approve ? RequestDecision.approved : RequestDecision.rejected,
    );
  }
}

import 'package:carenest_app/features/reward_proposals/domain/reward_proposal.dart';

/// Dữ liệu giả mockup V12: 8 đề xuất chờ xét (7 hợp lệ, 1 không hợp lệ), tên trẻ khớp danh sách Mầm 3A.
/// Bản dùng chung để Trang chủ và tab Duyệt thấy cùng số.
class FakeRewardProposalSource implements RewardProposalSource {
  FakeRewardProposalSource();

  static final shared = FakeRewardProposalSource();

  @override
  String get schoolYear => '2026–2027';

  final List<RewardProposal> _items = [
    for (final (id, name, className, award, evidence) in const [
      ('rw-1', 'Nguyễn Minh Anh', 'Mầm 3A', 'Bé ngoan toàn diện', '10/10'),
      ('rw-2', 'Lê Hoàng Nam', 'Mầm 3A', 'Bé chăm ngoan', '8/10'),
      ('rw-3', 'Trần Bảo Ngọc', 'Mầm 3A', 'Bé khéo tay', '9/10'),
      ('rw-5', 'Bùi Gia Thịnh', 'Mầm 3A', 'Bé chăm ngoan', '9/10'),
      ('rw-6', 'Lê Bảo Châu', 'Chồi 2', 'Bé ngoan toàn diện', '10/10'),
      ('rw-7', 'Phạm Thảo Nguyên', 'Lá 1', 'Bé học giỏi', '9/10'),
      ('rw-8', 'Phan Đức Mạnh', 'Lá 2', 'Bé chăm ngoan', '8/10'),
    ])
      RewardProposal(
        id: id,
        childName: name,
        className: className,
        awardTitle: award,
        evidence: '$evidence phiếu bé ngoan',
        isValid: true,
        stage: RewardStage.pending,
      ),
    const RewardProposal(
      id: 'rw-4',
      childName: 'Vũ Đức Huy',
      className: 'Mầm 3A',
      awardTitle: 'Bé chăm ngoan',
      evidence: '4/10 phiếu',
      isValid: false,
      invalidReason: 'chưa đủ điều kiện',
      stage: RewardStage.pending,
    ),
  ]..sort((a, b) => a.id.compareTo(b.id));

  @override
  Future<List<RewardProposal>> load() async => List.of(_items);

  void _move(bool valid, RewardStage to) {
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.stage == RewardStage.pending && item.isValid == valid) {
        _items[i] = item.moved(to);
      }
    }
  }

  @override
  Future<void> sendValidToPrincipal() async =>
      _move(true, RewardStage.sentToPrincipal);

  @override
  Future<void> returnInvalid() async => _move(false, RewardStage.returned);
}

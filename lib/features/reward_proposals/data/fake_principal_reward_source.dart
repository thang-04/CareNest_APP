import 'package:carenest_app/features/reward_proposals/data/fake_reward_proposal_source.dart';
import 'package:carenest_app/features/reward_proposals/domain/reward_batch.dart';
import 'package:carenest_app/features/reward_proposals/domain/reward_proposal.dart';

/// Dữ liệu giả mockup H02 / H04: đợt khen thưởng cuối năm cơ sở chính gồm đúng 7 đề xuất hợp lệ
/// Phó HT gửi ở V12, cùng hai đợt đã xử lý gần đây. Bản dùng chung để Tổng quan và tab Duyệt thấy cùng số.
class FakePrincipalRewardSource implements PrincipalRewardSource {
  FakePrincipalRewardSource();

  static final shared = FakePrincipalRewardSource();

  List<RewardBatch>? _batches;

  Future<List<RewardBatch>> _ensure() async {
    final existing = _batches;
    if (existing != null) return existing;
    final sent = (await FakeRewardProposalSource().load())
        .where((item) => item.isValid)
        .map((item) => item.moved(RewardStage.sentToPrincipal))
        .toList();
    return _batches = [
      RewardBatch(
        id: 'batch-main-year',
        title: 'Khen thưởng cuối năm',
        campusName: 'Cơ sở chính',
        reviewNote:
            'Phó HT Lê Văn Bình đã xét và gửi lên 12/10. 1 đề xuất không hợp lệ đã trả về giáo viên.',
        proposals: sent,
        status: RewardBatchStatus.pending,
      ),
      const RewardBatch(
        id: 'batch-cs2-month',
        title: 'Khen thưởng tháng 9',
        campusName: 'Cơ sở 2',
        reviewNote: 'Phó HT Vũ Thị Hạnh đã xét và gửi lên 07/10.',
        proposals: [],
        status: RewardBatchStatus.approved,
        decisionNote: 'Đã duyệt 08/10 · 5 bé',
      ),
      const RewardBatch(
        id: 'batch-choi-2-hk1',
        title: 'Khen thưởng HK1 · Chồi 2',
        campusName: 'Cơ sở chính',
        reviewNote: 'Phó HT Lê Văn Bình đã xét và gửi lên 04/10.',
        proposals: [],
        status: RewardBatchStatus.returned,
        decisionNote: 'Trả về 05/10 · thiếu minh chứng',
      ),
    ];
  }

  @override
  Future<List<RewardBatch>> loadBatches() async => List.of(await _ensure());

  @override
  Future<RewardBatch?> loadBatch(String id) async =>
      (await _ensure()).where((batch) => batch.id == id).firstOrNull;

  void _replace(String id, RewardBatch Function(RewardBatch) update) {
    final batches = _batches!;
    final index = batches.indexWhere((batch) => batch.id == id);
    if (index < 0) throw StateError('Không tìm thấy đợt đề xuất');
    batches[index] = update(batches[index]);
  }

  @override
  Future<void> approve(
    String id, {
    required Set<String> approvedIds,
    String? note,
  }) async {
    await _ensure();
    _replace(
      id,
      (batch) => RewardBatch(
        id: batch.id,
        title: batch.title,
        campusName: batch.campusName,
        reviewNote: batch.reviewNote,
        proposals: batch.proposals,
        status: RewardBatchStatus.approved,
        decisionNote: 'Đã duyệt 12/10 · ${approvedIds.length} bé',
      ),
    );
  }

  @override
  Future<void> returnToVicePrincipal(String id, {required String note}) async {
    await _ensure();
    _replace(
      id,
      (batch) => RewardBatch(
        id: batch.id,
        title: batch.title,
        campusName: batch.campusName,
        reviewNote: batch.reviewNote,
        proposals: batch.proposals,
        status: RewardBatchStatus.returned,
        decisionNote: 'Trả về 12/10 · $note',
      ),
    );
  }
}

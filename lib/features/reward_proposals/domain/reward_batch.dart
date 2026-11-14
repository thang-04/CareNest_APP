import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/reward_proposals/domain/reward_proposal.dart';

/// Kết quả Hiệu trưởng xử lý một đợt đề xuất (OBS-10 PROPOSED).
enum RewardBatchStatus { pending, approved, returned }

/// Một đợt đề xuất khen thưởng Phó HT đã xét và gửi lên Hiệu trưởng (mockup H02, H04).
/// Chỉ gồm đề xuất hợp lệ theo BE; tiêu chí P-11 PENDING.
@immutable
class RewardBatch {
  const RewardBatch({
    required this.id,
    required this.title,
    required this.campusName,
    required this.reviewNote,
    required this.proposals,
    required this.status,
    this.decisionNote,
  });

  final String id;

  /// "Khen thưởng cuối năm"
  final String title;
  final String campusName;

  /// "Phó HT Lê Văn Bình đã xét và gửi lên 12/10…"
  final String reviewNote;
  final List<RewardProposal> proposals;
  final RewardBatchStatus status;

  /// Đợt đã xử lý: "Đã duyệt 08/10 · 5 bé", "Trả về 05/10 · thiếu minh chứng"
  final String? decisionNote;
}

/// Chỉ đọc: HT duyệt khen thưởng trên Web, App chỉ xem (AUTH-21, BE ADR-0026).
abstract interface class PrincipalRewardSource {
  Future<List<RewardBatch>> loadBatches();
  Future<RewardBatch?> loadBatch(String id);
}

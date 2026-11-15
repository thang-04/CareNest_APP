import 'package:flutter/foundation.dart';

/// Chặng của đề xuất khen thưởng (OBS-10 PROPOSED): giáo viên gửi → Phó HT xét → Hiệu trưởng duyệt.
enum RewardStage { pending, sentToPrincipal, returned }

/// Một đề xuất khen thưởng cho một trẻ. "Hợp lệ" và minh chứng là kết quả BE trả theo tiêu chí P-11 (PENDING);
/// APP không tự xét tiêu chí.
@immutable
class RewardProposal {
  const RewardProposal({
    required this.id,
    required this.childName,
    required this.className,
    required this.awardTitle,
    required this.evidence,
    required this.isValid,
    required this.stage,
    this.invalidReason,
  });

  final String id;
  final String childName;
  final String className;

  /// "Bé ngoan toàn diện"
  final String awardTitle;

  /// "10/10 phiếu bé ngoan"
  final String evidence;
  final bool isValid;

  /// "chưa đủ điều kiện"
  final String? invalidReason;
  final RewardStage stage;

  RewardProposal moved(RewardStage value) => RewardProposal(
    id: id,
    childName: childName,
    className: className,
    awardTitle: awardTitle,
    evidence: evidence,
    isValid: isValid,
    invalidReason: invalidReason,
    stage: value,
  );
}

/// Chỉ đọc: PHT xét đề xuất trên Web, App chỉ xem (AUTH-21, BE ADR-0026).
abstract interface class RewardProposalSource {
  /// Năm học đang xét, vd. "2026–2027".
  String get schoolYear;
  Future<List<RewardProposal>> load();
}

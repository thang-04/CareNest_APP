import 'package:flutter/foundation.dart';

/// Mặt đánh giá ngày do BE trả (OBS-02; danh sách cố định hay trường cấu hình: P-11) — APP không có danh sách cứng.
@immutable
class ReviewCriterionDef {
  const ReviewCriterionDef({
    required this.id,
    required this.title,
    required this.options,
    required this.defaultOption,
  });

  final String id;

  /// "Ăn uống"
  final String title;

  /// "Đạt", "Cần cố gắng", "Chưa đạt"
  final List<String> options;

  /// Mức mặc định cho trẻ có mặt (OBS-01: GV chỉ sửa trẻ khác thường).
  final String defaultOption;
}

enum KidReviewState { pending, done, absent }

@immutable
class KidReview {
  const KidReview({
    required this.childId,
    required this.fullName,
    required this.state,
    required this.presenceLine,
    this.answers = const {},
    this.note = '',
    this.flagged = false,
  });

  final String childId;
  final String fullName;
  final KidReviewState state;

  /// "Có mặt 07:42" / "Vắng có phép"
  final String presenceLine;

  /// criterionId → lựa chọn
  final Map<String, String> answers;
  final String note;

  /// Gắn cờ hành vi tốt — phiếu bé ngoan OBS-10 PROPOSED.
  final bool flagged;
}

@immutable
class ReviewDay {
  const ReviewDay({
    required this.date,
    required this.activityLine,
    required this.criteria,
    required this.flagLabel,
    required this.kids,
  });

  final DateTime date;

  /// "Tạo hình: Bé tô màu chiếc lá mùa thu" — ngữ cảnh hoạt động (OBS-07 OPEN), không phải giáo án.
  final String activityLine;
  final List<ReviewCriterionDef> criteria;
  final String flagLabel;
  final List<KidReview> kids;
}

/// Chỉ đọc trên App — BE `GET /classes/{classId}/daily-assessment`; ghi làm trên Web.
abstract interface class DailyReviewSource {
  Future<ReviewDay> loadDay(String classId);
}

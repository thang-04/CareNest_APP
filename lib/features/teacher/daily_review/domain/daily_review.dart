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
    this.comment = '',
    this.attentionNotes = const [],
    this.flagged = false,
    this.healthSigns = const [],
  });

  final String childId;
  final String fullName;
  final KidReviewState state;

  /// "Có mặt 07:42" / "Vắng có phép"
  final String presenceLine;

  /// criterionId → lựa chọn
  final Map<String, String> answers;

  /// Nhận xét riêng về trẻ (`comment` trong DailySheetResponse của BE).
  final String comment;

  /// Các lưu ý quan sát được, ví dụ sức khỏe hoặc hành vi.
  final List<String> attentionNotes;

  /// Cờ bé ngoan trong ngày (BE `flag`).
  final bool flagged;

  /// Biểu hiện sức khỏe BE ghi nhận trong ngày (nhãn); rỗng = bình thường.
  final List<String> healthSigns;
}

@immutable
class ReviewDay {
  const ReviewDay({
    required this.date,
    required this.activityLine,
    required this.criteria,
    required this.flagLabel,
    required this.kids,
    this.classComment = '',
    this.attendanceTaken = true,
    this.locked = false,
    this.yearReadOnly = false,
  });

  final DateTime date;

  /// Lớp đã điểm danh ngày này; chưa ⇒ chưa có trẻ để đánh giá (BE `attendanceTaken`).
  final bool attendanceTaken;

  /// Ngày đã khóa (BE `locked`) / lớp thuộc năm học chỉ xem (BE `yearReadOnly`).
  final bool locked;
  final bool yearReadOnly;

  /// "Tạo hình: Bé tô màu chiếc lá mùa thu" — ngữ cảnh hoạt động (OBS-07 OPEN), không phải giáo án.
  final String activityLine;
  final List<ReviewCriterionDef> criteria;
  final String flagLabel;
  final List<KidReview> kids;

  /// Nhận xét chung của lớp trong ngày (`classComment` của BE).
  final String classComment;
}

/// Kỳ nhận xét App hiển thị: tuần, cuối chủ đề, học kỳ hoặc cuối năm.
enum ReviewPeriodKind { week, theme, semester, yearEnd }

/// Loại chi tiết người dùng đã chọn từ danh sách; màn chi tiết không trộn các loại.
enum ReviewDetailView { day, week, theme, semester, yearEnd }

@immutable
class PeriodReview {
  const PeriodReview({
    required this.childId,
    required this.fullName,
    required this.kind,
    required this.periodLabel,
    required this.summary,
    required this.statusLabel,
    this.attentionNote = '',
    this.goals = const [],
    this.domains = const [],
    this.measurement,
    this.notes = const [],
  });

  final String childId;
  final String fullName;
  final ReviewPeriodKind kind;
  final String periodLabel;

  /// Nội dung nhận xét tuần đã gửi hoặc đánh giá kỳ đã xác nhận.
  final String summary;
  final String statusLabel;
  final String attentionNote;
  final List<ReviewGoalResult> goals;
  final List<ReviewDomainResult> domains;
  final ReviewMeasurement? measurement;
  final List<ReviewLabeledNote> notes;
}

@immutable
class ReviewGoalResult {
  const ReviewGoalResult({
    required this.code,
    required this.title,
    required this.met,
    this.source = '',
  });

  final String code;
  final String title;
  final bool? met;
  final String source;
}

@immutable
class ReviewDomainResult {
  const ReviewDomainResult({
    required this.title,
    required this.goals,
    this.comment = '',
  });

  final String title;
  final List<ReviewGoalResult> goals;
  final String comment;
}

@immutable
class ReviewMeasurement {
  const ReviewMeasurement({
    required this.dateLabel,
    required this.weightKg,
    required this.heightCm,
  });

  final String dateLabel;
  final String weightKg;
  final String heightCm;
}

@immutable
class ReviewLabeledNote {
  const ReviewLabeledNote({required this.label, required this.text});

  final String label;
  final String text;
}

/// Chỉ đọc trên App — BE `GET /classes/{classId}/daily-assessment`; ghi làm trên Web.
abstract interface class DailyReviewSource {
  /// [date] null ⇒ hôm nay (BE bỏ qua tham số `date`).
  Future<ReviewDay> loadDay(String classId, {DateTime? date});

  /// BE: nhận xét tuần và các đợt đánh giá định kỳ; APP chỉ xem.
  Future<List<PeriodReview>> loadPeriods(String classId);
}

import 'package:carenest_app/features/parent/school_year/domain/child_school_year.dart';
import 'package:flutter/foundation.dart';

/// Bữa trong ngày theo nhóm tuổi (BE `MealSession`).
enum MealSession { morning, lunch, afternoon }

/// Mức ăn một bữa (BE `EatingLevel`: AN_HET, AN_IT, KHONG_AN).
enum EatingLevel { finished, little, none }

/// Ngủ trưa (BE `NapLevel`: NGU_TOT, NGU_IT, KHONG_NGU).
enum NapLevel { good, little, none }

/// Cảm xúc trong ngày (BE `Emotion`).
enum Emotion { happy, calm, sad, upset }

/// Hành vi cô tích (BE `ObservedBehavior`); không tích = bình thường.
enum ObservedBehavior {
  cooperative,
  helpful,
  uncooperative,
  grabbing,
  unfocused,
  shy,
  other,
}

/// Mức tham gia hoạt động cả ngày (BE `Participation`).
enum Participation { active, normal, passive }

/// Biểu hiện sức khỏe trong ngày (BE `HealthSymptom`); rỗng = bình thường.
enum HealthSign { fever, cough, runnyNose, flu, tired, other }

/// Một mục tiêu (MT) và kết quả: chỉ Đạt / Chưa đạt (FE bỏ "Cần cố gắng" từ 04/11).
@immutable
class GoalResult {
  const GoalResult(
    this.text, {
    required this.met,
    this.activity,
    this.themesMet,
    this.themesAssessed,
  });

  final String text;
  final bool met;

  /// Đánh giá ngày: hoạt động của giáo án có MT này ("Hoạt động học · Làm quen chữ p, q").
  final String? activity;

  /// Học kỳ: số chủ đề MT đạt / số chủ đề có kết quả (BE `metActivities`, `assessedActivities`).
  final int? themesMet;
  final int? themesAssessed;
}

/// Ngày có đánh giá, bé vắng (không đánh giá — OBS-01) hoặc cô chưa lưu.
enum DayStatus { evaluated, absent, notRecorded }

/// Đánh giá một ngày của trẻ (OBS-02, OBS-13): chỉ hiện sau khi cô lưu.
@immutable
class DayEvaluation {
  const DayEvaluation({
    required this.date,
    this.status = DayStatus.evaluated,
    this.teacherName,
    this.savedAt,
    this.flagged = false,
    this.healthSigns = const [],
    this.meals = const {},
    this.nap,
    this.emotion,
    this.behaviors = const [],
    this.participation,
    this.goals = const [],
    this.comment,
  });

  final DateTime date;
  final DayStatus status;
  final String? teacherName;
  final DateTime? savedAt;

  /// Cờ bé ngoan trong ngày (OBS-10).
  final bool flagged;
  final List<HealthSign> healthSigns;
  final Map<MealSession, EatingLevel> meals;
  final NapLevel? nap;
  final Emotion? emotion;
  final List<ObservedBehavior> behaviors;
  final Participation? participation;
  final List<GoalResult> goals;
  final String? comment;
}

/// Một tuần học theo giáo án tuần (tên tuần do BE trả), các ngày từ thứ Hai.
@immutable
class EvaluationWeek {
  const EvaluationWeek({
    required this.label,
    required this.from,
    required this.to,
    required this.days,
  });

  /// "Tuần 35"
  final String label;
  final DateTime from;
  final DateTime to;
  final List<DayEvaluation> days;
}

/// Nhận xét tuần cô đã gửi phụ huynh (OBS-29, BE `ParentWeeklyCommentResponse`).
@immutable
class WeeklyComment {
  const WeeklyComment({
    required this.weekLabel,
    required this.from,
    required this.to,
    required this.paragraphs,
    required this.teacherName,
    required this.sentAt,
  });

  final String weekLabel;
  final DateTime from;
  final DateTime to;
  final List<String> paragraphs;
  final String teacherName;
  final DateTime sentAt;
}

/// Kỳ đánh giá: chưa có kết quả cho phụ huynh hoặc cô đã xác nhận (PAR-03).
enum PeriodStatus { pending, confirmed }

/// Kết quả cuối chủ đề của trẻ (OBS-27): số MT đạt / tổng, đạt chủ đề do BE tính.
@immutable
class ThemeResult {
  const ThemeResult({
    required this.id,
    required this.name,
    required this.semester,
    required this.from,
    required this.to,
    this.status = PeriodStatus.confirmed,
    this.metGoals = 0,
    this.totalGoals = 0,
    this.passed,
    this.passPercent = 70,
    this.goals = const [],
    this.confirmedBy,
    this.confirmedAt,
    this.className,
  });

  final String id;
  final String name;

  /// Lớp của bé khi học chủ đề (BE `className`); null ⇒ màn dùng lớp hiện tại.
  final String? className;

  /// 1 hoặc 2; BE phụ huynh chưa trả ⇒ null, màn không chia theo học kỳ.
  final int? semester;
  final DateTime from;
  final DateTime to;
  final PeriodStatus status;
  final int metGoals;
  final int totalGoals;

  /// Đạt chủ đề do BE tính; BE phụ huynh chưa trả ⇒ null, màn không hiện dấu đạt.
  final bool? passed;

  /// Ngưỡng đạt chủ đề BE trả (`passPercent`); null ⇒ màn ẩn câu ngưỡng.
  final int? passPercent;
  final List<GoalResult> goals;
  final String? confirmedBy;
  final DateTime? confirmedAt;
}

/// Một lĩnh vực phát triển ở học kỳ hoặc phiếu cuối năm.
@immutable
class DomainResult {
  const DomainResult({
    required this.name,
    required this.metGoals,
    required this.totalGoals,
    required this.goals,
    this.met,
    this.comment,
  });

  final String name;

  /// Số MT đạt / tổng của lĩnh vực; BE phụ huynh chưa trả ⇒ null, màn ẩn (không tự đếm).
  final int? metGoals;
  final int? totalGoals;
  final List<GoalResult> goals;

  /// Học kỳ: lĩnh vực Đạt / Chưa đạt; phiếu cuối năm không có (null).
  final bool? met;

  /// Phiếu cuối năm: nhận xét của cô dưới lĩnh vực.
  final String? comment;
}

/// Đánh giá học kỳ của trẻ (OBS-06) theo lĩnh vực.
@immutable
class SemesterResult {
  const SemesterResult({
    required this.semester,
    required this.schoolYear,
    required this.from,
    required this.to,
    this.status = PeriodStatus.confirmed,
    this.domainsMet = 0,
    this.domainsTotal = 0,
    this.domains = const [],
    this.confirmedBy,
    this.confirmedAt,
  });

  /// 1 hoặc 2
  final int semester;

  /// "2026–2027"; BE phụ huynh chưa trả tên năm học ⇒ null.
  final String? schoolYear;
  final DateTime from;
  final DateTime to;
  final PeriodStatus status;

  /// Số lĩnh vực đạt / tổng; BE phụ huynh chưa trả ⇒ null, màn ẩn.
  final int? domainsMet;
  final int? domainsTotal;
  final List<DomainResult> domains;
  final String? confirmedBy;
  final DateTime? confirmedAt;
}

/// Phiếu đánh giá sự phát triển cuối năm (OBS-28); cân đo của phiếu (BE `SheetMeasurement`)
/// không hiện cho phụ huynh ở đây — số đo xem ở Sổ sức khỏe (user 18/11).
@immutable
class YearEndResult {
  const YearEndResult({
    required this.schoolYear,
    required this.ageGroup,
    this.status = PeriodStatus.confirmed,
    this.metGoals = 0,
    this.totalGoals = 0,
    this.programCompleted,
    this.teacherComment,
    this.teacherName,
    this.commentedAt,
    this.noteForParent,
    this.domains = const [],
    this.confirmedBy,
    this.confirmedAt,
  });

  /// BE phụ huynh chưa trả tên năm học, nhóm tuổi ⇒ null, màn ẩn.
  final String? schoolYear;

  /// "Nhóm 5–6 tuổi"
  final String? ageGroup;
  final PeriodStatus status;
  final int metGoals;
  final int totalGoals;

  /// Chỉ lớp 5–6 tuổi: hoàn thành chương trình giáo dục mầm non; lớp khác null.
  final bool? programCompleted;
  final String? teacherComment;
  final String? teacherName;
  final DateTime? commentedAt;

  /// Chỉ "Lưu ý cho cha mẹ" (user 18/11); 3 lưu ý còn lại không hiện cho phụ huynh.
  final String? noteForParent;
  final List<DomainResult> domains;
  final String? confirmedBy;
  final DateTime? confirmedAt;
}

/// Mọi đánh giá của trẻ trong năm học đang xem; tuần, chủ đề, học kỳ mới nhất trước.
@immutable
class EvaluationBook {
  const EvaluationBook({
    this.weeks = const [],
    this.weeklyComments = const [],
    this.themes = const [],
    this.semesters = const [],
    this.yearEnd,
  });

  final List<EvaluationWeek> weeks;
  final List<WeeklyComment> weeklyComments;
  final List<ThemeResult> themes;
  final List<SemesterResult> semesters;
  final YearEndResult? yearEnd;

  ThemeResult? themeById(String id) =>
      themes.where((theme) => theme.id == id).firstOrNull;
}

/// Nguồn dữ liệu trang Đánh giá; BE mới có API nhận xét tuần cho phụ huynh.
abstract interface class EvaluationSource {
  Future<EvaluationBook> load(String childId, {ChildSchoolYear? year});
}

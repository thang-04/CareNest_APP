import 'package:flutter/foundation.dart';

/// Sổ sức khỏe của một bé (user 17/11, canvas "Sổ sức khỏe"). BE dự kiến một API
/// `GET /children/{childId}/health/published`: kỳ cân đo = kết quả MEASUREMENT, đợt khám = kết quả
/// EXAM đã kết luận, xu hướng = các lần đo + nhận định đã duyệt. Chưa nối: App dùng dữ liệu giả.

/// Mức BMI theo tuổi theo chuẩn WHO, BE tính (HLT-18, PROPOSED). App không tự tính.
enum BmiLevel {
  severeThinness,
  thinness,
  normal,
  overweightRisk,
  overweight,
  obese,
}

/// Mức theo dõi theo kết luận của bác sĩ (HLT-10).
enum FollowUpLevel { none, knownStable, watch, closeWatch }

/// Một kỳ cân đo cô giáo ghi trên lớp; lưu là công bố (HLT-11).
@immutable
class MeasurementRound {
  const MeasurementRound({
    required this.id,
    required this.name,
    required this.date,
    required this.ageMonths,
    required this.heightCm,
    required this.weightKg,
    required this.bmi,
    this.bmiLevel,
    this.note,
  });

  final String id;

  /// "Cân đo định kỳ tháng 10/2026"
  final String name;
  final DateTime date;
  final int ageMonths;
  final double heightCm;
  final double weightKg;
  final double bmi;

  /// null ⇒ "Không xếp mức"
  final BmiLevel? bmiLevel;

  /// Ghi chú của cô khi đo
  final String? note;
}

/// Một dòng của phiếu khám (Phụ lục II): nhãn và lựa chọn đã ghi; [abnormal] ⇒ hiện nổi.
@immutable
class ExamItem {
  const ExamItem(this.label, this.value, {this.abnormal = false});

  final String label;
  final String value;
  final bool abnormal;
}

/// Một nhóm mục khám lâm sàng, vd. "2.5. Khám miệng, răng".
@immutable
class ExamSection {
  const ExamSection(this.title, this.items);

  final String title;
  final List<ExamItem> items;
}

/// Dấu hiệu sinh tồn (phần II): "Nhiệt độ", "36,7", "°C", "Bình thường".
@immutable
class ExamVital {
  const ExamVital({
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    this.abnormal = false,
  });

  final String label;
  final String value;
  final String unit;
  final String status;
  final bool abnormal;
}

/// Một đợt khám sức khỏe đã có kết luận: bác sĩ khám tại trường, giáo viên nhập phiếu (HLT-08).
/// Phụ huynh xem đủ phiếu theo yêu cầu user 17/11; API phụ huynh hiện chỉ trả phần kết luận ⇒ các mục
/// khác rỗng, màn chỉ hiện mục có dữ liệu.
@immutable
class HealthExam {
  const HealthExam({
    required this.id,
    required this.name,
    required this.date,
    required this.ageMonths,
    required this.examiner,
    required this.doctorName,
    required this.followUp,
    required this.conclusion,
    required this.action,
    required this.nutritionStatus,
    this.issueText,
    this.issueKind,
    this.advice,
    this.parentOpinion,
    this.history = const [],
    this.vitals = const [],
    this.nutrition = const [],
    this.development = const [],
    this.immunization = const [],
    this.clinical = const [],
  });

  final String id;

  /// "Khám sức khỏe đầu năm học 2026-2027"
  final String name;
  final DateTime date;
  final int ageMonths;

  /// Đơn vị khám, vd. "Trạm Y tế xã Thượng Hồng"; API phụ huynh chưa trả ⇒ null, màn ẩn.
  final String? examiner;

  /// "BS. Nguyễn Thị Hằng"; bác sĩ không ghi tên ⇒ null.
  final String? doctorName;
  final FollowUpLevel followUp;

  /// "Bình thường" | "Có vấn đề về sức khỏe" | "Có nguy cơ mắc lao (tiền sử tiếp xúc)"
  final String conclusion;

  /// "Không cần tư vấn hay chuyển khám" | "Tư vấn" | "Chuyển khám chuyên khoa: Mắt"; null ⇒ màn ẩn.
  final String? action;

  /// Tình trạng dinh dưỡng bác sĩ chọn, vd. "Bình thường"; API phụ huynh chưa trả ⇒ null, màn ẩn.
  final String? nutritionStatus;

  /// Vấn đề bác sĩ ghi, vd. "Sâu răng"
  final String? issueText;

  /// "Vấn đề mới hoặc có thay đổi" | "Vấn đề đã biết, không thay đổi so với trước"
  final String? issueKind;

  /// Lời dặn của bác sĩ
  final String? advice;

  /// Ý kiến phụ huynh ghi trên phiếu (user 25/11: phụ huynh xem được).
  final String? parentOpinion;
  final List<ExamItem> history;
  final List<ExamVital> vitals;
  final List<ExamItem> nutrition;
  final List<ExamItem> development;
  final List<ExamItem> immunization;
  final List<ExamSection> clinical;
}

/// Một lần đo trên biểu đồ (cân đo hoặc đợt khám), cũ trước mới sau.
@immutable
class GrowthPoint {
  const GrowthPoint({
    required this.date,
    required this.heightCm,
    required this.weightKg,
    this.fromExam = false,
  });

  final DateTime date;
  final double heightCm;
  final double weightKg;

  /// Số đo lấy từ đợt khám (chấm rỗng trên biểu đồ)
  final bool fromExam;
}

/// Nhận định xu hướng AI soạn, giáo viên chủ nhiệm đã duyệt (HLT-04, HLT-05, HLT-21).
/// Phụ huynh không thấy bản nháp và mục "Gợi ý theo dõi".
@immutable
class TrendInterpretation {
  const TrendInterpretation({
    required this.periodLabel,
    required this.approvedOn,
    required this.overview,
    this.attention = const [],
    this.positives = const [],
    this.limitations,
    this.stale = false,
  });

  /// "Phân tích 6 tháng"
  final String periodLabel;
  final DateTime approvedOn;
  final String overview;
  final List<String> attention;
  final List<String> positives;
  final String? limitations;

  /// Đã có số đo mới sau lần duyệt
  final bool stale;
}

@immutable
class HealthBook {
  const HealthBook({
    required this.rounds,
    required this.exams,
    required this.growth,
    this.interpretation,
  });

  /// Mới trước cũ sau
  final List<MeasurementRound> rounds;

  /// Mới trước cũ sau
  final List<HealthExam> exams;

  /// Cũ trước mới sau
  final List<GrowthPoint> growth;
  final TrendInterpretation? interpretation;
}

abstract class HealthBookSource {
  const HealthBookSource();

  Future<HealthBook> load(String childId);

  /// Phiếu khám đầy đủ của một đợt (màn chi tiết); null ⇒ không có hoặc chưa kết luận.
  Future<HealthExam?> loadExam(String childId, String examId) async =>
      (await load(
        childId,
      )).exams.where((exam) => exam.id == examId).firstOrNull;
}

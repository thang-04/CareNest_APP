import 'package:flutter/foundation.dart';

/// Kết quả GV quan sát khi nhận trẻ — khớp enum BE `HealthObservation`; hệ thống không tự suy từ thân nhiệt.
enum HealthObservation {
  noConcern('NO_CONCERN', 'Bình thường'),
  noted('NOTED', 'Có dấu hiệu');

  const HealthObservation(this.code, this.label);
  final String code;
  final String label;
}

/// Biểu hiện GV chọn — khớp enum BE `HealthSymptom` (danh sách triệu chứng P-21 còn chờ chốt).
enum HealthSymptom {
  fever('FEVER', 'Sốt'),
  cough('COUGH', 'Ho'),
  runnyNose('RUNNY_NOSE', 'Sổ mũi'),
  flu('FLU', 'Cảm cúm'),
  tired('TIRED', 'Mệt mỏi'),
  other('OTHER', 'Khác');

  const HealthSymptom(this.code, this.label);
  final String code;
  final String label;
}

/// Việc GV đã làm — khớp enum BE `HealthAction`; không phải chẩn đoán (HLT-14).
enum HealthAction {
  monitor('MONITOR', 'Theo dõi tại lớp'),
  medicalRoom('MEDICAL_ROOM', 'Đưa phòng y tế'),
  parentInformed('PARENT_INFORMED', 'Đã gọi điện cho phụ huynh'),
  earlyPickup('EARLY_PICKUP', 'Báo phụ huynh đón về sớm'),
  referral('REFERRAL', 'Chuyển cơ sở y tế / cấp cứu');

  const HealthAction(this.code, this.label);
  final String code;
  final String label;
}

/// Chuyển cơ sở y tế — BE `DailyHealthRequest.Referral`: nơi ≤150, giờ HH:mm, người đi kèm ≤100.
@immutable
class HealthReferral {
  const HealthReferral({this.place, this.time, this.escort});

  final String? place;

  /// "HH:mm"
  final String? time;
  final String? escort;
}

/// Một lần ghi — khớp BE `DailyHealthRequest` / `DailyHealthEntryResponse`.
@immutable
class DailyHealthEntry {
  const DailyHealthEntry({
    required this.requestId,
    required this.classId,
    required this.childId,
    required this.date,
    required this.observation,
    this.temperature,
    this.symptoms = const [],
    this.actions = const [],
    this.note,
    this.referral,
    this.recordedAt,
    this.recordedByName,
  });

  /// APP sinh mỗi lần bấm lưu; gửi lặp BE trả lại bản đã lưu (idempotent).
  final String requestId;
  final String classId;
  final String childId;
  final DateTime date;
  final HealthObservation observation;

  /// °C, tùy chọn, 20,0–45,0, tối đa 1 số lẻ (BE kiểm tra lại).
  final double? temperature;
  final List<HealthSymptom> symptoms;
  final List<HealthAction> actions;

  /// ≤500 ký tự.
  final String? note;
  final HealthReferral? referral;
  final DateTime? recordedAt;

  /// Người ghi — BE `recordedByName`.
  final String? recordedByName;
}

/// Một bé có mặt trong màn Sức khỏe đầu ngày — từ BE `ClassAttendanceResponse.ChildRow`
/// (`child` + `health` HealthSummary); [latest] là lần ghi gần nhất nếu đã kiểm tra.
@immutable
class DailyHealthKid {
  const DailyHealthKid({
    required this.childId,
    required this.fullName,
    this.latest,
    this.entryCount = 0,
    this.handedOverAt,
    this.code,
  });

  final String childId;
  final String fullName;
  final DailyHealthEntry? latest;
  final int entryCount;

  /// BE `DailyHealthResponse.ChildDay.handedOverAt` — đã trả trẻ thì không ghi thêm (HEALTH_CHILD_PICKED_UP).
  final DateTime? handedOverAt;

  /// Mã trẻ nếu BE trả.
  final String? code;

  bool get checked => latest != null;
  bool get pickedUp => handedOverAt != null;
}

@immutable
class DailyHealthSheet {
  const DailyHealthSheet({
    required this.classId,
    required this.className,
    required this.date,
    required this.canRecord,
    required this.kids,
    this.schoolDay = true,
  });

  final String classId;
  final String className;
  final DateTime date;

  /// BE quyết định GV còn được ghi hay không (quyền DAILY_HEALTH_RECORD, ngày đã qua).
  final bool canRecord;

  /// Chỉ bé có mặt (ATT: PRESENT).
  final List<DailyHealthKid> kids;

  /// BE `DayInfoResponse.schoolDay`.
  final bool schoolDay;
}

/// Các lần ghi trong ngày của một trẻ, mới nhất trước — BE `DailyHealthResponse.ChildDay`.
@immutable
class DailyHealthChildDay {
  const DailyHealthChildDay({
    required this.entries,
    required this.canRecord,
    this.handedOverAt,
  });

  final List<DailyHealthEntry> entries;

  /// BE: GV lớp, hôm nay, trẻ đã lưu Có mặt.
  final bool canRecord;
  final DateTime? handedOverAt;
}

abstract interface class DailyHealthSource {
  /// [date] null = hôm nay do BE chọn.
  Future<DailyHealthSheet> loadSheet(String classId, {DateTime? date});

  /// BE: `GET /classes/{classId}/children/{childId}/daily-health[?date=]` — lịch sử trong ngày.
  Future<DailyHealthChildDay> loadChildDay(
    String classId,
    String childId, {
    DateTime? date,
  });

  /// BE: `POST /daily-health-entries`.
  Future<DailyHealthEntry> save(DailyHealthEntry entry);
}

import 'package:carenest_app/features/attendance/domain/arrival_health.dart';

/// Nhãn giống Web (`DailyHealthPanel.jsx`, `dailyHealthValidation.js`).
extension HealthObservationLabel on HealthObservation {
  String get label => switch (this) {
    HealthObservation.noConcern => 'Không ghi nhận bất thường',
    HealthObservation.noted => 'Có dấu hiệu cần lưu ý',
  };
}

extension HealthSymptomLabel on HealthSymptom {
  String get label => switch (this) {
    HealthSymptom.fever => 'Sốt',
    HealthSymptom.cough => 'Ho',
    HealthSymptom.runnyNose => 'Sổ mũi',
    HealthSymptom.flu => 'Cảm cúm',
    HealthSymptom.tired => 'Mệt mỏi',
    HealthSymptom.other => 'Khác',
  };
}

extension HealthActionLabel on HealthAction {
  String get label => switch (this) {
    HealthAction.monitor => 'Theo dõi tại lớp',
    HealthAction.medicalRoom => 'Đưa phòng y tế',
    HealthAction.parentInformed => 'Đã gọi điện cho phụ huynh',
    HealthAction.earlyPickup => 'Báo phụ huynh đón về sớm',
    HealthAction.referral => 'Chuyển cơ sở y tế / cấp cứu',
  };
}

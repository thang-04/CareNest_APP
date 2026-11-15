import 'package:flutter/foundation.dart';

/// Quan sát sức khỏe đầu ngày (HLT-07); khớp BE `HealthObservation`.
enum HealthObservation { noConcern, noted }

/// Biểu hiện chọn nhanh — danh sách BE `HealthSymptom` (HLT-07, đóng P-21).
enum HealthSymptom { fever, cough, runnyNose, flu, tired, other }

/// Việc GV đã làm khi trẻ có dấu hiệu cần lưu ý — BE `HealthAction`. Trẻ vẫn được nhận (P-22).
enum HealthAction {
  monitor,
  medicalRoom,
  parentInformed,
  earlyPickup,
  referral,
}

/// Chuyển cơ sở y tế: nơi đến và giờ bắt buộc, người đi kèm tùy chọn (như Web).
@immutable
class HealthReferral {
  const HealthReferral({this.place = '', this.time = '', this.escort = ''});

  final String place;

  /// "hh:mm"
  final String time;
  final String escort;

  HealthReferral copyWith({String? place, String? time, String? escort}) =>
      HealthReferral(
        place: place ?? this.place,
        time: time ?? this.time,
        escort: escort ?? this.escort,
      );
}

/// Kiểm tra sức khỏe đầu ngày của một bé có mặt (HLT-07): quan sát bắt buộc, thân nhiệt tùy chọn.
@immutable
class ArrivalHealth {
  const ArrivalHealth({
    this.observation,
    this.temperature,
    this.symptoms = const {},
    this.actions = const {},
    this.note = '',
    this.referral = const HealthReferral(),
  });

  /// Thân nhiệt BE nhận (`DailyHealthRequest`), °C.
  static const minTemperature = 20.0;
  static const maxTemperature = 45.0;
  static const maxNoteLength = 500;

  final HealthObservation? observation;
  final double? temperature;
  final Set<HealthSymptom> symptoms;
  final Set<HealthAction> actions;
  final String note;
  final HealthReferral referral;

  /// Chưa nhập gì ⇒ chưa kiểm tra, không gửi bản ghi sức khỏe.
  bool get isBlank =>
      observation == null &&
      temperature == null &&
      symptoms.isEmpty &&
      actions.isEmpty &&
      note.trim().isEmpty;

  bool get isNoted => observation == HealthObservation.noted;

  ArrivalHealth copyWith({
    HealthObservation? observation,
    double? Function()? temperature,
    Set<HealthSymptom>? symptoms,
    Set<HealthAction>? actions,
    String? note,
    HealthReferral? referral,
  }) {
    return ArrivalHealth(
      observation: observation ?? this.observation,
      temperature: temperature != null ? temperature() : this.temperature,
      symptoms: symptoms ?? this.symptoms,
      actions: actions ?? this.actions,
      note: note ?? this.note,
      referral: referral ?? this.referral,
    );
  }

  /// Chọn quan sát; "không ghi nhận bất thường" bỏ biểu hiện, xử trí đã chọn (chỉ ghi khi có dấu hiệu).
  ArrivalHealth withObservation(HealthObservation value) {
    if (value == HealthObservation.noted) {
      return copyWith(observation: value);
    }
    return ArrivalHealth(
      observation: value,
      temperature: temperature,
      note: note,
    );
  }
}

/// Ô bị lỗi khi kiểm tra trước khi lưu.
enum ArrivalHealthField { temperature, observation, note, referral }

/// Kiểm tra hỗ trợ nhập như Web (`dailyHealthValidation.js`); BE vẫn kiểm tra lại.
Map<ArrivalHealthField, String> validateArrivalHealth(ArrivalHealth health) {
  final errors = <ArrivalHealthField, String>{};
  if (health.isBlank) return errors;
  final temperature = health.temperature;
  if (temperature != null &&
      (temperature < ArrivalHealth.minTemperature ||
          temperature > ArrivalHealth.maxTemperature)) {
    errors[ArrivalHealthField.temperature] =
        'Thân nhiệt phải từ 20,0 đến 45,0 °C';
  }
  if (health.observation == null) {
    errors[ArrivalHealthField.observation] =
        'Chọn kết quả quan sát sau khi kiểm tra trẻ';
  }
  if (health.isNoted && health.symptoms.isEmpty && health.note.trim().isEmpty) {
    errors[ArrivalHealthField.note] = 'Ghi biểu hiện hoặc ghi chú cần lưu ý';
  } else if (health.note.length > ArrivalHealth.maxNoteLength) {
    errors[ArrivalHealthField.note] = 'Ghi chú tối đa 500 ký tự';
  }
  if (health.actions.contains(HealthAction.referral)) {
    if (health.referral.place.trim().isEmpty) {
      errors[ArrivalHealthField.referral] = 'Nhập nơi chuyển trẻ đến';
    } else if (!RegExp(
      r'^([01]\d|2[0-3]):[0-5]\d$',
    ).hasMatch(health.referral.time)) {
      errors[ArrivalHealthField.referral] = 'Nhập giờ chuyển theo hh:mm';
    }
  }
  return errors;
}

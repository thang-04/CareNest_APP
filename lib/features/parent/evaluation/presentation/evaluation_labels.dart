import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/features/parent/evaluation/domain/evaluation.dart';

/// Nhãn trang Đánh giá, cùng chữ với web (FE `dailyObservationOptions.js`, `assessmentConstants.js`).
/// Mặt "cần chú ý" tô cam như ô khác thường ở bảng đánh giá ngày của web.
abstract final class EvaluationLabels {
  static String meal(MealSession session) => switch (session) {
    MealSession.morning => 'Bữa sáng',
    MealSession.lunch => 'Bữa trưa',
    MealSession.afternoon => 'Bữa chiều',
  };

  static String eating(EatingLevel level) => switch (level) {
    EatingLevel.finished => 'Ăn hết',
    EatingLevel.little => 'Ăn ít',
    EatingLevel.none => 'Không ăn',
  };

  static String nap(NapLevel level) => switch (level) {
    NapLevel.good => 'Ngủ tốt',
    NapLevel.little => 'Ngủ ít',
    NapLevel.none => 'Không ngủ',
  };

  static String emotion(Emotion emotion) => switch (emotion) {
    Emotion.happy => 'Vui vẻ',
    Emotion.calm => 'Bình thường',
    Emotion.sad => 'Buồn',
    Emotion.upset => 'Quấy khóc',
  };

  static String behavior(ObservedBehavior behavior) => switch (behavior) {
    ObservedBehavior.cooperative => 'Hợp tác tốt',
    ObservedBehavior.helpful => 'Giúp đỡ bạn',
    ObservedBehavior.uncooperative => 'Chưa hợp tác',
    ObservedBehavior.grabbing => 'Tranh giành / đánh bạn',
    ObservedBehavior.unfocused => 'Không tập trung',
    ObservedBehavior.shy => 'Rụt rè',
    ObservedBehavior.other => 'Khác',
  };

  static String participation(Participation value) => switch (value) {
    Participation.active => 'Tích cực',
    Participation.normal => 'Bình thường',
    Participation.passive => 'Chưa tích cực',
  };

  static String healthSign(HealthSign sign) => switch (sign) {
    HealthSign.fever => 'Sốt',
    HealthSign.cough => 'Ho',
    HealthSign.runnyNose => 'Sổ mũi',
    HealthSign.flu => 'Cúm',
    HealthSign.tired => 'Mệt',
    HealthSign.other => 'Khác',
  };

  static bool eatingNeedsAttention(EatingLevel level) =>
      level != EatingLevel.finished;

  static bool napNeedsAttention(NapLevel level) => level != NapLevel.good;

  static bool emotionNeedsAttention(Emotion emotion) =>
      emotion == Emotion.sad || emotion == Emotion.upset;

  /// Chỉ "Hợp tác tốt", "Giúp đỡ bạn" là hành vi tích cực (FE `POSITIVE_BEHAVIORS`).
  static bool behaviorNeedsAttention(ObservedBehavior behavior) =>
      behavior != ObservedBehavior.cooperative &&
      behavior != ObservedBehavior.helpful;

  static String semester(int semester) =>
      semester == 1 ? 'Học kỳ I' : 'Học kỳ II';

  /// "Tuần 35 · 24/05 – 28/05/2027"
  static String week(String label, DateTime from, DateTime to) =>
      '$label · ${DateLabels.range(from, to)}';

  /// Số kiểu Việt Nam, tối đa 1 chữ số thập phân: 107.5 ⇒ "107,5", 18.0 ⇒ "18".
  static String number(double value) => value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1).replaceAll('.', ',');
}

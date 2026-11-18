import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/features/parent/health_book/domain/health_book.dart';

/// Nhãn và tông của Sổ sức khỏe, cùng chữ với web (FE `childrenConstants.js`).
abstract final class HealthLabels {
  /// Số kiểu Việt Nam, tối đa 1 chữ số thập phân: 104 ⇒ "104", 17.2 ⇒ "17,2".
  static String number(double value) => value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1).replaceAll('.', ',');

  /// Dưới 36 tháng ghi "N tháng", từ đó ghi "X tuổi Y tháng" như web.
  static String age(int months) {
    if (months < 36) return '$months tháng';
    final years = months ~/ 12;
    final rest = months % 12;
    return rest == 0 ? '$years tuổi' : '$years tuổi $rest tháng';
  }

  static (String, AppStatusTone) bmiLevel(BmiLevel? level) => switch (level) {
    null => ('Không xếp mức', AppStatusTone.gray),
    BmiLevel.severeThinness => ('Gầy còm nặng', AppStatusTone.red),
    BmiLevel.thinness => ('Gầy còm', AppStatusTone.orange),
    BmiLevel.normal => ('Bình thường', AppStatusTone.green),
    BmiLevel.overweightRisk => ('Nguy cơ thừa cân', AppStatusTone.orange),
    BmiLevel.overweight => ('Thừa cân', AppStatusTone.orange),
    BmiLevel.obese => ('Béo phì', AppStatusTone.red),
  };

  static (String, AppStatusTone) followUp(FollowUpLevel level) =>
      switch (level) {
        FollowUpLevel.none => (
          'Không ghi nhận bất thường',
          AppStatusTone.green,
        ),
        FollowUpLevel.knownStable => (
          'Vấn đề đã biết, ổn định',
          AppStatusTone.teal,
        ),
        FollowUpLevel.watch => ('Cần theo dõi', AppStatusTone.orange),
        FollowUpLevel.closeWatch => ('Cần theo dõi sát', AppStatusTone.red),
      };
}

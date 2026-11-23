import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/features/kitchen/food_samples/domain/food_samples.dart';

/// Nhãn và tông của Sổ lưu mẫu; nhãn trạng thái như web (`CareNest_FE` kitchenRecordConstants).
abstract final class FoodSamplesStatus {
  static (String, AppStatusTone) sample(SampleStatus status) =>
      switch (status) {
        SampleStatus.recorded => ('Chờ duyệt lưu mẫu', AppStatusTone.approval),
        SampleStatus.approved => ('Đã duyệt lưu mẫu', AppStatusTone.green),
      };

  static (String, AppStatusTone) disposal(SampleDisposalStatus status) =>
      switch (status) {
        SampleDisposalStatus.none => ('Chưa ghi hủy', AppStatusTone.gray),
        SampleDisposalStatus.recorded => (
          'Chờ duyệt hủy mẫu',
          AppStatusTone.approval,
        ),
        SampleDisposalStatus.approved => (
          'Đã duyệt hủy mẫu',
          AppStatusTone.green,
        ),
      };

  static const notRecorded = ('Chưa ghi', AppStatusTone.orange);
  static const upcoming = ('Chưa tới bữa', AppStatusTone.gray);
  static const notYetDisposable = ('Chưa tới giờ hủy', AppStatusTone.gray);

  /// Đã đủ 24 giờ, bếp ghi hủy được (khớp việc "Đến hạn" ở Trang chủ bếp)
  static const disposalDue = ('Đến hạn hủy', AppStatusTone.blue);

  /// "Cháo thịt băm cà rốt · Nhà trẻ"
  static String dishName(SampleDish dish) =>
      [dish.name, ?dish.blockLabel].join(' · ');

  /// "150 ml · Hộp inox có nắp · 0–5 °C"; null khi món chưa có ghi chú
  static String? dishNote(SampleDish dish) {
    if (!dish.hasNote) return null;
    final temperature =
        dish.temperature.isEmpty || dish.temperature.contains('°')
        ? dish.temperature
        : '${dish.temperature} °C';
    return [
      dish.weight,
      dish.container,
      temperature,
    ].where((part) => part.isNotEmpty).join(' · ');
  }

  /// "Lấy mẫu 08:05 · 1 món"
  static String sampled(FoodSample sample) =>
      'Lấy mẫu ${DateLabels.time24(sample.sampledAt)} · ${sample.dishes.length} món';

  /// "Bữa trưa 11/10"
  static String pastTitle(FoodSample sample) =>
      '${sample.sessionLabel} ${DateLabels.dayMonth(sample.date)}';

  /// "Lấy mẫu 10:40 ngày 11/10 · hủy được từ 10:40 ngày 12/10"
  static String disposalWindow(FoodSample sample) =>
      'Lấy mẫu ${_moment(sample.sampledAt)} · hủy được từ ${_moment(sample.disposableFrom)}';

  static String _moment(DateTime value) =>
      '${DateLabels.time24(value)} ngày ${DateLabels.dayMonth(value)}';
}

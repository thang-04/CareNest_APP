import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/features/kitchen/food_samples/domain/food_samples.dart';
import 'package:carenest_app/features/kitchen/kitchen_home/domain/kitchen_today.dart';
import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';

/// "Việc hôm nay" ở Trang chủ bếp ghép từ ảnh mẫu và sổ lưu mẫu BE trả (BE không có API việc;
/// user 25/11: chỉ đếm, không tính số liệu nghiệp vụ).
List<KitchenTask> kitchenTasks(KitchenPhotoDay photos, FoodSampleDay samples) =>
    [
      ?KitchenTasks._photoTask(photos),
      ?KitchenTasks._sampleTask(samples),
      ?KitchenTasks._disposalTask(samples),
    ];

abstract final class KitchenTasks {
  static String _lower(String label) => label.toLowerCase();

  /// "bữa trưa và bữa chiều"
  static String _join(List<String> parts) => parts.length < 2
      ? parts.join()
      : '${parts.take(parts.length - 1).join(', ')} và ${parts.last}';

  static KitchenTask? _photoTask(KitchenPhotoDay day) {
    final meals = day.meals;
    if (day.isDayOff || meals.isEmpty) return null;
    final done = meals.where((m) => m.status == MealPhotoStatus.done).length;
    final progress = '$done/${meals.length} bữa có ảnh';
    // Bữa đang trong giờ mà chưa có ảnh: "bữa trưa cần chụp"
    final needed = [
      for (final meal in meals)
        if (meal.status == MealPhotoStatus.needed) _lower(meal.name),
    ];
    final missed = meals
        .where((m) => m.status == MealPhotoStatus.missed)
        .length;
    final (badge, level, detail) = needed.isNotEmpty
        ? ('Cần chụp', KitchenTaskLevel.todo, '${_join(needed)} cần chụp')
        : missed > 0
        ? ('Thiếu ảnh', KitchenTaskLevel.missed, '$missed bữa quá giờ')
        : done == meals.length
        ? ('Đủ ảnh', KitchenTaskLevel.done, null)
        : ('Chưa tới giờ', KitchenTaskLevel.later, null);
    return KitchenTask(
      kind: KitchenTaskKind.mealPhotos,
      title: 'Ảnh mẫu bữa ăn',
      subtitle: [progress, ?detail].join(' · '),
      badge: badge,
      level: level,
    );
  }

  static KitchenTask? _sampleTask(FoodSampleDay day) {
    if (day.isDayOff || day.sessions.isEmpty) return null;
    final toRecord = [
      for (final session in day.sessions)
        if (session.sample == null &&
            !session.upcoming &&
            session.dishes.isNotEmpty)
          session.label,
    ];
    final waiting = [
      for (final session in day.sessions)
        if (session.sample?.status == SampleStatus.recorded) session.label,
    ];
    final parts = [
      if (toRecord.isNotEmpty) '${_join(toRecord)} chưa ghi',
      if (waiting.isNotEmpty)
        '${_join(waiting.map(_lower).toList())} chờ PHT duyệt',
    ];
    final recorded = day.sessions.where((s) => s.sample != null).length;
    final (badge, level) = toRecord.isNotEmpty
        ? ('Cần ghi', KitchenTaskLevel.todo)
        : waiting.isNotEmpty
        ? ('Chờ duyệt', KitchenTaskLevel.waiting)
        : recorded == day.sessions.length
        ? ('Đã ghi', KitchenTaskLevel.done)
        : ('Chưa tới bữa', KitchenTaskLevel.later);
    final subtitle = parts.isEmpty
        ? '$recorded/${day.sessions.length} bữa đã ghi'
        : parts.join(' · ');
    return KitchenTask(
      kind: KitchenTaskKind.foodSamples,
      title: 'Sổ lưu mẫu',
      // Câu đầu viết hoa như nhãn bữa ("Bữa trưa chưa ghi")
      subtitle: subtitle[0].toUpperCase() + subtitle.substring(1),
      badge: badge,
      level: level,
    );
  }

  static String _sampleName(FoodSample sample) =>
      '${_lower(sample.sessionLabel)} ${DateLabels.dayMonth(sample.date)}';

  static KitchenTask? _disposalTask(FoodSampleDay day) {
    final pending = day.toDispose
        .where((s) => s.disposalStatus == SampleDisposalStatus.none)
        .toList();
    final due = pending.where((s) => s.disposableNow).toList();
    final waiting = day.toDispose
        .where((s) => s.disposalStatus == SampleDisposalStatus.recorded)
        .length;
    final (subtitle, badge, level) = due.isNotEmpty
        ? (
            due.length == 1
                ? 'Mẫu ${_sampleName(due.single)} hủy được từ ${DateLabels.time24(due.single.disposableFrom)}'
                : '${due.length} mẫu đến hạn hủy',
            'Đến hạn',
            KitchenTaskLevel.due,
          )
        : waiting > 0
        ? (
            '$waiting mẫu chờ PHT duyệt hủy',
            'Chờ duyệt',
            KitchenTaskLevel.waiting,
          )
        : pending.isNotEmpty
        ? (
            'Mẫu ${_sampleName(pending.first)} hủy được từ ${DateLabels.time24(pending.first.disposableFrom)}',
            'Chưa tới giờ',
            KitchenTaskLevel.later,
          )
        : (null, null, null);
    if (subtitle == null || badge == null || level == null) return null;
    return KitchenTask(
      kind: KitchenTaskKind.sampleDisposal,
      title: 'Hủy mẫu',
      subtitle: subtitle,
      badge: badge,
      level: level,
    );
  }
}

import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/features/kitchen/food_samples/data/fake_food_sample_source.dart';
import 'package:carenest_app/features/kitchen/food_samples/domain/food_samples.dart';
import 'package:carenest_app/features/kitchen/kitchen_home/domain/kitchen_today.dart';
import 'package:carenest_app/features/kitchen/meal_photos/data/fake_kitchen_photo_source.dart';
import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

/// Trang chủ bếp giả lúc 10:50 ngày 12/10: số suất khớp màn Suất ăn theo lớp (bữa phụ sáng
/// 46 suất của Nhà trẻ; trưa, chiều 182 suất, 7 thay thế; PHT xác nhận 08:30). Việc hôm nay
/// ghép từ ảnh mẫu và sổ lưu mẫu — BE không có API "việc hôm nay", lớp dữ liệu ghép khi nối.
class FakeKitchenHomeSource implements KitchenHomeSource {
  FakeKitchenHomeSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 400),
    KitchenPhotoSource? photos,
    FoodSampleSource? samples,
  }) : _photos = photos ?? FakeKitchenPhotoSource.shared,
       _samples = samples ?? FakeFoodSampleSource.shared;

  final FakeMode mode;
  final Duration delay;
  final KitchenPhotoSource _photos;
  final FoodSampleSource _samples;

  static const _servings = [
    SessionServings(
      session: 'MORNING',
      label: 'Bữa phụ sáng',
      total: 46,
      substitute: 1,
      blockNote: 'Nhà trẻ',
    ),
    SessionServings(
      session: 'LUNCH',
      label: 'Bữa trưa',
      total: 182,
      substitute: 7,
    ),
    SessionServings(
      session: 'AFTERNOON',
      label: 'Bữa chiều',
      total: 182,
      substitute: 7,
    ),
  ];

  static String _lower(String label) => label.toLowerCase();

  /// "bữa trưa và bữa chiều"
  static String _join(List<String> parts) => parts.length < 2
      ? parts.join()
      : '${parts.take(parts.length - 1).join(', ')} và ${parts.last}';

  static KitchenTask? _photoTask(KitchenPhotoDay day) {
    final meals = [
      for (final group in day.groups)
        for (final meal in group.meals) meal,
    ];
    if (day.isDayOff || meals.isEmpty) return null;
    final done = meals.where((m) => m.status == MealPhotoStatus.done).length;
    final progress = '$done/${meals.length} phần có ảnh';
    // Số nhóm còn thiếu ảnh theo từng bữa đang trong giờ: "bữa trưa còn 2 nhóm"
    final needed = <String, int>{};
    for (final meal in meals) {
      if (meal.status == MealPhotoStatus.needed) {
        needed.update(meal.name, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    final missed = meals
        .where((m) => m.status == MealPhotoStatus.missed)
        .length;
    final (badge, level, detail) = needed.isNotEmpty
        ? (
            'Cần chụp',
            KitchenTaskLevel.todo,
            _join([
              for (final MapEntry(key: name, value: count) in needed.entries)
                '${_lower(name)} còn $count nhóm',
            ]),
          )
        : missed > 0
        ? ('Thiếu ảnh', KitchenTaskLevel.missed, '$missed phần quá giờ')
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

  @override
  Future<KitchenToday> loadToday() async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    final today = FakeParentHomeSource.today;
    if (mode == FakeMode.empty) {
      return KitchenToday(
        date: today,
        campusLabel: 'Cơ sở chính',
        countStatus: KitchenCountStatus.none,
        servings: const [],
        tasks: const [],
        isDayOff: true,
      );
    }
    final photoDay = await _photos.loadToday();
    final sampleDay = await _samples.loadToday();
    return KitchenToday(
      date: today,
      campusLabel: 'Cơ sở chính',
      countStatus: KitchenCountStatus.confirmed,
      confirmedAt: DateTime(today.year, today.month, today.day, 8, 30),
      servings: _servings,
      tasks: [
        ?_photoTask(photoDay),
        ?_sampleTask(sampleDay),
        ?_disposalTask(sampleDay),
      ],
    );
  }
}

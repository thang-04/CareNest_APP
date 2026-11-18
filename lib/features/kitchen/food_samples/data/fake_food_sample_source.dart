import 'package:carenest_app/features/kitchen/food_samples/domain/food_sample.dart';
import 'package:carenest_app/features/kitchen/kitchen_day/data/fake_kitchen_day_source.dart';
import 'package:carenest_app/features/kitchen/kitchen_day/domain/kitchen_day.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

/// Sổ lưu mẫu giả, giữ trong bộ nhớ: hôm qua bữa trưa đã duyệt, đủ 24 giờ ⇒ cần hủy;
/// hôm qua bữa sáng đã ghi hủy chờ duyệt; hôm nay đã lưu bữa phụ sáng.
class FakeFoodSampleSource implements FoodSampleSource {
  FakeFoodSampleSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 300),
    this.failWrites = false,
  }) : _samples = mode == FakeMode.data ? _seed() : [];

  final FakeMode mode;
  final Duration delay;

  /// Giả lập ghi lỗi (mất mạng) để thử thông báo lỗi.
  final bool failWrites;

  final List<FoodSample> _samples;
  int _nextId = 100;

  static List<MenuDish> _dishes(MealSession session) =>
      FakeKitchenDaySource.sample().dishesOf(session);

  static List<FoodSample> _seed() {
    final today = FakeParentHomeSource.today;
    final yesterday = today.subtract(const Duration(days: 1));
    DateTime at(DateTime day, int hour, int minute) =>
        DateTime(day.year, day.month, day.day, hour, minute);
    return [
      FoodSample(
        id: 1,
        date: yesterday,
        session: MealSession.morning,
        sampledAt: at(yesterday, 8, 10),
        dishes: _dishes(MealSession.morning),
        status: FoodSampleStatus.approved,
        disposableFrom: at(today, 8, 10),
        disposalStatus: FoodSampleDisposalStatus.recorded,
        disposedAt: at(today, 8, 20),
      ),
      FoodSample(
        id: 2,
        date: yesterday,
        session: MealSession.lunch,
        sampledAt: at(yesterday, 10, 30),
        dishes: _dishes(MealSession.lunch),
        status: FoodSampleStatus.approved,
        disposableFrom: at(today, 10, 30),
        disposalStatus: FoodSampleDisposalStatus.none,
      ),
      FoodSample(
        id: 3,
        date: today,
        session: MealSession.morning,
        sampledAt: at(today, 8, 15),
        dishes: _dishes(MealSession.morning),
        status: FoodSampleStatus.recorded,
        disposableFrom: at(today.add(const Duration(days: 1)), 8, 15),
        disposalStatus: FoodSampleDisposalStatus.none,
      ),
    ];
  }

  Future<void> _wait() async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
  }

  Future<void> _waitWrite() async {
    await Future<void>.delayed(delay);
    if (failWrites) throw StateError('Không ghi được dữ liệu giả');
  }

  FoodSample _fromDraft(int id, FoodSampleDraft draft) {
    final dishes = _dishes(draft.session);
    return FoodSample(
      id: id,
      date: draft.date,
      session: draft.session,
      sampledAt: draft.sampledAt,
      dishes: dishes.where((dish) => draft.dishIds.contains(dish.id)).toList(),
      note: draft.note,
      status: FoodSampleStatus.recorded,
      disposableFrom: draft.sampledAt.add(const Duration(hours: 24)),
      disposalStatus: FoodSampleDisposalStatus.none,
    );
  }

  @override
  Future<List<FoodSample>> loadSamples(DateTime from, DateTime to) async {
    await _wait();
    final last = DateTime(to.year, to.month, to.day + 1);
    return _samples
        .where((s) => !s.date.isBefore(from) && s.date.isBefore(last))
        .toList();
  }

  @override
  Future<FoodSample> create(FoodSampleDraft draft) async {
    await _waitWrite();
    final sample = _fromDraft(_nextId++, draft);
    _samples.add(sample);
    return sample;
  }

  @override
  Future<FoodSample> update(int id, FoodSampleDraft draft) async {
    await _waitWrite();
    final index = _samples.indexWhere((s) => s.id == id);
    if (index < 0 || !_samples[index].editable) {
      throw StateError('Bản lưu mẫu không sửa được');
    }
    return _samples[index] = _fromDraft(id, draft);
  }

  @override
  Future<FoodSample> dispose(int id, DateTime disposedAt) async {
    await _waitWrite();
    final index = _samples.indexWhere((s) => s.id == id);
    final old = _samples[index];
    return _samples[index] = FoodSample(
      id: old.id,
      date: old.date,
      session: old.session,
      sampledAt: old.sampledAt,
      dishes: old.dishes,
      note: old.note,
      status: old.status,
      disposableFrom: old.disposableFrom,
      disposalStatus: FoodSampleDisposalStatus.recorded,
      disposedAt: disposedAt,
    );
  }
}

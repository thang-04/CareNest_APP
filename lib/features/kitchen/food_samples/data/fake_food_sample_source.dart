import 'package:carenest_app/features/kitchen/food_samples/domain/food_samples.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';

/// Sổ lưu mẫu giả của bếp cơ sở chính lúc 10:50 ngày 12/10 (canvas "Sổ lưu mẫu (NUT-21)"):
/// bữa phụ sáng đã ghi, chờ PHT duyệt; bữa trưa chưa ghi; bữa chiều chưa tới. Mẫu ngày 11/10:
/// bữa trưa đến hạn hủy, bữa chiều chưa tới giờ hủy, bữa phụ sáng đã ghi hủy chờ duyệt.
/// Tên món theo seed BE. Ghi thêm chỉ giữ trong bộ nhớ.
class FakeFoodSampleSource implements FoodSampleSource {
  FakeFoodSampleSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 300),
  });

  /// Một nguồn cho Trang chủ bếp và Sổ lưu mẫu khi chạy bản giả: ghi ở sổ thì việc ở Trang chủ đổi theo.
  static final shared = FakeFoodSampleSource();

  final FakeMode mode;
  final Duration delay;

  static DateTime _at(DateTime day, int hour, int minute) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  static DateTime get _today => FakeParentHomeSource.today;
  static DateTime get _yesterday => _today.subtract(const Duration(days: 1));

  /// Giờ giả "bây giờ" theo máy chủ
  static DateTime get _now => _at(_today, 10, 50);

  static const _labels = {
    'MORNING': 'Bữa phụ sáng',
    'LUNCH': 'Bữa trưa',
    'AFTERNOON': 'Bữa chiều',
  };

  /// Món hôm nay theo thực đơn đã công bố
  static const _menu = {
    'MORNING': [
      SampleDish(id: 11, name: 'Cháo thịt băm cà rốt', blockLabel: 'Nhà trẻ'),
    ],
    'LUNCH': [
      SampleDish(id: 21, name: 'Cơm tẻ'),
      SampleDish(id: 22, name: 'Cá basa sốt cà chua'),
      SampleDish(id: 23, name: 'Canh bí đỏ thịt băm'),
    ],
    'AFTERNOON': [SampleDish(id: 31, name: 'Sữa chua chuối')],
  };

  static const _upcoming = {'AFTERNOON'};

  var _nextId = 100;

  late final Map<String, FoodSample> _todaySamples = {
    'MORNING': FoodSample(
      id: 1,
      date: _today,
      session: 'MORNING',
      sessionLabel: _labels['MORNING']!,
      sampledAt: _at(_today, 8, 5),
      dishes: const [
        SampleDish(
          id: 11,
          name: 'Cháo thịt băm cà rốt',
          blockLabel: 'Nhà trẻ',
          weight: '150 ml',
          container: 'Hộp inox có nắp',
          temperature: '0–5',
        ),
      ],
      status: SampleStatus.recorded,
      disposableFrom: _at(_today, 8, 5).add(const Duration(days: 1)),
    ),
  };

  late final List<FoodSample> _past = [
    _pastSample(
      id: 2,
      session: 'MORNING',
      hour: 8,
      minute: 2,
      dishes: const [
        SampleDish(id: 12, name: 'Cháo gà bí đỏ', blockLabel: 'Nhà trẻ'),
      ],
      disposal: SampleDisposalStatus.recorded,
      disposableNow: true,
    ),
    _pastSample(
      id: 3,
      session: 'LUNCH',
      hour: 10,
      minute: 40,
      dishes: const [
        SampleDish(id: 21, name: 'Cơm tẻ'),
        SampleDish(id: 24, name: 'Cá thu sốt cà chua'),
        SampleDish(id: 25, name: 'Canh cải xanh thịt băm'),
      ],
      disposableNow: true,
    ),
    _pastSample(
      id: 4,
      session: 'AFTERNOON',
      hour: 14,
      minute: 50,
      dishes: const [SampleDish(id: 32, name: 'Bánh flan sữa')],
    ),
  ];

  static FoodSample _pastSample({
    required int id,
    required String session,
    required int hour,
    required int minute,
    required List<SampleDish> dishes,
    SampleDisposalStatus disposal = SampleDisposalStatus.none,
    bool disposableNow = false,
  }) {
    final sampledAt = _at(_yesterday, hour, minute);
    return FoodSample(
      id: id,
      date: _yesterday,
      session: session,
      sessionLabel: _labels[session]!,
      sampledAt: sampledAt,
      dishes: [
        for (final dish in dishes)
          SampleDish(
            id: dish.id,
            name: dish.name,
            blockLabel: dish.blockLabel,
            weight: '150 g',
            container: 'Hộp inox có nắp',
            temperature: '0–5',
          ),
      ],
      status: SampleStatus.approved,
      disposableFrom: sampledAt.add(const Duration(days: 1)),
      disposalStatus: disposal,
      disposableNow: disposableNow,
    );
  }

  FoodSampleDay _day() {
    if (mode == FakeMode.empty) {
      return FoodSampleDay(
        date: _today,
        campusLabel: 'Cơ sở chính',
        sessions: const [],
        toDispose: const [],
        isDayOff: true,
      );
    }
    return FoodSampleDay(
      date: _today,
      campusLabel: 'Cơ sở chính',
      sessions: [
        for (final MapEntry(key: session, value: dishes) in _menu.entries)
          SampleSession(
            session: session,
            label: _labels[session]!,
            dishes: dishes,
            sample: _todaySamples[session],
            upcoming: _upcoming.contains(session),
          ),
      ],
      // PHT đã duyệt hủy thì xong, không còn trong danh sách cần hủy
      toDispose: [
        for (final sample in _past)
          if (sample.disposalStatus != SampleDisposalStatus.approved) sample,
      ],
    );
  }

  @override
  Future<FoodSampleDay> loadToday() async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    return _day();
  }

  @override
  Future<FoodSampleDay> saveSample({
    required String session,
    int? sampleId,
    required List<DishNoteInput> dishes,
  }) async {
    await Future<void>.delayed(delay);
    final notes = {for (final note in dishes) note.dishId: note};
    final current = _todaySamples[session];
    // BE chặn sửa khi đã duyệt hoặc đã ghi hủy (FOOD_SAMPLE_LOCKED)
    if (sampleId != null && (current == null || !current.editable)) {
      throw StateError('Bản lưu mẫu đã khoá');
    }
    final sampledAt = current?.sampledAt ?? _now;
    _todaySamples[session] = FoodSample(
      id: current?.id ?? _nextId++,
      date: _today,
      session: session,
      sessionLabel: _labels[session]!,
      sampledAt: sampledAt,
      dishes: [
        for (final dish in _menu[session]!)
          SampleDish(
            id: dish.id,
            name: dish.name,
            blockLabel: dish.blockLabel,
            weight: notes[dish.id]?.weight ?? '',
            container: notes[dish.id]?.container ?? '',
            temperature: notes[dish.id]?.temperature ?? '',
          ),
      ],
      status: SampleStatus.recorded,
      disposableFrom: sampledAt.add(const Duration(days: 1)),
    );
    return _day();
  }

  @override
  Future<FoodSampleDay> recordDisposal(int sampleId) async {
    await Future<void>.delayed(delay);
    final index = _past.indexWhere((sample) => sample.id == sampleId);
    final sample = index < 0 ? null : _past[index];
    // BE chặn hủy trước 24 giờ (FOOD_SAMPLE_DISPOSAL_TOO_EARLY) hoặc đã ghi hủy
    if (sample == null ||
        !sample.disposableNow ||
        sample.disposalStatus != SampleDisposalStatus.none) {
      throw StateError('Chưa hủy được mẫu này');
    }
    _past[index] = FoodSample(
      id: sample.id,
      date: sample.date,
      session: sample.session,
      sessionLabel: sample.sessionLabel,
      sampledAt: sample.sampledAt,
      dishes: sample.dishes,
      status: sample.status,
      disposableFrom: sample.disposableFrom,
      disposalStatus: SampleDisposalStatus.recorded,
      disposableNow: true,
    );
    return _day();
  }
}

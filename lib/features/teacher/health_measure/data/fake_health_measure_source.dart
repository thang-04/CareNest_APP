import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/health_measure/domain/health_measure.dart';

/// Dữ liệu giả mockup T07 / T07.1: 13 bé đã đo, 15 bé chưa đo (Khánh Linh, Minh Châu, Đức Huy vắng).
/// Khớp màn Phụ huynh: Minh Anh 104 cm · 17,2 kg, lần trước 05/09: 103 cm · 16,8 kg.
class FakeHealthMeasureSource implements HealthMeasureSource {
  FakeHealthMeasureSource({this.open = true});

  /// false ⇒ không có kỳ cân đo đang mở (màn chỉ xem).
  final bool open;

  static final shared = FakeHealthMeasureSource();

  static const _absent = {'k-03', 'k-04', 'k-08'};

  late final Map<String, MeasureKid> _kids = {
    for (final (i, kid) in FakeClassRosterSource.kids.indexed)
      kid.id: _initial(i, kid.id, kid.fullName, kid.ageLabel),
  };

  static MeasureKid _initial(int i, String id, String name, String age) {
    final prevHeight = 98 + i % 8;
    final prevWeight = (15.0 + (i % 7) * 0.4)
        .toStringAsFixed(1)
        .replaceAll('.', ',');
    final previous = id == 'child-1'
        ? '05/09: 103 cm · 16,8 kg'
        : '05/09: $prevHeight cm · $prevWeight kg';
    if (_absent.contains(id)) {
      return MeasureKid(
        childId: id,
        fullName: name,
        ageLabel: age,
        state: MeasureState.absent,
        previous: previous,
      );
    }
    // 13 bé đầu danh sách (trừ bé vắng) đã đo hôm nay
    final measured = i < 16;
    return MeasureKid(
      childId: id,
      fullName: name,
      ageLabel: age,
      state: measured ? MeasureState.measured : MeasureState.pending,
      height: !measured
          ? null
          : id == 'child-1'
          ? '104'
          : '${prevHeight + 1}',
      weight: !measured
          ? null
          : id == 'child-1'
          ? '17,2'
          : prevWeight,
      measuredWhen: !measured ? null : '05/11',
      result: !measured ? null : _normal,
      previous: previous,
    );
  }

  static const _normal = MeasureResult(
    label: 'Bình thường',
    tone: AppStatusTone.green,
    detail: 'BMI 15,9',
  );

  @override
  Future<MeasureMonth> loadMonth(String classId) async {
    if (!open) return const MeasureMonth(title: '', kids: []);
    final kids = [for (final kid in FakeClassRosterSource.kids) _kids[kid.id]!];
    return MeasureMonth(
      title: 'Kỳ cân đo quý IV',
      kids: kids,
      campaign: MeasureCampaign(
        name: 'Kỳ cân đo quý IV',
        kindLabel: 'Kỳ cân đo',
        campusName: 'Cơ sở chính',
        dateRange: '05/11/2026 – 20/11/2026',
        statusLabel: 'Đang diễn ra',
        recorded: kids.where((k) => k.state == MeasureState.measured).length,
        total: kids.length,
        absent: kids.where((k) => k.state == MeasureState.absent).length,
      ),
    );
  }

  @override
  Future<List<HealthCampaign>> loadCampaigns() async => [
    if (open)
      const HealthCampaign(
        id: '2',
        name: 'Kỳ cân đo quý IV',
        kindLabel: 'Kỳ cân đo',
        campusName: 'Cơ sở chính',
        dateRange: '05/11/2026 – 20/11/2026',
        statusLabel: 'Đang diễn ra',
        statusTone: AppStatusTone.green,
        recorded: 16,
        total: 28,
      ),
    const HealthCampaign(
      id: '1',
      name: 'Kỳ cân đo quý III',
      kindLabel: 'Kỳ cân đo',
      campusName: 'Cơ sở chính',
      dateRange: '01/09/2026 – 10/09/2026',
      statusLabel: 'Đã đóng',
      statusTone: AppStatusTone.gray,
      recorded: 25,
      total: 28,
      warningLabel: '1 trẻ có cảnh báo',
    ),
  ];

  @override
  Future<void> saveMeasurement({
    required String childId,
    required String height,
    required String weight,
    String? note,
    String? reason,
  }) async {
    final current = _kids[childId];
    if (!open || current == null || current.state == MeasureState.absent) {
      throw StateError('Không thể lưu số đo cho bé này');
    }
    _kids[childId] = MeasureKid(
      childId: current.childId,
      fullName: current.fullName,
      ageLabel: current.ageLabel,
      state: MeasureState.measured,
      height: height,
      weight: weight,
      measuredWhen: 'hôm nay',
      result: _normal,
      previous: current.state == MeasureState.measured
          ? '${current.height} cm · ${current.weight} kg'
          : current.previous,
      note: (note?.trim().isEmpty ?? true) ? null : note!.trim(),
      published: true,
    );
  }
}

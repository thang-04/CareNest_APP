import 'package:carenest_app/features/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/health_measure/domain/health_measure.dart';

/// Dữ liệu giả mockup T07 / T07.1: 13 bé đã đo, 15 bé chưa đo (Khánh Linh, Minh Châu, Đức Huy vắng).
/// Khớp màn Phụ huynh: Minh Anh 104 cm · 17,2 kg, lần trước 05/09: 103 cm · 16,8 kg.
class FakeHealthMeasureSource implements HealthMeasureSource {
  FakeHealthMeasureSource();

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
      measuredWhen: !measured
          ? null
          : id == 'child-1'
          ? 'vừa xong'
          : '${i * 3 + 5} phút trước',
      previous: previous,
    );
  }

  @override
  Future<MeasureMonth> loadMonth(String classId) async => MeasureMonth(
    title: 'Đo sức khỏe tháng 10',
    kids: [for (final kid in FakeClassRosterSource.kids) _kids[kid.id]!],
  );

  // Kết quả giả thay cho BE: đủ hai số thì trả "Bình thường"
  @override
  Future<MeasureResult?> preview(
    String childId,
    String height,
    String weight,
  ) async {
    if (height.trim().isEmpty || weight.trim().isEmpty) return null;
    return const MeasureResult(
      label: 'Bình thường',
      detail: 'Cân nặng/tuổi · Chiều cao/tuổi đạt',
      position: 0.5,
    );
  }

  @override
  Future<void> save(MeasureKid kid) async => _kids[kid.childId] = kid;
}

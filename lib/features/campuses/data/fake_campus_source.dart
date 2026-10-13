import 'package:carenest_app/features/campus_children/data/fake_campus_children_source.dart';
import 'package:carenest_app/features/campuses/domain/campus.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';

/// Dữ liệu giả mockup H08: 2 cơ sở, số lớp / số trẻ khớp danh sách trẻ giả (196 + 138).
/// Bỏ mảng "CSVC" của mockup: cơ sở vật chất không thuộc phạm vi CareNest.
class FakeCampusSource implements CampusSource {
  FakeCampusSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 300),
  });

  final FakeMode mode;
  final Duration delay;

  static const _scopes = ['Trẻ & lớp', 'Bán trú', 'Thực đơn'];

  @override
  String get schoolYear => '2026–2027';

  @override
  Future<List<Campus>> loadCampuses() async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    if (mode == FakeMode.empty) return const [];
    const main = FakeCampusChildrenSource.mainCampusId;
    const second = FakeCampusChildrenSource.secondCampusId;
    return [
      Campus(
        id: main,
        name: FakeCampusChildrenSource.campusNames[main]!,
        address: 'Số 12 Thượng Hồng, Hải Phòng',
        classCount: FakeCampusChildrenSource.classesOf(main).length,
        childCount: FakeCampusChildrenSource.childrenOf(main).length,
        vicePrincipal: 'Thầy Lê Văn Bình',
        scopes: _scopes,
      ),
      Campus(
        id: second,
        name: FakeCampusChildrenSource.campusNames[second]!,
        address: '45 An Đồng, An Dương',
        classCount: FakeCampusChildrenSource.classesOf(second).length,
        childCount: FakeCampusChildrenSource.childrenOf(second).length,
        vicePrincipal: 'Cô Vũ Thị Hạnh',
        scopes: _scopes,
      ),
    ];
  }
}

import 'package:carenest_app/features/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/pickup/domain/pickup.dart';

/// Dữ liệu giả mockup T05/T06: 25 bé có mặt (khớp Điểm danh), 18 đã đón, 7 chờ đón.
/// Một bản dùng chung để danh sách thấy bé vừa giao.
class FakePickupSource implements PickupSource {
  FakePickupSource();

  static final shared = FakePickupSource();

  static const _absent = {'k-03', 'k-04', 'k-08'};
  static const _waiting = {
    'child-1',
    'k-02',
    'k-05',
    'k-15',
    'k-20',
    'k-24',
    'k-27',
  };

  static List<RegisteredGuardian> _guardiansOf(String childId, String line) {
    if (childId == 'child-1') {
      return const [
        RegisteredGuardian(
          id: 'g-1',
          relation: 'Mẹ',
          fullName: 'Nguyễn Thu Lan',
          phone: '0912 345 678',
        ),
        RegisteredGuardian(
          id: 'g-2',
          relation: 'Bố',
          fullName: 'Trần Văn Hùng',
          phone: '0987 654 321',
        ),
      ];
    }
    final relation = line.split(':').first;
    final surname = FakeClassRosterSource.kidById(
      childId,
    ).fullName.split(' ').first;
    final given = switch (relation) {
      'Mẹ' => 'Thị Mai',
      'Ông' => 'Văn Tư',
      _ => 'Văn An',
    };
    return [
      RegisteredGuardian(
        id: 'g-$childId',
        relation: relation,
        fullName: '$surname $given',
        phone: line.split(': ').last,
      ),
      if (childId == 'k-02')
        const RegisteredGuardian(
          id: 'g-k02b',
          relation: 'Bà ngoại',
          fullName: 'Lê Thị Hoa',
          phone: '0904 222 333',
        ),
    ];
  }

  late final Map<String, PickupKid> _kids = {
    for (final (i, kid) in FakeClassRosterSource.kids.indexed)
      if (!_absent.contains(kid.id))
        kid.id: PickupKid(
          childId: kid.id,
          fullName: kid.fullName,
          guardians: _guardiansOf(kid.id, kid.guardianLine),
          pickedUpAt: _waiting.contains(kid.id)
              ? null
              : DateTime(2026, 10, 12, 16, 30 + i % 15),
          pickedUpBy: _waiting.contains(kid.id)
              ? null
              : kid.id == 'k-07'
              ? 'Ông nội'
              : kid.guardianLine.split(':').first,
        ),
  };

  @override
  Future<List<PickupKid>> loadClass(String classId) async => [
    ..._kids.values.where((kid) => !kid.pickedUp),
    ..._kids.values.where((kid) => kid.pickedUp),
  ];

  @override
  Future<void> handOver(String childId, RegisteredGuardian guardian) async {
    final kid = _kids[childId]!;
    _kids[childId] = PickupKid(
      childId: kid.childId,
      fullName: kid.fullName,
      guardians: kid.guardians,
      pickedUpAt: DateTime(2026, 10, 12, 16, 45),
      pickedUpBy: guardian.relation,
    );
  }
}

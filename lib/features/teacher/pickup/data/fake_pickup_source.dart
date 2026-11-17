import 'package:carenest_app/features/teacher/attendance/data/fake_attendance_source.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/pickup/domain/pickup.dart';

/// Dữ liệu giả bảng đón lớp Mầm 3A, dạng theo BE `PickupBoardResponse`: bé có mặt theo màn
/// Điểm danh, 7 bé chờ đón, còn lại đã đón; bé có đơn nghỉ là ABSENT. Tên, SĐT là giả; photoUrl giả không tải ảnh thật; bố Minh Anh và phụ huynh bé k-05 chưa có ảnh.
class FakePickupSource implements PickupSource {
  FakePickupSource();

  static final shared = FakePickupSource();

  static const _waiting = {
    'child-1',
    'k-02',
    'k-05',
    'k-15',
    'k-20',
    'k-24',
    'k-27',
  };

  static GuardianRelationship _relationOf(String line) =>
      switch (line.split(':').first) {
        'Mẹ' => GuardianRelationship.mother,
        'Bố' => GuardianRelationship.father,
        'Ông' => GuardianRelationship.grandfather,
        'Bà' => GuardianRelationship.grandmother,
        _ => GuardianRelationship.guardian,
      };

  static List<PickupGuardian> guardiansOf(String childId) {
    if (childId == 'child-1') {
      return const [
        PickupGuardian(
          position: 1,
          fullName: 'Nguyễn Thu Lan',
          relationship: GuardianRelationship.mother,
          phone: '0912345678',
          photoUrl: 'fake://guardian/1',
        ),
        PickupGuardian(
          position: 2,
          fullName: 'Trần Văn Hùng',
          relationship: GuardianRelationship.father,
          phone: '0987654321',
        ),
      ];
    }
    final kid = FakeClassRosterSource.kidById(childId);
    final relation = _relationOf(kid.guardianLine);
    final surname = kid.fullName.split(' ').first;
    final given = switch (relation) {
      GuardianRelationship.mother => 'Thị Mai',
      GuardianRelationship.grandfather => 'Văn Tư',
      _ => 'Văn An',
    };
    return [
      PickupGuardian(
        position: 1,
        fullName: '$surname $given',
        relationship: relation,
        phone: kid.guardianLine.split(': ').last.replaceAll(' ', ''),
        // Một bé chưa có ảnh phụ huynh ⇒ GV phải gọi (PCK-02)
        photoUrl: childId == 'k-05' ? null : 'fake://guardian/$childId',
      ),
    ];
  }

  late final Map<String, PickupRow> _rows = {
    for (final (i, kid) in FakeAttendanceSource.kids.indexed)
      kid.childId: kid.hasLeaveNotice
          ? PickupRow(
              childId: kid.childId,
              fullName: kid.fullName,
              status: PickupStatus.absent,
            )
          : _waiting.contains(kid.childId)
          ? PickupRow(
              childId: kid.childId,
              fullName: kid.fullName,
              status: PickupStatus.waiting,
            )
          : PickupRow(
              childId: kid.childId,
              fullName: kid.fullName,
              status: PickupStatus.pickedUp,
              pickup: PickupRecord(
                verification: PickupVerification.photoMatch,
                guardianPosition: 1,
                pickupPersonName: guardiansOf(kid.childId).first.fullName,
                pickupPersonRelationship: guardiansOf(
                  kid.childId,
                ).first.relationship,
                handedOverAt: DateTime(2026, 10, 12, 16, 30 + i % 15),
              ),
            ),
  };

  /// Request GV đã gửi, theo thứ tự (để test kiểm tra).
  final List<PickupRequest> requests = [];

  @override
  Future<List<PickupRow>> loadBoard(String classId) async => [
    ..._rows.values.where((row) => row.status == PickupStatus.waiting),
    ..._rows.values.where((row) => row.status == PickupStatus.pickedUp),
  ];

  @override
  Future<PickupChild> loadChild(String childId) async => PickupChild(
    row: _rows[childId]!,
    className: FakeClassRosterSource.className,
    guardians: guardiansOf(childId),
  );

  @override
  Future<void> record(PickupRequest request) async {
    requests.add(request);
    if (!request.verification.handedOver) return;
    final row = _rows[request.childId]!;
    final guardian = request.guardianPosition == null
        ? null
        : guardiansOf(
            request.childId,
          ).firstWhere((g) => g.position == request.guardianPosition);
    final parts = request.handoverTime!.split(':');
    _rows[request.childId] = PickupRow(
      childId: row.childId,
      fullName: row.fullName,
      status: PickupStatus.pickedUp,
      pickup: PickupRecord(
        verification: request.verification,
        guardianPosition: request.guardianPosition,
        pickupPersonName: guardian?.fullName,
        pickupPersonRelationship: guardian?.relationship,
        handedOverAt: DateTime(
          2026,
          10,
          12,
          int.parse(parts[0]),
          int.parse(parts[1]),
        ),
        note: request.note,
      ),
    );
  }
}

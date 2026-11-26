import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/teacher/class_roster/data/live_teacher_classes.dart';
import 'package:carenest_app/features/teacher/class_roster/domain/class_roster.dart';
import 'package:carenest_app/features/teacher/pickup/domain/pickup.dart';
import 'package:carenest_app/features/teacher/school_year/presentation/selected_school_year.dart';

/// Danh sách lớp từ BE: trẻ = `GET /children?classId=` (mọi trạng thái, như Web; lọc ở màn), tên lớp = `GET /attendance/classes`.
/// BE chưa trả tên điểm trường cho giáo viên ⇒ `campusName` rỗng (màn ẩn).
class LiveClassRosterSource implements ClassRosterSource {
  LiveClassRosterSource(
    this._api, {
    DateTime Function()? clock,
    String? Function()? schoolYearId,
  }) : _clock = clock ?? DateTime.now,
       _schoolYearId = schoolYearId ?? (() => SelectedSchoolYear.apiYearId);

  final MobileApi _api;
  final DateTime Function() _clock;
  final String? Function() _schoolYearId;

  @override
  Future<ClassRoster> loadRoster(String classId) async {
    final yearId = _schoolYearId();
    // BE xếp trẻ vào lớp theo năm: lớp năm khác cần `schoolYear` mới ra danh sách
    final yearQuery = yearId == null ? '' : '&schoolYear=$yearId';
    final results = await Future.wait<Object?>([
      _api.json('GET', '/children?classId=$classId&size=100$yearQuery'),
      loadTeacherClasses(_api, schoolYearId: yearId),
    ]);
    final page = results[0] as Map? ?? const {};
    final classes = results[1]! as List<TeacherClass>;
    final name = classes.where((c) => c.id == classId).firstOrNull?.name;
    final items = (page['items'] as List? ?? const []).whereType<Map>();
    return ClassRoster(
      classId: classId,
      className: name ?? items.firstOrNull?['className']?.toString() ?? '',
      campusName: '',
      kids: [for (final child in items) _kid(child)],
    );
  }

  RosterKid _kid(Map<Object?, Object?> child) {
    final allergies = [
      for (final item in child['allergies'] as List? ?? const []) '$item',
    ];
    return RosterKid(
      id: '${child['id']}',
      fullName: child['fullName']?.toString() ?? '',
      ageLabel: _age(child['dateOfBirth']),
      guardianLine: _guardian(child['guardians']),
      dateOfBirth: DateTime.tryParse('${child['dateOfBirth']}'),
      status: switch (child['status']) {
        'PENDING_PLACEMENT' => RosterKidStatus.pendingPlacement,
        'LEFT' => RosterKidStatus.left,
        _ => RosterKidStatus.active,
      },
      tag: allergies.isEmpty
          ? null
          : RosterTag(RosterTagKind.allergy, 'Dị ứng ${allergies.join(', ')}'),
    );
  }

  String _age(Object? dateOfBirth) {
    if (dateOfBirth is! String) return '';
    final born = DateTime.tryParse(dateOfBirth);
    if (born == null) return '';
    final now = _clock();
    var years = now.year - born.year;
    if (now.month < born.month ||
        (now.month == born.month && now.day < born.day)) {
      years--;
    }
    return years < 0 ? '' : '$years tuổi';
  }

  /// "Mẹ: 0912345678" của phụ huynh đầu tiên có SĐT; BE đã bỏ CCCD, email ở danh sách.
  String _guardian(Object? guardians) {
    for (final g in (guardians as List? ?? const []).whereType<Map>()) {
      final phone = g['phone']?.toString() ?? '';
      if (phone.isEmpty) continue;
      final relation = GuardianRelationship.values
          .where((r) => r.code == g['relation'])
          .firstOrNull;
      return '${relation?.label ?? g['fullName'] ?? ''}: $phone';
    }
    return '';
  }
}

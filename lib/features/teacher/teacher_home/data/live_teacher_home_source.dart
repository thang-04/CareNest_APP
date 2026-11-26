import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/teacher/class_roster/data/live_teacher_classes.dart';
import 'package:carenest_app/features/teacher/teacher_home/domain/teacher_today.dart';

/// Trang chủ GV từ BE (chưa có endpoint riêng): tên = `GET /accounts/me`; lớp = `GET /attendance/classes`
/// (lớp đầu tiên `teaches`, hoặc [classId]); số đã điểm danh, giờ chốt, khóa, khám đầu ngày =
/// `GET /classes/{id}/attendance`; số đơn nghỉ = `GET /leave-requests?classId=`. BE chưa có lịch hoạt động
/// đang diễn ra ⇒ `currentActivity` null. APP chỉ đếm bản ghi BE trả, không áp rule.
class LiveTeacherHomeSource implements TeacherHomeSource {
  LiveTeacherHomeSource(this._api, {this.classId, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final MobileApi _api;
  final String? classId;
  final DateTime Function() _clock;

  @override
  Future<TeacherToday> loadToday() async {
    final me = await _api.json('GET', '/accounts/me') as Map? ?? const {};
    final name = me['fullName']?.toString() ?? '';
    final taught = (await loadTeacherClasses(
      _api,
    )).where((c) => c.teaches).toList();
    final wanted = classId;
    final cls = wanted == null
        ? taught.firstOrNull
        : taught.where((c) => c.id == wanted).firstOrNull;
    if (cls == null) {
      return TeacherToday(
        teacherName: name,
        date: _clock(),
        className: '',
        childCount: 0,
        tasks: const [],
      );
    }
    final id = cls.id;
    final sheet =
        await _api.json('GET', '/classes/$id/attendance') as Map? ?? const {};
    final leaveCount = await _leaveCount(id);

    final day = sheet['day'] as Map? ?? const {};
    final schoolDay = day['schoolDay'] != false;
    final rows = (sheet['children'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final total = rows.length;
    final recorded = rows.where((r) => r['record'] != null).length;
    final missing = total - recorded;
    final present = rows
        .where((r) => (r['record'] as Map?)?['status'] == 'PRESENT')
        .toList();
    final checked = present
        .where((r) => (r['health'] as Map?)?['checked'] == true)
        .length;
    final cutoff = day['cutoff']?.toString() ?? '';
    final locked = day['locked'] == true;
    final leaves = rows.where((r) => r['leave'] != null).length;
    final leaveTotal = leaveCount ?? leaves;

    return TeacherToday(
      teacherName: name,
      date: DateTime.tryParse('${day['date']}') ?? _clock(),
      className: cls.name,
      childCount: total,
      deadlineNote: cutoff.isEmpty ? null : 'Hạn điểm danh: $cutoff',
      attendanceRecorded: schoolDay && total > 0 ? recorded : null,
      tasks: [
        if (schoolDay) ...[
          TeacherTask(
            kind: TeacherTaskKind.attendance,
            title: 'Điểm danh',
            subtitle: [
              '$recorded/$total trẻ',
              if (cutoff.isNotEmpty) 'trước $cutoff',
            ].join(' · '),
            badge: missing == 0 && total > 0
                ? 'Đã xong'
                : locked
                ? 'Quá giờ'
                : 'Cần làm',
            badgeLevel: missing == 0 && total > 0
                ? TaskBadgeLevel.info
                : TaskBadgeLevel.todo,
            highlighted: missing > 0,
          ),
          TeacherTask(
            kind: TeacherTaskKind.dailyHealth,
            title: 'Sức khỏe',
            subtitle: present.isEmpty
                ? 'Đầu ngày · cân nặng · chiều cao'
                : 'Đã khám $checked/${present.length} trẻ có mặt',
            badge: present.isNotEmpty && checked >= present.length
                ? 'Đã xong'
                : 'Tiếp theo',
            badgeLevel: TaskBadgeLevel.info,
          ),
          const TeacherTask(
            kind: TeacherTaskKind.pickup,
            title: 'Trả trẻ',
            subtitle: 'Đối chiếu ảnh phụ huynh',
            badge: 'Cuối ngày',
            badgeLevel: TaskBadgeLevel.info,
          ),
        ],
        TeacherTask(
          kind: TeacherTaskKind.leave,
          title: 'Đơn xin nghỉ của lớp',
          subtitle: leaveTotal > 0 ? '$leaveTotal đơn' : 'Đơn nghỉ của lớp',
          badge: 'Chỉ xem',
          badgeLevel: leaveTotal > 0
              ? TaskBadgeLevel.fresh
              : TaskBadgeLevel.info,
        ),
        const TeacherTask(
          kind: TeacherTaskKind.review,
          title: 'Đánh giá trẻ',
          subtitle: 'Ngày · tuần · định kỳ',
          badge: 'Chỉ xem',
          badgeLevel: TaskBadgeLevel.info,
        ),
        const TeacherTask(
          kind: TeacherTaskKind.menu,
          title: 'Thực đơn',
          subtitle: 'Các bữa hôm nay',
          badge: 'Chỉ xem',
          badgeLevel: TaskBadgeLevel.info,
        ),
        const TeacherTask(
          kind: TeacherTaskKind.rewards,
          title: 'Khen thưởng',
          subtitle: 'Phiếu bé ngoan · đề xuất',
          badge: 'Chỉ xem',
          badgeLevel: TaskBadgeLevel.info,
        ),
      ],
    );
  }

  /// Số đơn BE trả cho lớp (không lọc ở APP); lỗi ⇒ null.
  Future<int?> _leaveCount(String id) async {
    try {
      final data = await _api.json('GET', '/leave-requests?classId=$id');
      return data is List ? data.length : null;
    } on ApiFailure {
      return null;
    }
  }
}

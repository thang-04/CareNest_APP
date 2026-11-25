import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/integration/mobile_session.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/parent/parent_home/domain/parent_today.dart';

/// Trang chủ phụ huynh từ BE: con = `childIds` của `/accounts/me` + `GET /children/{id}/profile`,
/// hôm nay = `GET /children/{id}/attendance/today` (ATT-15), số chưa đọc = `GET /me/notifications`.
class LiveParentHomeSource implements ParentHomeSource {
  LiveParentHomeSource(this._api, this._session);

  final MobileApi _api;
  final MobileSession _session;

  // Danh sách con tải một lần mỗi phiên; đổi người dùng ⇒ tải lại
  Future<List<ChildSummary>>? _children;
  int? _childrenOwner;

  @override
  Future<List<ChildSummary>> loadChildren() {
    final owner = _session.userId;
    if (_children == null || owner != _childrenOwner) {
      _childrenOwner = owner;
      _children = _fetchChildren().catchError((Object error) {
        // Lỗi không giữ lại: lần sau thử tải lại
        _children = null;
        throw error;
      });
    }
    return _children!;
  }

  Future<List<ChildSummary>> _fetchChildren() async {
    final ids = [
      for (final id in _session.account?['childIds'] as List? ?? const [])
        '$id',
    ];
    return Future.wait([
      for (final id in ids)
        _api
            .json('GET', '/children/$id/profile')
            .then((data) => childSummaryFrom(id, data! as Map)),
    ]);
  }

  @override
  Future<ParentToday> loadToday(String childId) async {
    final results = await Future.wait([
      _api.json('GET', '/children/$childId/attendance/today'),
      _api.json('GET', '/me/notifications'),
      loadChildren(),
    ]);
    final today = results[0]! as Map;
    final feed = results[1]! as Map;
    final children = results[2]! as List<ChildSummary>;
    return ParentToday(
      greetingName: _session.account?['fullName']?.toString() ?? '',
      date: DateTime.parse(today['date'] as String),
      child: children.firstWhere((child) => child.id == childId),
      attendance: _status(today['status'] as String?),
      arrivedAt: switch (today['arrivedAt']) {
        final String at => DateTime.parse(at).toLocal(),
        _ => null,
      },
      absentPart: switch (today['absentPart']) {
        'MORNING' => AbsentPart.morning,
        'AFTERNOON' => AbsentPart.afternoon,
        _ => null,
      },
      unreadNotifications: (feed['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  static ParentAttendanceStatus _status(String? code) => switch (code) {
    'PRESENT' => ParentAttendanceStatus.present,
    'ABSENT_EXCUSED' => ParentAttendanceStatus.absentExcused,
    'ABSENT' => ParentAttendanceStatus.absentUnexcused,
    'NO_SCHOOL' => ParentAttendanceStatus.noSchool,
    'NOT_ENROLLED' => ParentAttendanceStatus.notEnrolled,
    _ => ParentAttendanceStatus.notRecorded,
  };
}

/// `ChildPhotoProfileResponse` → thẻ bé; điểm trường, tuổi, GV chủ nhiệm chưa có ở BE ⇒ null.
ChildSummary childSummaryFrom(String id, Map<Object?, Object?> profile) {
  final child = profile['child'] as Map? ?? const {};
  final cls = profile['cls'] as Map?;
  final fullName = child['fullName']?.toString() ?? '';
  final words = fullName.trim().split(RegExp(r'\s+'));
  return ChildSummary(
    id: id,
    fullName: fullName,
    // Tên gọi = 2 chữ cuối của họ tên ("Nguyễn Minh Anh" ⇒ "Minh Anh")
    shortName: words.length > 2
        ? words.sublist(words.length - 2).join(' ')
        : fullName,
    className: (child['className'] ?? cls?['name'])?.toString() ?? '',
  );
}

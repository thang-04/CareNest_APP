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

  // Danh sách con tải một lần mỗi lần đăng nhập (người dùng + generation): đăng nhập lại ⇒ tải lại,
  // vì con của tài khoản có thể đã đổi (thêm bé, bé nghỉ học)
  Future<List<ChildSummary>>? _children;
  (int?, int)? _childrenOwner;

  @override
  Future<List<ChildSummary>> loadChildren() {
    final owner = (_session.userId, _session.generation);
    if (_children == null || owner != _childrenOwner) {
      _childrenOwner = owner;
      final children = _fetchChildren();
      _children = children;
      children.catchError((Object _) {
        // Lỗi không giữ lại: lần sau thử tải lại (chỉ xóa đúng lần tải này)
        if (identical(_children, children)) _children = null;
        return const <ChildSummary>[];
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
      // Chỉ cần số chưa đọc; tải thông báo lỗi không làm hỏng trang chủ
      _api
          .json('GET', '/me/notifications?limit=1')
          .then<Object?>((feed) => feed, onError: (_) => const {}),
      loadChildren(),
    ]);
    final today = results[0]! as Map;
    final feed = results[1] as Map? ?? const {};
    var children = results[2]! as List<ChildSummary>;
    // Bé mới có trên tài khoản sau lần tải danh sách ⇒ tải lại một lần
    if (!children.any((child) => child.id == childId)) {
      _children = null;
      children = await loadChildren();
    }
    final child = children.where((child) => child.id == childId).firstOrNull;
    if (child == null) {
      throw ApiFailure(403, 'Bạn chỉ xem được thông tin của con mình.', 4108);
    }
    return ParentToday(
      greetingName: _session.account?['fullName']?.toString() ?? '',
      date: DateTime.parse(today['date'] as String),
      child: child,
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

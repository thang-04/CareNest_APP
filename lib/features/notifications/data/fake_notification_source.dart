import 'package:carenest_app/features/account/domain/account_profile.dart';
import 'package:carenest_app/features/notifications/domain/app_notification.dart';

/// Dữ liệu giả theo mockup P06–P07; khớp dữ liệu giả của các màn khác (bé Minh Anh, lớp Mầm 3A).
class FakeNotificationSource implements NotificationSource {
  const FakeNotificationSource();

  static final byRole = <AppRole, List<AppNotification>>{
    AppRole.parent: [
      AppNotification(
        id: 'p1',
        kind: NotificationKind.review,
        title: 'Bé Minh Anh đã được đánh giá hôm nay',
        sender: 'Cô Hà',
        sentAt: DateTime(2026, 10, 12, 16, 5),
        body:
            'Giáo viên đã gửi đánh giá hằng ngày (sức khỏe, cảm xúc, kỹ năng học tập) cho bé.',
        tag: 'Bé Nguyễn Minh Anh · Mầm 3A',
        hasPhoto: true,
        actionLabel: 'Xem đánh giá của bé',
        unread: true,
      ),
      AppNotification(
        id: 'p2',
        kind: NotificationKind.leave,
        title: 'Đơn xin nghỉ 13/10 đã được gửi tới cô Hà',
        sentAt: DateTime(2026, 10, 12, 7, 55),
        body: 'Suất ăn ngày 13/10 của bé đã được huỷ tự động.',
        tag: 'Bé Nguyễn Minh Anh · Mầm 3A',
        unread: true,
      ),
      AppNotification(
        id: 'p3',
        kind: NotificationKind.menu,
        title: 'Thực đơn tuần 12/10 – 16/10 đã được công bố',
        sentAt: DateTime(2026, 10, 10, 9),
      ),
      AppNotification(
        id: 'p4',
        kind: NotificationKind.health,
        title: 'Kết quả đo sức khỏe tháng 10 đã có',
        sentAt: DateTime(2026, 10, 12, 9, 40),
      ),
      AppNotification(
        id: 'p5',
        kind: NotificationKind.attendance,
        title: 'Bé đã được điểm danh: Có mặt',
        sentAt: DateTime(2026, 10, 12, 7, 42),
      ),
    ],
    AppRole.teacher: [
      AppNotification(
        id: 't1',
        kind: NotificationKind.leave,
        title: '2 đơn xin nghỉ mới của lớp Mầm 3A',
        sentAt: DateTime(2026, 10, 12, 7, 55),
        body: 'Phụ huynh bé Minh Anh và bé Khánh Linh vừa gửi đơn xin nghỉ.',
        tag: 'Lớp Mầm 3A',
        actionLabel: 'Xem đơn xin nghỉ',
        unread: true,
      ),
      AppNotification(
        id: 't2',
        kind: NotificationKind.health,
        title: 'Nhắc: đo sức khỏe tháng 10 còn 16 bé',
        sentAt: DateTime(2026, 10, 12, 7),
        unread: true,
      ),
      AppNotification(
        id: 't3',
        kind: NotificationKind.meal,
        title: 'Bếp đã giao bữa trưa tới lớp',
        sentAt: DateTime(2026, 10, 12, 10, 40),
        unread: true,
      ),
      AppNotification(
        id: 't4',
        kind: NotificationKind.menu,
        title: 'Thực đơn tuần 12/10 – 16/10 đã được công bố',
        sentAt: DateTime(2026, 10, 10, 9),
      ),
    ],
    AppRole.kitchen: [
      AppNotification(
        id: 'k1',
        kind: NotificationKind.meal,
        title: 'Mầm 3A xin điều chỉnh +1 suất bữa trưa',
        sentAt: DateTime(2026, 10, 12, 9, 5),
        body:
            'Đang chờ Phó HT duyệt. Bếp tiếp tục nấu theo số đã chốt 182 suất cho tới khi có số mới.',
        unread: true,
      ),
      AppNotification(
        id: 'k2',
        kind: NotificationKind.menu,
        title: 'Thực đơn tuần 12/10 – 16/10 đã được công bố',
        sentAt: DateTime(2026, 10, 10, 9),
        unread: true,
      ),
    ],
    AppRole.vicePrincipal: [
      AppNotification(
        id: 'v1',
        kind: NotificationKind.meal,
        title: 'Mầm 3A xin điều chỉnh +1 suất',
        sender: 'Cô Hà',
        sentAt: DateTime(2026, 10, 12, 9, 5),
        body: 'Bé đến muộn, giáo viên sửa điểm danh sau giờ chốt.',
        actionLabel: 'Xem yêu cầu',
        unread: true,
      ),
      AppNotification(
        id: 'v2',
        kind: NotificationKind.approval,
        title: '8 đề xuất khen thưởng từ giáo viên',
        sentAt: DateTime(2026, 10, 11, 17),
        unread: true,
      ),
      AppNotification(
        id: 'v3',
        kind: NotificationKind.meal,
        title: 'Bếp báo thiếu cá basa 0,7 kg',
        sender: 'Cô Mai',
        sentAt: DateTime(2026, 10, 12, 7, 55),
      ),
    ],
    AppRole.principal: [
      AppNotification(
        id: 'h1',
        kind: NotificationKind.approval,
        title: 'Phó HT Lê Văn Bình gửi 7 đề xuất khen thưởng',
        sentAt: DateTime(2026, 10, 13, 8),
        tag: 'Cơ sở chính',
        actionLabel: 'Xem đề xuất',
        unread: true,
      ),
      AppNotification(
        id: 'h2',
        kind: NotificationKind.menu,
        title: 'Thực đơn tuần 12/10 – 16/10: 2/2 cơ sở đã công bố',
        sentAt: DateTime(2026, 10, 10, 9),
      ),
    ],
  };

  @override
  Future<List<AppNotification>> load(AppRole role) async => byRole[role]!;
}

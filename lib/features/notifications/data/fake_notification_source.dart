import 'package:carenest_app/features/account/domain/account_profile.dart';
import 'package:carenest_app/features/notifications/domain/app_notification.dart';

/// Dữ liệu giả theo loại BE `NotificationType` mỗi role nhận (PAR-07); khớp dữ liệu giả các màn khác
/// (bé Minh Anh, lớp Mầm 3A). Câu chữ mô phỏng nội dung BE soạn, không kèm dữ liệu sức khỏe — trừ nhận định xu hướng
/// đã duyệt: BE gửi tổng quan giáo viên đã duyệt (HLT-21), push trên màn khóa vẫn chỉ ghi "Thông tin sức khỏe".
class FakeNotificationSource implements NotificationSource {
  const FakeNotificationSource();

  static final byRole = <AppRole, List<AppNotification>>{
    AppRole.parent: [
      AppNotification(
        id: 'p1',
        type: NotificationType.dailyHealthNoted,
        title: 'Sức khỏe của bé cần lưu ý',
        sentAt: DateTime(2026, 10, 12, 9, 10),
        body:
            'Cô giáo ghi nhận sức khỏe của bé ngày 12/10/2026 cần lưu ý. Mở ứng dụng để xem chi tiết.',
        childId: 'child-1',
        tag: 'Bé Nguyễn Minh Anh · Mầm 3A',
        unread: true,
      ),
      AppNotification(
        id: 'p2',
        type: NotificationType.weeklyCommentSent,
        title: 'Nhận xét tuần 05/10 – 09/10 của bé',
        sentAt: DateTime(2026, 10, 10, 16, 30),
        body: 'Cô giáo đã gửi nhận xét tuần của bé.',
        childId: 'child-1',
        tag: 'Bé Nguyễn Minh Anh · Mầm 3A',
        unread: true,
      ),
      AppNotification(
        id: 'p3',
        type: NotificationType.childPickedUp,
        title: 'Bé Minh Anh đã được đón',
        sentAt: DateTime(2026, 10, 9, 16, 45),
        body: 'Bé đã được trả cho người đón lúc 16:45.',
        childId: 'child-1',
        tag: 'Bé Nguyễn Minh Anh · Mầm 3A',
      ),
      AppNotification(
        id: 'p5',
        type: NotificationType.healthTrendApproved,
        title: 'Nhận định xu hướng sức khỏe mới',
        sentAt: DateTime(2026, 10, 8, 10, 15),
        body:
            'Trong 6 tháng qua, trẻ phát triển ổn định: cân nặng tăng 0,6 kg, chiều cao tăng 3 cm, các chỉ số trong khoảng chuẩn WHO.',
        childId: 'child-1',
        tag: 'Bé Nguyễn Minh Anh · Mầm 3A',
      ),
      AppNotification(
        id: 'p4',
        type: NotificationType.healthResultPublished,
        title: 'Kết quả cân đo tháng 10 đã công bố',
        sentAt: DateTime(2026, 10, 5, 15, 20),
        body: 'Có thông tin sức khỏe mới. Mở ứng dụng để xem.',
        childId: 'child-1',
        tag: 'Bé Nguyễn Minh Anh · Mầm 3A',
      ),
    ],
    AppRole.teacher: [
      AppNotification(
        id: 't1',
        type: NotificationType.leaveRequestChanged,
        title: 'Phụ huynh bé Minh Anh gửi đơn nghỉ 13/10',
        sentAt: DateTime(2026, 10, 12, 7, 55),
        body: 'Ngày 13/10 bé được ghi Vắng có phép.',
        childId: 'child-1',
        tag: 'Lớp Mầm 3A',
        unread: true,
      ),
      AppNotification(
        id: 't2',
        type: NotificationType.attendanceReminder,
        title: 'Sắp tới giờ chốt điểm danh 08:30',
        sentAt: DateTime(2026, 10, 12, 8, 15),
        body: 'Lớp Mầm 3A còn 25 bé chưa điểm danh.',
        tag: 'Lớp Mầm 3A',
        unread: true,
      ),
      AppNotification(
        id: 't3',
        type: NotificationType.childPlaced,
        title: 'Bé Trần Gia Bảo được xếp vào lớp Mầm 3A',
        sentAt: DateTime(2026, 10, 11, 10),
        tag: 'Lớp Mầm 3A',
      ),
      AppNotification(
        id: 't4',
        type: NotificationType.healthCheckOpened,
        title: 'Kỳ cân đo tháng 10 đã mở',
        sentAt: DateTime(2026, 10, 5, 7, 30),
        tag: 'Lớp Mầm 3A',
      ),
    ],
    AppRole.kitchen: [
      AppNotification(
        id: 'k1',
        type: NotificationType.mealCountConfirmed,
        title: 'Số suất cơ sở chính hôm nay đã cập nhật',
        sentAt: DateTime(2026, 10, 12, 9, 5),
        body:
            'Phó Hiệu trưởng đã xác nhận lại số suất sau khi mở lại điểm danh.',
        unread: true,
      ),
      AppNotification(
        id: 'k2',
        type: NotificationType.cutoffChanged,
        title: 'Giờ chốt điểm danh đổi thành 08:30 từ 15/10',
        sentAt: DateTime(2026, 10, 10, 9),
        unread: true,
      ),
    ],
    AppRole.vicePrincipal: [
      AppNotification(
        id: 'v1',
        type: NotificationType.mealCountReconfirm,
        title: 'Sổ báo ăn 12/10 cần xác nhận lại',
        sentAt: DateTime(2026, 10, 12, 9, 5),
        body: 'Lớp Mầm 3A sửa điểm danh sau khi mở lại ngày.',
        tag: 'Cơ sở chính',
        unread: true,
      ),
      AppNotification(
        id: 'v2',
        type: NotificationType.rewardListUpdated,
        title: 'Lớp Mầm 3A gửi danh sách khen thưởng',
        sentAt: DateTime(2026, 10, 11, 17),
        unread: true,
      ),
      AppNotification(
        id: 'v3',
        type: NotificationType.leaderReminder,
        title: 'Sổ báo ăn hôm nay chưa xác nhận',
        sentAt: DateTime(2026, 10, 12, 8, 45),
      ),
    ],
    AppRole.principal: [
      AppNotification(
        id: 'h1',
        type: NotificationType.rewardListUpdated,
        title: 'Phó HT Lê Văn Bình chuyển danh sách khen thưởng',
        sentAt: DateTime(2026, 10, 13, 8),
        tag: 'Cơ sở chính',
        unread: true,
      ),
      AppNotification(
        id: 'h2',
        type: NotificationType.leaderReminder,
        title: 'Lớp Chồi 2 quá hạn đánh giá tuần',
        sentAt: DateTime(2026, 10, 10, 9),
      ),
    ],
  };

  @override
  Future<List<AppNotification>> load(AppRole role) async => byRole[role]!;
}

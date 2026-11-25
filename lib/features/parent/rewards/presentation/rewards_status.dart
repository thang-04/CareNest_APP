import 'package:flutter/widgets.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/features/parent/rewards/domain/rewards.dart';

/// Nhãn và tông của trang Khen thưởng; tên phiếu theo loại phiếu BE (WEEKLY, MONTHLY).
abstract final class RewardsStatus {
  static const weeklyTicket = 'Bé ngoan';
  static const monthlyTicket = 'Bé ngoan toàn diện';

  /// Thứ bé đã nhận (cờ, phiếu, danh hiệu) cùng tông xanh lá; vàng chỉ dành cho "chờ duyệt".
  static const earned = AppStatusTone.green;

  static String flagDay(FlagDayStatus status) => switch (status) {
    FlagDayStatus.flagged => 'có cờ',
    FlagDayStatus.noFlag => 'không có cờ',
    FlagDayStatus.absent => 'nghỉ',
    FlagDayStatus.pending => 'chưa có',
  };

  static String weekTicket(WeekTicketStatus status) => switch (status) {
    WeekTicketStatus.issued => 'có phiếu $weeklyTicket',
    WeekTicketStatus.none => 'không có phiếu',
    WeekTicketStatus.ongoing => 'tuần đang diễn ra',
  };

  /// "24/05 – 28/05"
  static String days(DateTime from, DateTime to) =>
      '${DateLabels.dayMonth(from)} – ${DateLabels.dayMonth(to)}';

  /// "Cô Trần Thu Hà phát · 31/05/2027"
  static String issued(IssuedTicket ticket) =>
      '${ticket.issuedBy} phát · ${DateLabels.date(ticket.issuedAt)}';

  /// Tên danh hiệu theo danh sách BE (OBS-14).
  static IconData titleIcon(String title) {
    if (title == 'Cháu ngoan Bác Hồ') return AppIcons.star;
    if (title.startsWith('Hoàn thành')) return AppIcons.school;
    return AppIcons.trophy;
  }
}

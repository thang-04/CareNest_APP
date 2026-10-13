import 'package:carenest_app/features/activity_schedule/domain/activity_schedule.dart';

/// Lịch giả tuần 12–16/10 theo mockup T10; thứ Hai đang ở hoạt động Tạo hình (khớp Trang chủ GV).
class FakeActivityScheduleSource implements ActivityScheduleSource {
  const FakeActivityScheduleSource();

  static const _common = [
    ScheduleEntry(
      time: '07:00',
      title: 'Đón trẻ · Thể dục sáng',
      detail: 'Bài “Chim sẻ”',
    ),
  ];
  static const _tail = [
    ScheduleEntry(
      time: '10:30',
      title: 'Ăn trưa · Ngủ trưa',
      detail: 'Đến 14:00',
    ),
    ScheduleEntry(
      time: '14:15',
      title: 'Hoạt động chiều',
      detail: 'Ôn bài hát “Mùa thu”',
    ),
    ScheduleEntry(
      time: '15:30',
      title: 'Nêu gương · Trả trẻ',
      detail: 'Đánh giá cuối ngày',
    ),
  ];

  @override
  Future<WeekSchedule> loadWeek(String classId) async => WeekSchedule(
    weekStart: DateTime(2026, 10, 12),
    theme: 'Mùa thu của bé',
    days: {
      DateTime.monday: const [
        ..._common,
        ScheduleEntry(
          time: '08:00',
          title: 'Hoạt động học: Tạo hình',
          detail: 'Tô màu chiếc lá mùa thu · Đang diễn ra',
          isCurrent: true,
        ),
        ScheduleEntry(
          time: '09:00',
          title: 'Hoạt động ngoài trời',
          detail: 'Quan sát cây xanh sân trường',
        ),
        ScheduleEntry(
          time: '09:40',
          title: 'Hoạt động góc',
          detail: 'Góc nghệ thuật · góc xây dựng',
        ),
        ..._tail,
      ],
      DateTime.tuesday: const [
        ..._common,
        ScheduleEntry(
          time: '08:00',
          title: 'Hoạt động học: Âm nhạc',
          detail: 'Hát “Lá vàng rơi”',
        ),
        ScheduleEntry(
          time: '09:00',
          title: 'Hoạt động ngoài trời',
          detail: 'Nhặt lá làm tranh',
        ),
        ..._tail,
      ],
      DateTime.wednesday: const [
        ..._common,
        ScheduleEntry(
          time: '08:00',
          title: 'Hoạt động học: Làm quen toán',
          detail: 'Đếm số lá trong nhóm',
        ),
        ScheduleEntry(
          time: '09:00',
          title: 'Trò chơi vận động',
          detail: 'Mèo đuổi chuột',
        ),
        ..._tail,
      ],
      DateTime.thursday: const [
        ..._common,
        ScheduleEntry(
          time: '08:00',
          title: 'Hoạt động học: Văn học',
          detail: 'Truyện “Chiếc lá nhỏ”',
        ),
        ScheduleEntry(
          time: '09:00',
          title: 'Hoạt động góc',
          detail: 'Góc phân vai · bán hàng',
        ),
        ..._tail,
      ],
      DateTime.friday: const [
        ..._common,
        ScheduleEntry(
          time: '08:00',
          title: 'Hoạt động học: Khám phá',
          detail: 'Mùa thu có gì?',
        ),
        ScheduleEntry(
          time: '09:00',
          title: 'Sinh hoạt cuối tuần',
          detail: 'Bình bầu bé ngoan',
        ),
        ..._tail,
      ],
    },
  );
}

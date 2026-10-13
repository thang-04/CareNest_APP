/// Định dạng ngày tiếng Việt cho UI, không cần thêm thư viện intl.
abstract final class DateLabels {
  static const _weekdays = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật',
  ];

  static const _weekdaysShort = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  /// Nhãn cột lịch, thứ Hai trước.
  static const weekdayHeaders = _weekdaysShort;

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// 12/10/2026
  static String date(DateTime value) =>
      '${_two(value.day)}/${_two(value.month)}/${value.year}';

  /// 12/10
  static String dayMonth(DateTime value) =>
      '${_two(value.day)}/${_two(value.month)}';

  /// Thứ Hai, 12/10/2026
  static String weekdayDate(DateTime value) =>
      '${_weekdays[value.weekday - 1]}, ${date(value)}';

  /// Thứ Hai, 12/10
  static String weekdayDayMonth(DateTime value) =>
      '${_weekdays[value.weekday - 1]}, ${dayMonth(value)}';

  /// 07:42 — giờ có số 0 đầu, dùng khi xếp cột giờ thẳng hàng
  static String time24(DateTime value) =>
      '${_two(value.hour)}:${_two(value.minute)}';

  /// T2 … CN
  static String weekdayShort(DateTime value) =>
      _weekdaysShort[value.weekday - 1];

  /// 7:42
  static String time(DateTime value) => '${value.hour}:${_two(value.minute)}';

  /// "13/10 – 14/10/2026", hoặc "02/10/2026" khi nghỉ một ngày.
  static String range(DateTime from, DateTime to) {
    if (from.year == to.year && from.month == to.month && from.day == to.day) {
      return date(from);
    }
    return '${dayMonth(from)} – ${date(to)}';
  }

  /// Tháng 10/2026
  static String month(DateTime value) => 'Tháng ${value.month}/${value.year}';
}

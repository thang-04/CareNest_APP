/// Ngày theo định dạng BE nhận ở query/body (`LocalDate` ISO): `2026-11-25`.
String apiDate(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

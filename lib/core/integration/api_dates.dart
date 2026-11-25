import 'package:carenest_app/core/integration/mobile_api.dart';

/// Ngày theo định dạng BE nhận ở query/body (`LocalDate` ISO): `2026-11-25`.
String apiDate(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// Thứ Hai của tuần chứa [day] (0 giờ).
DateTime mondayOf(DateTime day) =>
    DateTime(day.year, day.month, day.day - (day.weekday - DateTime.monday));

/// API phụ huynh theo khoảng ngày từ chối khoảng lấn ra ngoài năm học (400/4109, ATT-15) mà App
/// không biết ngày khai giảng ⇒ thử lần lượt các ngày bắt đầu [starts] (xa trước, gần sau).
Future<T> loadFromNearestStart<T>(
  List<DateTime> starts,
  Future<T> Function(DateTime from) load,
) async {
  for (final (i, from) in starts.indexed) {
    try {
      return await load(from);
    } on ApiFailure catch (failure) {
      final outsideYear =
          failure.status == 400 && '${failure.errorCode}' == '4109';
      if (!outsideYear || i == starts.length - 1) rethrow;
    }
  }
  throw ArgumentError.value(starts, 'starts', 'rỗng');
}

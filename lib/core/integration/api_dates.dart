import 'package:carenest_app/core/integration/mobile_api.dart';

/// Ngày theo định dạng BE nhận ở query/body (`LocalDate` ISO): `2026-11-25`.
String apiDate(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// Thứ Hai của tuần chứa [day] (0 giờ).
DateTime mondayOf(DateTime day) =>
    DateTime(day.year, day.month, day.day - (day.weekday - DateTime.monday));

/// Ngày bắt đầu cho trang xem lại gần đây (Đánh giá, Khen thưởng), xa trước gần sau: 8 tuần gần nhất
/// lùi tới ngày 1 tháng trước (giữ phiếu tháng trước — luôn ≤ 62 ngày tới hôm nay, giới hạn BE), rồi
/// ngày 1 tháng này, thứ Hai tuần này, hôm nay — dùng khi BE trả 4109 đầu năm học.
List<DateTime> recentStarts(DateTime today) {
  final monday = mondayOf(today);
  final starts = {
    DateTime(monday.year, monday.month, monday.day - 49),
    DateTime(today.year, today.month - 1),
    DateTime(today.year, today.month),
    monday,
    today,
  }.toList()..sort();
  return starts;
}

/// API phụ huynh theo khoảng ngày từ chối khoảng lấn ra ngoài năm học (400/4109, ATT-15) mà App
/// không biết ngày khai giảng ⇒ thử lần lượt các ngày bắt đầu [starts] (xa trước, gần sau).
/// Mọi khoảng đều bị từ chối (hè: lớp năm cũ còn mở tới khi kích hoạt năm mới) ⇒ [outsideYear]
/// nếu có (màn hiện rỗng thay vì lỗi mạng), không thì ném lỗi BE.
Future<T> loadFromNearestStart<T>(
  List<DateTime> starts,
  Future<T> Function(DateTime from) load, {
  T Function()? outsideYear,
}) async {
  for (final (i, from) in starts.indexed) {
    try {
      return await load(from);
    } on ApiFailure catch (failure) {
      final rejected =
          failure.status == 400 && '${failure.errorCode}' == '4109';
      if (!rejected) rethrow;
      if (i == starts.length - 1) {
        if (outsideYear == null) rethrow;
        return outsideYear();
      }
    }
  }
  throw ArgumentError.value(starts, 'starts', 'rỗng');
}

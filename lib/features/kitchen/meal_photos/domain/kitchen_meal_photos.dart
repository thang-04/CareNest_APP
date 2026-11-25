import 'package:flutter/foundation.dart';

/// Giờ đăng ảnh của một bữa (NUT-16): Hiệu trưởng đặt, chung toàn trường; ngoài giờ BE chặn.
/// BE chỉ trả giờ mở/đóng; trạng thái theo giờ điện thoại chỉ để hiển thị (user 25/11).
enum PhotoWindow { notSet, upcoming, open, closed }

/// Trạng thái ảnh mẫu của một bữa, suy từ số ảnh và giờ đăng. Hết giờ mà chưa có ảnh
/// chỉ báo đỏ, không đăng bù (user chốt 18/11).
enum MealPhotoStatus { done, needed, upcoming, missed, noWindow }

/// Một ảnh mẫu đã đăng. [bytes] chỉ có với ảnh vừa chụp trên máy (nguồn giả giữ trong bộ nhớ);
/// ảnh BE tải bằng [KitchenPhotoSource.loadPhoto] (API có auth, không lưu ra máy).
@immutable
class SamplePhoto {
  const SamplePhoto({required this.id, required this.postedAt, this.bytes});

  final String id;

  /// Giờ đăng, "10:41"
  final String postedAt;
  final Uint8List? bytes;
}

/// Một bữa hôm nay của điểm trường. BE giữ 1 ảnh mỗi điểm trường × ngày × bữa, chụp lại là thay
/// ảnh cũ (NUT-16, user 25/11) ⇒ [photos] có 0 hoặc 1 ảnh.
@immutable
class SampleMeal {
  const SampleMeal({
    required this.id,
    required this.name,
    required this.window,
    this.opensAt,
    this.closesAt,
    this.minutesLeft,
    this.photos = const [],
  });

  /// Buổi theo BE MealSession: MORNING, LUNCH, AFTERNOON
  final String id;

  /// Nhãn buổi như web: "Bữa phụ sáng", "Bữa trưa", "Bữa chiều"
  final String name;
  final PhotoWindow window;

  /// Giờ mở, giờ đóng đăng ảnh, "10:30"; null khi Hiệu trưởng chưa đặt giờ
  final String? opensAt;
  final String? closesAt;

  /// Số phút còn lại khi đang mở giờ, theo giờ máy chủ
  final int? minutesLeft;
  final List<SamplePhoto> photos;

  /// "10:30–11:30"
  String get windowLabel => '${opensAt ?? ''}–${closesAt ?? ''}';

  MealPhotoStatus get status => photos.isNotEmpty
      ? MealPhotoStatus.done
      : switch (window) {
          PhotoWindow.notSet => MealPhotoStatus.noWindow,
          PhotoWindow.upcoming => MealPhotoStatus.upcoming,
          PhotoWindow.open => MealPhotoStatus.needed,
          PhotoWindow.closed => MealPhotoStatus.missed,
        };
}

/// Ảnh mẫu hôm nay của bếp một điểm trường (BE `/nutrition/meal-photos`, `/meal-photo-windows`).
@immutable
class KitchenPhotoDay {
  const KitchenPhotoDay({
    required this.date,
    required this.campusLabel,
    required this.meals,
    this.isDayOff = false,
  });

  final DateTime date;

  /// "Cơ sở chính"
  final String campusLabel;

  /// Các bữa điểm trường ăn hôm nay, theo thứ tự phục vụ
  final List<SampleMeal> meals;

  int get doneMeals =>
      meals.where((meal) => meal.status == MealPhotoStatus.done).length;
  final bool isDayOff;
}

abstract interface class KitchenPhotoSource {
  Future<KitchenPhotoDay> loadToday();

  /// Đăng ảnh [bytes] vừa chụp cho bữa [mealId] (thay ảnh cũ nếu có); trả ngày đã cập nhật.
  Future<KitchenPhotoDay> addPhoto({
    required String mealId,
    required Uint8List bytes,
  });

  /// Nội dung ảnh đã đăng [photoId] (API có auth).
  Future<Uint8List> loadPhoto(String photoId);
}

/// Camera chụp một ảnh mẫu; trả null khi bếp huỷ, ném lỗi khi không mở được camera.
abstract interface class SamplePhotoCamera {
  Future<Uint8List?> takePhoto();
}

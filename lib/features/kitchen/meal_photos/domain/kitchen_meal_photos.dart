import 'package:flutter/foundation.dart';

/// Giờ đăng ảnh của một bữa (NUT-16): Hiệu trưởng đặt, chung toàn trường; ngoài giờ BE chặn.
/// Nguồn dữ liệu trả theo giờ máy chủ, App không tự tính theo giờ máy.
enum PhotoWindow { notSet, upcoming, open, closed }

/// Trạng thái ảnh mẫu của một bữa, suy từ số ảnh và giờ đăng. Hết giờ mà chưa có ảnh
/// chỉ báo đỏ, không đăng bù (user chốt 18/11).
enum MealPhotoStatus { done, needed, upcoming, missed, noWindow }

/// Một ảnh mẫu đã đăng. [bytes] chỉ có với ảnh vừa chụp trên máy (nguồn giả giữ trong bộ nhớ);
/// ảnh từ BE tải qua URL có auth khi có API.
@immutable
class SamplePhoto {
  const SamplePhoto({required this.id, required this.postedAt, this.bytes});

  final String id;

  /// Giờ đăng, "10:41"
  final String postedAt;
  final Uint8List? bytes;
}

/// Một bữa của một nhóm tuổi hôm nay. Mỗi bữa cần ít nhất 1 ảnh, chụp bao nhiêu cũng được
/// (user 17/11).
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

/// Các bữa một nhóm tuổi ăn trong ngày, theo cấu hình nhóm tuổi của Hiệu trưởng
/// (BE `age_groups.meal_sessions`, user chốt 18/11).
@immutable
class AgeGroupMeals {
  const AgeGroupMeals({
    required this.id,
    required this.name,
    required this.ageRange,
    required this.meals,
  });

  final String id;

  /// "Mẫu giáo nhỡ"
  final String name;

  /// "4–5 tuổi"
  final String ageRange;
  final List<SampleMeal> meals;

  int get doneMeals =>
      meals.where((meal) => meal.status == MealPhotoStatus.done).length;
}

/// Ảnh mẫu hôm nay của bếp một điểm trường, theo nhóm tuổi (BE chưa có API theo nhóm tuổi).
@immutable
class KitchenPhotoDay {
  const KitchenPhotoDay({
    required this.date,
    required this.campusLabel,
    required this.groups,
    this.isDayOff = false,
  });

  final DateTime date;

  /// "Cơ sở chính"
  final String campusLabel;
  final List<AgeGroupMeals> groups;
  final bool isDayOff;
}

abstract interface class KitchenPhotoSource {
  Future<KitchenPhotoDay> loadToday();

  /// Đăng ảnh [bytes] vừa chụp cho bữa [mealId] của nhóm [groupId]; trả ngày đã cập nhật.
  Future<KitchenPhotoDay> addPhoto({
    required String groupId,
    required String mealId,
    required Uint8List bytes,
  });
}

/// Camera chụp một ảnh mẫu; trả null khi bếp huỷ, ném lỗi khi không mở được camera.
abstract interface class SamplePhotoCamera {
  Future<Uint8List?> takePhoto();
}

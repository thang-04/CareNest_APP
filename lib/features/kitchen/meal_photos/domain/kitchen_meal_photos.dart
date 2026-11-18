import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/kitchen/kitchen_day/domain/kitchen_day.dart';

/// Khung giờ đăng ảnh của một bữa (NUT-16: HT cấu hình, chung toàn trường; ngoài khung BE chặn).
/// Nguồn dữ liệu trả (`/meal-photo-windows`), App không tự tính theo giờ máy.
enum PhotoWindow { upcoming, open, closed }

/// Ảnh mẫu đã đăng — `MealPhotoResponse`. [bytes] chỉ có với ảnh vừa chụp trên máy
/// (nguồn giả giữ trong bộ nhớ); ảnh từ BE tải qua `/meal-photos/{id}/content` có auth.
@immutable
class SamplePhoto {
  const SamplePhoto({required this.id, required this.uploadedAt, this.bytes});

  final String id;
  final DateTime uploadedAt;
  final Uint8List? bytes;
}

/// Một bữa hôm nay của bếp một cơ sở: tối đa 1 ảnh (BE: cơ sở + ngày + bữa,
/// đăng lại thì thay ảnh cũ — user chốt 18/11 theo BE).
@immutable
class SampleMeal {
  const SampleMeal({
    required this.session,
    required this.windowLabel,
    required this.window,
    this.photo,
  });

  final MealSession session;

  /// Khung giờ đăng, "10:30–11:30"
  final String windowLabel;
  final PhotoWindow window;
  final SamplePhoto? photo;
}

@immutable
class KitchenPhotoDay {
  const KitchenPhotoDay({
    required this.date,
    required this.kitchenLabel,
    required this.meals,
  });

  final DateTime date;

  /// "Bếp cơ sở chính"
  final String kitchenLabel;
  final List<SampleMeal> meals;
}

abstract interface class KitchenPhotoSource {
  Future<KitchenPhotoDay> loadToday();

  /// `POST /nutrition/meal-photos` (multipart `file`, `session`); trả ngày đã cập nhật.
  Future<KitchenPhotoDay> upload({
    required MealSession session,
    required Uint8List bytes,
  });
}

/// Camera chụp một ảnh mẫu; trả null khi bếp huỷ, ném lỗi khi không mở được camera.
abstract interface class SamplePhotoCamera {
  Future<Uint8List?> takePhoto();
}

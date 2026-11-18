import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/kitchen/kitchen_day/domain/kitchen_day.dart';

/// `FoodSampleStatus`: bếp ghi (RECORDED), PHT dinh dưỡng duyệt (APPROVED) — NUT-21.
enum FoodSampleStatus {
  recorded('Chờ duyệt'),
  approved('Đã duyệt');

  const FoodSampleStatus(this.label);

  final String label;
}

/// `FoodSampleDisposalStatus`: NONE / RECORDED (bếp ghi hủy) / APPROVED.
enum FoodSampleDisposalStatus {
  none('Chưa hủy'),
  recorded('Chờ duyệt hủy'),
  approved('Đã hủy');

  const FoodSampleDisposalStatus(this.label);

  final String label;
}

/// Bản lưu mẫu một bữa — khớp `FoodSampleResponse` (bỏ field bếp không cần xem).
@immutable
class FoodSample {
  const FoodSample({
    required this.id,
    required this.date,
    required this.session,
    required this.sampledAt,
    required this.dishes,
    required this.status,
    required this.disposableFrom,
    required this.disposalStatus,
    this.note,
    this.disposedAt,
  });

  final int id;
  final DateTime date;
  final MealSession session;
  final DateTime sampledAt;
  final List<MenuDish> dishes;
  final String? note;
  final FoodSampleStatus status;

  /// BE tính = giờ lấy mẫu + 24 giờ.
  final DateTime disposableFrom;
  final DateTime? disposedAt;
  final FoodSampleDisposalStatus disposalStatus;

  /// Như `FoodSample.isEditable()` BE: đã duyệt hoặc đã ghi hủy thì là chứng từ, không sửa.
  bool get editable =>
      status == FoodSampleStatus.recorded &&
      disposalStatus == FoodSampleDisposalStatus.none;

  bool get awaitingDisposal => disposalStatus == FoodSampleDisposalStatus.none;

  /// Đủ 24 giờ mới được ghi hủy; BE kiểm tra lại.
  bool canDisposeAt(DateTime now) =>
      awaitingDisposal && !now.isBefore(disposableFrom);
}

/// Thân `FoodSampleRequest` bếp gửi khi ghi/sửa lưu mẫu.
@immutable
class FoodSampleDraft {
  const FoodSampleDraft({
    required this.date,
    required this.session,
    required this.dishIds,
    required this.sampledAt,
    this.note,
  });

  final DateTime date;
  final MealSession session;
  final List<int> dishIds;
  final DateTime sampledAt;
  final String? note;
}

abstract interface class FoodSampleSource {
  /// Bản lưu mẫu từ [from] tới [to] (`GET /nutrition/food-samples`).
  Future<List<FoodSample>> loadSamples(DateTime from, DateTime to);

  Future<FoodSample> create(FoodSampleDraft draft);

  Future<FoodSample> update(int id, FoodSampleDraft draft);

  /// `POST /food-samples/{id}/dispose`.
  Future<FoodSample> dispose(int id, DateTime disposedAt);
}

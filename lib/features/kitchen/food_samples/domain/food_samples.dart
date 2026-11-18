import 'package:flutter/foundation.dart';

/// Trạng thái bản lưu mẫu theo BE `FoodSampleStatus` (NUT-21): bếp ghi, PHT duyệt.
enum SampleStatus { recorded, approved }

/// Trạng thái hủy mẫu theo BE `FoodSampleDisposalStatus`: chưa ghi hủy, bếp đã ghi, PHT đã duyệt.
enum SampleDisposalStatus { none, recorded, approved }

/// Một món lưu mẫu kèm ghi chú Mẫu 5 (khối lượng, dụng cụ chứa, nhiệt độ); chuỗi rỗng khi chưa ghi.
@immutable
class SampleDish {
  const SampleDish({
    required this.id,
    required this.name,
    this.blockLabel,
    this.weight = '',
    this.container = '',
    this.temperature = '',
  });

  final int id;

  /// "Cá basa sốt cà chua"
  final String name;

  /// "Nhà trẻ" khi món chỉ một khối ăn (BE `MenuBlock`, NUT-13)
  final String? blockLabel;
  final String weight;
  final String container;
  final String temperature;

  bool get hasNote =>
      weight.isNotEmpty || container.isNotEmpty || temperature.isNotEmpty;
}

/// Bản lưu mẫu một bữa (BE `FoodSampleResponse`).
@immutable
class FoodSample {
  const FoodSample({
    required this.id,
    required this.date,
    required this.session,
    required this.sessionLabel,
    required this.sampledAt,
    required this.dishes,
    required this.status,
    required this.disposableFrom,
    this.disposalStatus = SampleDisposalStatus.none,
    this.disposableNow = false,
  });

  final int id;
  final DateTime date;

  /// Buổi theo BE MealSession: MORNING, LUNCH, AFTERNOON
  final String session;

  /// "Bữa trưa"
  final String sessionLabel;
  final DateTime sampledAt;
  final List<SampleDish> dishes;
  final SampleStatus status;

  /// Lúc lấy mẫu + 24 giờ, BE trả
  final DateTime disposableFrom;
  final SampleDisposalStatus disposalStatus;

  /// Đã tới giờ hủy theo giờ máy chủ; nguồn dữ liệu trả, App không so giờ máy
  final bool disposableNow;

  /// Như BE `FoodSample.isEditable`: chưa duyệt và chưa ghi hủy
  bool get editable =>
      status == SampleStatus.recorded &&
      disposalStatus == SampleDisposalStatus.none;
}

/// Một bữa hôm nay trong sổ lưu mẫu: món theo thực đơn đã công bố và bản đã ghi (nếu có).
@immutable
class SampleSession {
  const SampleSession({
    required this.session,
    required this.label,
    required this.dishes,
    this.sample,
    this.upcoming = false,
  });

  final String session;
  final String label;

  /// Món của bữa theo thực đơn đã công bố; rỗng khi thực đơn chưa công bố
  final List<SampleDish> dishes;
  final FoodSample? sample;

  /// Bữa chưa tới theo giờ máy chủ: chưa có món đã nấu để lưu mẫu
  final bool upcoming;
}

@immutable
class FoodSampleDay {
  const FoodSampleDay({
    required this.date,
    required this.campusLabel,
    required this.sessions,
    required this.toDispose,
    this.isDayOff = false,
  });

  final DateTime date;

  /// "Cơ sở chính"
  final String campusLabel;
  final List<SampleSession> sessions;

  /// Mẫu các ngày trước chưa xong hủy (chưa ghi hủy hoặc chờ PHT duyệt hủy)
  final List<FoodSample> toDispose;
  final bool isDayOff;
}

/// Ghi chú Mẫu 5 của một món khi lưu (BE `FoodSampleRequest.DishDetailInput`).
@immutable
class DishNoteInput {
  const DishNoteInput({
    required this.dishId,
    required this.weight,
    required this.container,
    required this.temperature,
  });

  final int dishId;
  final String weight;
  final String container;
  final String temperature;
}

abstract interface class FoodSampleSource {
  Future<FoodSampleDay> loadToday();

  /// Ghi mới ([sampleId] null, giờ lấy mẫu = lúc ghi) hoặc sửa bản đã ghi; trả ngày đã cập nhật.
  Future<FoodSampleDay> saveSample({
    required String session,
    int? sampleId,
    required List<DishNoteInput> dishes,
  });

  /// Ghi hủy mẫu lúc bấm (BE `/food-samples/{id}/dispose`); trả ngày đã cập nhật.
  Future<FoodSampleDay> recordDisposal(int sampleId);
}

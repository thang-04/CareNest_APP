import 'package:flutter/foundation.dart';

enum KitchenTaskKind { menu, mealCounts, quantities, receipt, cooking }

/// Mức nhấn badge: cần làm / có thay đổi / đã xong / thông tin.
enum KitchenBadgeLevel { todo, changed, done, info }

@immutable
class KitchenTask {
  const KitchenTask({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.level,
    this.highlighted = false,
  });

  final KitchenTaskKind kind;
  final String title;
  final String subtitle;
  final String badge;
  final KitchenBadgeLevel level;
  final bool highlighted;
}

/// Trang chủ bếp — mockup K01. Số suất chỉ khi đã xác nhận (NUT-02), BE trả.
@immutable
class KitchenToday {
  const KitchenToday({
    required this.staffName,
    required this.kitchenLabel,
    required this.date,
    required this.tasks,
    this.mealLabel,
    this.confirmedAt,
    this.total,
    this.regular,
    this.alternative,
  });

  /// "Nguyễn Thị Mai"
  final String staffName;

  /// "Bếp cơ sở chính" — bếp theo campus hay trung tâm còn PENDING (P-06).
  final String kitchenLabel;
  final DateTime date;
  final String? mealLabel;
  final DateTime? confirmedAt;
  final int? total;
  final int? regular;
  final int? alternative;
  final List<KitchenTask> tasks;
}

abstract interface class KitchenHomeSource {
  Future<KitchenToday> loadToday();
}

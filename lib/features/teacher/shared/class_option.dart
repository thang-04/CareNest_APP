import 'package:flutter/foundation.dart';

/// Lớp giáo viên chọn được trên thanh Lớp · Ngày (cùng `ClassDateBar` của Web).
/// `readOnly` = lớp xem lịch sử (BE `historicalReadOnly`): không nhập được.
@immutable
class ClassOption {
  const ClassOption({
    required this.id,
    required this.name,
    this.readOnly = false,
  });

  final String id;
  final String name;
  final bool readOnly;
}

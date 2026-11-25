import 'package:flutter/foundation.dart';

/// Một cơ sở của trường và Phó HT được phân công (AUTH-02; cố định hay luân phiên P-14 PENDING).
/// Chỉ xem; thêm cơ sở, đổi phân công làm trên Web.
@immutable
class Campus {
  const Campus({
    required this.id,
    required this.name,
    required this.address,
    required this.classCount,
    required this.childCount,
    required this.vicePrincipal,
    required this.scopes,
  });

  final String id;

  /// "Cơ sở chính – Thượng Hồng"
  final String name;
  final String address;
  final int classCount;
  final int childCount;

  /// "Thầy Lê Văn Bình"
  final String vicePrincipal;

  /// Mảng Phó HT phụ trách BE trả, vd. "Trẻ & lớp", "Bán trú".
  final List<String> scopes;
}

abstract interface class CampusSource {
  /// Năm học đang xem, vd. "2026–2027".
  String get schoolYear;
  Future<List<Campus>> loadCampuses();
}

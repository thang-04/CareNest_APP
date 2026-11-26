import 'package:carenest_app/core/integration/api_dates.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/teacher/pickup/domain/pickup.dart';

/// Đón trẻ từ BE (PCK-01..04): bảng đón `GET /classes/{classId}/pickups`, một bé
/// `GET /pickups/children/{childId}`, ghi `POST /pickups`.
class LivePickupSource implements PickupSource {
  LivePickupSource(this._api);

  final MobileApi _api;

  /// [date] null ⇒ không gửi `date`: BE lấy "hôm nay" theo giờ trường, không phụ thuộc múi giờ máy.
  @override
  Future<PickupBoard> loadBoard(String classId, {DateTime? date}) async {
    final query = date == null ? '' : '?date=${apiDate(date)}';
    final data =
        await _api.json('GET', '/classes/$classId/pickups$query') as Map;
    return PickupBoard(
      className: data['className']?.toString() ?? '',
      date: _day(data['date']) ?? date ?? DateTime.now(),
      today: _day(data['today']) ?? date ?? DateTime.now(),
      rows: [
        for (final row in (data['rows'] as List? ?? const []).whereType<Map>())
          _row(row),
      ],
    );
  }

  @override
  Future<List<PickupRecord>> loadResults({DateTime? date}) async {
    final query = date == null ? '' : '?date=${apiDate(date)}';
    final data = await _api.json('GET', '/pickups$query') as List? ?? const [];
    return [for (final item in data.whereType<Map>()) _record(item)];
  }

  static DateTime? _day(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  @override
  Future<PickupChild> loadChild(String childId) async {
    final data = await _api.json('GET', '/pickups/children/$childId') as Map;
    return PickupChild(
      row: _row(data['row'] as Map? ?? const {}),
      className: data['className']?.toString() ?? '',
      guardians: [
        for (final g
            in (data['guardians'] as List? ?? const []).whereType<Map>())
          PickupGuardian(
            position: (g['position'] as num?)?.toInt() ?? 0,
            fullName: g['fullName']?.toString() ?? '',
            relationship:
                _relation(g['relationship']) ?? GuardianRelationship.other,
            phone: g['phone']?.toString() ?? '',
            photoUrl: g['photoUrl']?.toString(),
          ),
      ],
    );
  }

  /// POST không tự thử lại: lỗi mạng ⇒ GV tải lại bảng đón rồi quyết định (tránh ghi trùng).
  @override
  Future<void> record(PickupRequest request) async {
    await _api.json(
      'POST',
      '/pickups',
      body: {
        'childId': int.tryParse(request.childId) ?? request.childId,
        'verification': request.verification.code,
        'guardianPosition': ?request.guardianPosition,
        'handoverTime': ?request.handoverTime,
        'note': ?request.note,
      },
    );
  }

  static PickupRow _row(Map<Object?, Object?> row) {
    final child = row['child'] as Map? ?? const {};
    final pickup = row['pickup'] as Map?;
    return PickupRow(
      childId: '${child['id']}',
      fullName: child['fullName']?.toString() ?? '',
      status: switch (row['status']) {
        'PICKED_UP' => PickupStatus.pickedUp,
        'ABSENT' => PickupStatus.absent,
        'UNMARKED' => PickupStatus.unmarked,
        _ => PickupStatus.waiting,
      },
      code: child['code']?.toString() ?? '',
      pickup: pickup == null ? null : _record(pickup),
      attempts: [
        for (final a in (row['attempts'] as List? ?? const []).whereType<Map>())
          _record(a),
      ],
    );
  }

  static PickupRecord _record(Map<Object?, Object?> pickup) => PickupRecord(
    verification: PickupVerification.values.firstWhere(
      (v) => v.code == pickup['verification'],
      orElse: () => PickupVerification.phoneConfirmed,
    ),
    guardianPosition: (pickup['guardianPosition'] as num?)?.toInt(),
    pickupPersonName: pickup['pickupPersonName']?.toString(),
    pickupPersonRelationship: _relation(pickup['pickupPersonRelationship']),
    handedOverAt: switch (pickup['handedOverAt']) {
      final String at => DateTime.parse(at).toLocal(),
      _ => null,
    },
    note: pickup['note']?.toString(),
    childName: pickup['childName']?.toString(),
    className: pickup['className']?.toString(),
    recordedAt: switch (pickup['recordedAt']) {
      final String at => DateTime.parse(at).toLocal(),
      _ => null,
    },
  );

  static GuardianRelationship? _relation(Object? code) {
    for (final value in GuardianRelationship.values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

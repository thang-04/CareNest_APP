import 'package:flutter/material.dart' show DateUtils;

import 'package:carenest_app/core/integration/api_dates.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/kitchen/food_samples/domain/food_samples.dart';
import 'package:carenest_app/features/kitchen/shared/kitchen_day_api.dart';

/// Sổ lưu mẫu từ BE (NUT-21): món của bữa = thực đơn đã công bố `/nutrition/kitchen/day.menu`; bản đã
/// ghi = `GET /nutrition/food-samples` 30 ngày gần nhất (BE ≤ 93 ngày). Ghi `POST`, sửa `PUT`, hủy
/// `POST /{id}/dispose`; BE kiểm hôm nay, khóa, mốc hủy và trả lỗi ⇒ App hiện câu BE.
class LiveFoodSampleSource implements FoodSampleSource {
  LiveFoodSampleSource(this._api, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final MobileApi _api;
  final DateTime Function() _clock;

  /// Thực đơn hôm nay theo bữa, giữ cho lần ghi (dishIds = mọi món của bữa).
  final Map<String, List<SampleDish>> _menu = {};
  DateTime? _date;

  @override
  Future<FoodSampleDay> loadToday() async {
    final data = await KitchenDayData.load(_api);
    final date = data.date;
    _date = date;
    final from = DateTime(date.year, date.month, date.day - 30);
    final samples = [
      for (final item in KitchenDayData.maps(
        await _api.json(
          'GET',
          '/nutrition/food-samples?from=${apiDate(from)}&to=${apiDate(date)}',
        ),
      ))
        _sample(item),
    ];
    _menu
      ..clear()
      ..addAll(_menuOf(data));
    final today = {
      for (final sample in samples)
        if (DateUtils.isSameDay(sample.date, date)) sample.session: sample,
    };
    return FoodSampleDay(
      date: date,
      // BE chưa trả tên điểm trường cho bếp ⇒ ẩn
      campusLabel: '',
      isDayOff: data.dayOff,
      sessions: [
        for (final MapEntry(key: session, value: dishes) in _menu.entries)
          SampleSession(
            session: session,
            label: kitchenSessionLabels[session] ?? '',
            dishes: dishes,
            sample: today[session],
          ),
      ],
      // Mẫu ngày trước chưa xong hủy: chưa ghi hủy hoặc chờ PHT duyệt hủy
      toDispose: [
        for (final sample in samples)
          if (sample.date.isBefore(date) &&
              sample.disposalStatus != SampleDisposalStatus.approved)
            sample,
      ],
    );
  }

  @override
  Future<FoodSampleDay> saveSample({
    required String session,
    int? sampleId,
    required List<DishNoteInput> dishes,
  }) async {
    final date = _date ?? (await KitchenDayData.load(_api)).date;
    final body = {
      'date': apiDate(date),
      'session': session,
      'dishIds': [for (final dish in _menu[session] ?? const []) dish.id],
      'dishDetails': [
        for (final note in dishes)
          {
            'dishId': note.dishId,
            'weight': note.weight,
            'container': note.container,
            'temperature': note.temperature,
          },
      ],
    };
    if (sampleId == null) {
      await _api.json('POST', '/nutrition/food-samples', body: body);
    } else {
      await _api.json('PUT', '/nutrition/food-samples/$sampleId', body: body);
    }
    return loadToday();
  }

  @override
  Future<FoodSampleDay> recordDisposal(int sampleId) async {
    await _api.json(
      'POST',
      '/nutrition/food-samples/$sampleId/dispose',
      body: const <String, Object?>{},
    );
    return loadToday();
  }

  /// Món theo bữa; món chỉ một khối ăn ghi nhãn khối (NUT-13).
  static Map<String, List<SampleDish>> _menuOf(KitchenDayData data) {
    final blocksOf = <int, Set<String>>{};
    final byId = <int, Map<Object?, Object?>>{};
    final sessions = <String, List<int>>{};
    for (final menu in KitchenDayData.maps(data.day['menu'])) {
      final session = '${menu['session']}';
      for (final dish in KitchenDayData.maps(menu['dishes'])) {
        final id = KitchenDayData.count(dish['id']);
        byId[id] = dish;
        (blocksOf[id] ??= {}).add('${menu['menuBlock']}');
        final ids = sessions[session] ??= [];
        if (!ids.contains(id)) ids.add(id);
      }
    }
    final ordered = kitchenSessionOrder.where(sessions.containsKey);
    return {
      for (final session in ordered)
        session: [
          for (final id in sessions[session]!)
            SampleDish(
              id: id,
              name: '${byId[id]?['name'] ?? ''}',
              blockLabel: blocksOf[id]!.length == 1
                  ? kitchenBlockLabels[blocksOf[id]!.single]
                  : null,
            ),
        ],
    };
  }

  FoodSample _sample(Map<Object?, Object?> item) {
    final disposableFrom = DateTime.parse('${item['disposableFrom']}');
    final disposal = switch (item['disposalStatus']) {
      'RECORDED' => SampleDisposalStatus.recorded,
      'APPROVED' => SampleDisposalStatus.approved,
      _ => SampleDisposalStatus.none,
    };
    return FoodSample(
      id: KitchenDayData.count(item['id']),
      date: DateTime.parse('${item['date']}'),
      session: '${item['session']}',
      sessionLabel: kitchenSessionLabels['${item['session']}'] ?? '',
      sampledAt: DateTime.parse('${item['sampledAt']}').toLocal(),
      dishes: [
        for (final dish in KitchenDayData.maps(item['dishes']))
          SampleDish(
            id: KitchenDayData.count(dish['id']),
            name: '${dish['name'] ?? ''}',
            weight: '${dish['weight'] ?? ''}',
            container: '${dish['container'] ?? ''}',
            temperature: '${dish['temperature'] ?? ''}',
          ),
      ],
      status: item['status'] == 'APPROVED'
          ? SampleStatus.approved
          : SampleStatus.recorded,
      disposableFrom: disposableFrom.toLocal(),
      disposalStatus: disposal,
      // Chỉ để hiển thị nút "Ghi hủy" (user 25/11: giờ máy chỉ để hiển thị); BE chặn hủy sớm (6062)
      disposableNow: !_clock().isBefore(disposableFrom),
      editable: item['editable'] == true,
    );
  }
}

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/kitchen/food_quantities/domain/food_quantities.dart';
import 'package:carenest_app/features/kitchen/shared/kitchen_day_api.dart';

/// Lượng thực phẩm cả ngày từ BE `/nutrition/kitchen/day.foods` (NUT-07, đã cộng thải bỏ). App chỉ
/// đổi sang đơn vị mua khi BE trả `purchaseUnit` + `purchaseUnitSize` (vd. 10500 g ⇒ "10,5 kg").
class LiveFoodQuantitySource implements FoodQuantitySource {
  LiveFoodQuantitySource(this._api);

  final MobileApi _api;

  @override
  Future<FoodNeedDay?> loadDay() async {
    final data = await KitchenDayData.load(_api);
    final needs = [
      for (final item in KitchenDayData.maps(data.day['foods']))
        FoodNeed(
          food: '${(item['food'] as Map?)?['name'] ?? ''}',
          amount: _amount(item),
          storage: item['storage'] == 'DRY'
              ? FoodStorage.dry
              : FoodStorage.fresh,
        ),
    ];
    // Rỗng: ngày nghỉ, thực đơn chưa công bố hoặc chưa có suất đã xác nhận
    if (needs.isEmpty) return null;
    return FoodNeedDay(date: data.date, needs: needs);
  }

  static String _amount(Map<Object?, Object?> item) {
    final food = item['food'] as Map? ?? const {};
    final quantity = item['quantity'];
    if (quantity is! num) return '';
    final size = food['purchaseUnitSize'];
    final purchaseUnit = food['purchaseUnit'];
    if (purchaseUnit is String && size is num && size > 0) {
      return '${_number(quantity / size)} $purchaseUnit';
    }
    return '${_number(quantity)} ${food['unit'] ?? ''}'.trim();
  }

  /// Tối đa 2 chữ số thập phân, dấu phẩy thập phân, bỏ số 0 thừa: 10.50 ⇒ "10,5".
  static String _number(num value) {
    var text = value.toStringAsFixed(2);
    text = text.replaceFirst(RegExp(r'\.?0+$'), '');
    return text.replaceAll('.', ',');
  }
}

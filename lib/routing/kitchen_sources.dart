import 'package:carenest_app/features/kitchen/food_quantities/domain/food_quantities.dart';
import 'package:carenest_app/features/kitchen/food_samples/domain/food_samples.dart';
import 'package:carenest_app/features/kitchen/kitchen_home/domain/kitchen_today.dart';
import 'package:carenest_app/features/kitchen/kitchen_menu/domain/kitchen_menu.dart';
import 'package:carenest_app/features/kitchen/kitchen_meals/domain/kitchen_meals.dart';
import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';

/// Nguồn dữ liệu các màn bếp. Mặc định (Xem thử) mọi nguồn null ⇒ màn dùng bản giả;
/// phiên thật truyền bản gọi BE (`Live…Source`).
class KitchenSources {
  const KitchenSources({
    this.home,
    this.meals,
    this.quantities,
    this.samples,
    this.photos,
    this.menu,
  });

  final KitchenHomeSource? home;
  final KitchenMealsSource? meals;
  final FoodQuantitySource? quantities;
  final FoodSampleSource? samples;
  final KitchenPhotoSource? photos;
  final KitchenMenuSource? menu;
}

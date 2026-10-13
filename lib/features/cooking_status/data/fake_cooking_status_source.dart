import 'package:carenest_app/features/cooking_status/domain/cooking_status.dart';
import 'package:carenest_app/features/school_menu/domain/meal_slot.dart';

/// Dữ liệu giả mockup K07 / V05: sáng đã giao, trưa đang nấu từ 09:10, chiều chờ nấu.
/// Một bản dùng chung để Trang chủ bếp và Phó HT thấy cùng trạng thái.
class FakeCookingStatusSource implements CookingStatusSource {
  FakeCookingStatusSource();

  static final shared = FakeCookingStatusSource();

  static const _defaultNotes = {
    CookingStage.waiting: 'Đã nhận đủ nguyên liệu',
    CookingStage.cooking: 'Bắt đầu',
    CookingStage.ready: 'Sẵn sàng chia suất',
    CookingStage.delivered: 'Bếp tự giao, ghi giờ giao',
  };

  static String hintOf(CookingStage stage) => _defaultNotes[stage]!;

  final Map<MealSlot, MealCooking> _meals = {
    MealSlot.breakfast: const MealCooking(
      slot: MealSlot.breakfast,
      stage: CookingStage.delivered,
      notes: {
        CookingStage.waiting: 'Đã nhận đủ nguyên liệu · 06:20',
        CookingStage.cooking: 'Bắt đầu 06:30',
        CookingStage.ready: 'Xong 07:20',
        CookingStage.delivered: 'Đã giao 07:35',
      },
    ),
    MealSlot.lunch: const MealCooking(
      slot: MealSlot.lunch,
      stage: CookingStage.cooking,
      notes: {
        CookingStage.waiting: 'Đã nhận đủ nguyên liệu · 07:45',
        CookingStage.cooking: 'Bắt đầu 09:10',
      },
    ),
    MealSlot.snack: const MealCooking(
      slot: MealSlot.snack,
      stage: CookingStage.waiting,
    ),
  };

  @override
  Future<Map<MealSlot, MealCooking>> loadToday() async => Map.of(_meals);

  @override
  Future<MealCooking> advance(MealSlot slot) async {
    final current = _meals[slot]!;
    final next =
        CookingStage.values[(current.stage.index + 1).clamp(
          0,
          CookingStage.values.length - 1,
        )];
    final updated = MealCooking(
      slot: slot,
      stage: next,
      notes: {...current.notes, next: '${hintOf(next)} · vừa cập nhật'},
    );
    _meals[slot] = updated;
    return updated;
  }
}

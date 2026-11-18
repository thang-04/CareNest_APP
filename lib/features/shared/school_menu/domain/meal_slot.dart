/// Bữa trong ngày, dùng chung thực đơn và trạng thái nấu.
enum MealSlot {
  breakfast('Bữa sáng'),
  lunch('Bữa trưa'),
  snack('Bữa chiều');

  const MealSlot(this.label);

  final String label;
}

/// Bữa trong ngày, dùng chung thực đơn, ảnh bữa ăn, trạng thái nấu.
enum MealSlot {
  breakfast('Bữa sáng'),
  lunch('Bữa trưa'),
  snack('Bữa chiều');

  const MealSlot(this.label);

  final String label;
}

/// Tên lớp kèm chữ "Lớp": BE có lớp đặt tên sẵn "Lớp Nhà trẻ 1", có lớp chỉ "Mầm 3A" ⇒ không thêm
/// "Lớp" lần nữa. [lower] cho giữa câu: "GV lớp Mầm 3A".
String classLabel(String name, {bool lower = false}) {
  final trimmed = name.trim();
  final hasPrefix = trimmed.toLowerCase().startsWith('lớp ');
  final base = hasPrefix ? trimmed.substring(4) : trimmed;
  return '${lower ? 'lớp' : 'Lớp'} $base';
}

import 'package:flutter/painting.dart';

/// Bóng duy nhất được dùng (DESIGN.md §5.5). Nút không có bóng.
abstract final class AppShadows {
  static const card = [
    BoxShadow(color: Color(0x0A101828), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(
      color: Color(0x400B72BC),
      blurRadius: 40,
      spreadRadius: -20,
      offset: Offset(0, 16),
    ),
  ];

  // Cùng giá trị `--shadow-xl` trong tokens.css của web
  static const overlay = [
    BoxShadow(
      color: Color(0x29101828),
      blurRadius: 32,
      spreadRadius: -8,
      offset: Offset(0, 20),
    ),
    BoxShadow(
      color: Color(0x0F101828),
      blurRadius: 12,
      spreadRadius: -6,
      offset: Offset(0, 8),
    ),
  ];
}

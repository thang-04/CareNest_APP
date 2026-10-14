import 'package:flutter/painting.dart';

/// Bóng của style Clay nổi (DESIGN.md §5.5, docs/design/mobile-redesign-clay.md).
/// Chỉ khai báo ở đây; widget không tự đặt bóng.
abstract final class AppShadows {
  // Card, thanh dưới, vùng nút đáy: bóng xanh mềm + bóng tối gần (FE `--shadow-clay`)
  static const card = [
    BoxShadow(
      color: Color(0x8C4FB0F5),
      blurRadius: 30,
      spreadRadius: -14,
      offset: Offset(0, 16),
    ),
    BoxShadow(
      color: Color(0x14101828),
      blurRadius: 8,
      spreadRadius: -3,
      offset: Offset(0, 3),
    ),
  ];

  // Flutter không có bóng trong ⇒ gờ đáy của nút là bóng cứng lệch xuống 3px (FE `--shadow-clay-btn`)
  static const buttonPrimary = [
    BoxShadow(color: Color(0xFF3F8FC8), offset: Offset(0, 3)),
    BoxShadow(
      color: Color(0xBF4FB0F5),
      blurRadius: 16,
      spreadRadius: -8,
      offset: Offset(0, 10),
    ),
  ];

  static const buttonSecondary = [
    BoxShadow(color: Color(0x14101828), offset: Offset(0, 2)),
    BoxShadow(
      color: Color(0x26101828),
      blurRadius: 10,
      spreadRadius: -6,
      offset: Offset(0, 4),
    ),
  ];

  // Rãnh lõm (segmented): bóng tối mảnh phía trên đặt trong viền rãnh
  static const pressedTrack = [
    BoxShadow(color: Color(0x14101828), offset: Offset(0, 1), blurRadius: 2),
  ];

  // Banner: nổi nhẹ, không viền
  static const soft = [
    BoxShadow(
      color: Color(0x4D101828),
      blurRadius: 16,
      spreadRadius: -12,
      offset: Offset(0, 8),
    ),
  ];

  /// Quầng màu theo tông cho badge, ô icon, ô số nhỏ.
  static List<BoxShadow> tinted(Color main, {double strength = 0.45}) => [
    BoxShadow(
      color: main.withValues(alpha: strength),
      blurRadius: 12,
      spreadRadius: -6,
      offset: const Offset(0, 6),
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

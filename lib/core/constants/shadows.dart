import 'package:flutter/painting.dart';

/// Bóng theo Figma App phẳng (user chốt 14/11): card, nút, badge tách bằng viền; chỉ lớp nổi
/// (bottom sheet, dialog) có bóng thật. Widget không tự đặt bóng.
abstract final class AppShadows {
  // Card, thanh dưới: bóng rất mảnh đi kèm viền `border`
  static const card = [
    BoxShadow(color: Color(0x0A101828), blurRadius: 2, offset: Offset(0, 1)),
  ];

  // Nút phẳng: không bóng
  static const List<BoxShadow> buttonPrimary = [];
  static const List<BoxShadow> buttonSecondary = [];
  static const List<BoxShadow> pressedTrack = [];
  static const List<BoxShadow> soft = [];

  /// Giữ chữ ký cũ cho badge, ô icon: style phẳng ⇒ không quầng màu.
  static List<BoxShadow> tinted(Color main, {double strength = 0.45}) =>
      const [];

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

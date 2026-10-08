import 'package:flutter/painting.dart';

/// Màu gốc của CareNest (DESIGN.md §4.1). Widget không dùng trực tiếp; đọc qua Theme/ThemeExtension.
abstract final class AppColors {
  // Brand
  static const brandBlue700 = Color(0xFF0269C5);
  static const brandBlue600 = Color(0xFF1675CF);
  static const brandSky400 = Color(0xFF4FB0F5);
  static const brandSky300 = Color(0xFF71C6FD);
  static const brandMint300 = Color(0xFF94DEBD);

  // Primary
  static const primary = Color(0xFF1565E0);
  static const primaryPressed = Color(0xFF0F55C4);
  static const primaryContainer = Color(0xFFEAF2FE);
  static const focusRing = Color(0xFFD6E6FD);

  // Semantic
  static const success = Color(0xFF12A150);
  static const successText = Color(0xFF0B7A3B);
  static const warning = Color(0xFFE8890C);
  static const warningText = Color(0xFFB25E00);
  static const danger = Color(0xFFE03131);
  static const dangerText = Color(0xFFC92A2A);
  static const purple = Color(0xFF7048E8);
  static const purpleText = Color(0xFF4D2DB7);
  static const teal = Color(0xFF0C8599);

  // Text
  static const textPrimary = Color(0xFF1B2433);
  static const textSecondary = Color(0xFF4A5568);
  static const textMuted = Color(0xFF8592A6);
  static const textInverse = Color(0xFFFFFFFF);

  // Border, surface
  static const border = Color(0xFFE3E9F2);
  static const borderStrong = Color(0xFFCDD6E3);
  static const background = Color(0xFFF5F8FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF8FAFC);

  // Disabled, loading
  static const disabled = Color(0xFFADB5BD);
  static const disabledContainer = Color(0xFFF1F3F6);
  static const skeleton = Color(0xFFEEF1F5);

  // Chip theo tông — user duyệt 2026-10-08; chữ/nền mỗi tông đạt ≥4.5:1 (WCAG AA chữ 12px).
  static const tealText = Color(0xFF0A6B7B);
  // warningText #B25E00 trên warningContainer chỉ 4.30:1 ⇒ chip dùng màu đậm hơn
  static const warningChipText = Color(0xFFA35600);
  static const successContainer = Color(0xFFE7F6EE);
  static const successBorder = Color(0xFFB5E3C8);
  static const warningContainer = Color(0xFFFFF4E5);
  static const warningBorder = Color(0xFFFFD8A8);
  static const dangerContainer = Color(0xFFFDECEC);
  static const dangerBorder = Color(0xFFF8C4C4);
  static const purpleContainer = Color(0xFFF1EDFD);
  static const purpleBorder = Color(0xFFD5CBF9);
  static const tealContainer = Color(0xFFE3F4F6);
  static const tealBorder = Color(0xFFB2DFE5);
}

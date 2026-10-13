import 'package:flutter/animation.dart';

/// Thời lượng và đường cong chuyển động (DESIGN.md §5.5).
abstract final class AppMotion {
  static const curve = Cubic(0.4, 0, 0.2, 1);
  static const fast = Duration(milliseconds: 150);
  static const overlay = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 300);
  static const toast = Duration(milliseconds: 3500);
  static const toastError = Duration(seconds: 6);
  static const skeletonPulse = Duration(milliseconds: 1200);
  static const pressScale = 0.98;
}

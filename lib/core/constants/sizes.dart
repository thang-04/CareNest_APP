/// Khoảng cách theo lưới 4, đơn vị logical pixel (DESIGN.md §5.2).
abstract final class AppSpacing {
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space7 = 32;

  static const double pagePadding = 16;
  static const double cardPadding = 16;
}

abstract final class AppRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 20;
  static const double pill = 999;
}

abstract final class AppSizes {
  static const double minimumTapTarget = 48;
  static const double buttonMinHeight = 48;
  static const double iconSmall = 16;
  static const double iconMedium = 24;
  static const double iconLarge = 48;

  /// Dưới mốc này dùng bố cục một cột + NavigationBar (DESIGN §5.3).
  static const double compactBreakpoint = 600;
}

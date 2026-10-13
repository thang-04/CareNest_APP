/// Khoảng cách lưới 4, đơn vị logical pixel (DESIGN.md §5.2). Không có `space7`.
abstract final class AppSpacing {
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;

  static const double pagePadding = 16;
  static const double pagePaddingWide = 20;
  static const double cardPadding = 20;
  static const double cardPaddingDense = 16;
  static const double cardGap = 12;
  static const double sectionGap = 24;

  /// Lề màn 20 khi cửa sổ rộng từ mốc này (§5.2).
  static const double wideBreakpoint = 400;

  static double pageGutter(double width) =>
      width >= wideBreakpoint ? pagePaddingWide : pagePadding;
}

/// Bo góc (DESIGN.md §5.3).
abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double pill = 9999;
}

/// Kích thước nền trước text scaling (DESIGN.md §5.4).
abstract final class AppSizes {
  static const double buttonHeight = 52;
  static const double buttonSmallHeight = 44;
  static const double inputHeight = 52;
  static const double minimumTapTarget = 48;
  static const double badgeHeight = 28;
  static const double filterChipHeight = 36;
  static const double listRowMinHeight = 64;
  static const double iconTileSize = 40;
  static const double iconInline = 20;
  static const double iconTile = 22;
  static const double iconNavigation = 24;
  static const double iconBadge = 14;
  static const double appBarHeight = 56;
  static const double bottomNavigationHeight = 72;
  static const double navigationIndicatorWidth = 64;
  static const double navigationIndicatorHeight = 32;
  static const double heroHeight = 224;
  static const double emptyIllustrationWidth = 168;
  static const double emptyIllustrationHeight = 124;
  static const double avatar = 40;
  static const double avatarSmall = 32;
  static const double logoFull = 168;
}

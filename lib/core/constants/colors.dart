import 'package:flutter/painting.dart';

/// Màu gốc CareNest theo Figma App phẳng (user chốt 14/11, thay style Clay); tông trạng thái giữ như web.
/// Widget không dùng trực tiếp; đọc qua Theme/ThemeExtension.
abstract final class AppColors {
  // Thương hiệu: `brand` là nền nút chính và dải đầu màn, `primary` là link/icon nhấn/focus
  static const brand = Color(0xFF1565E0);
  static const brandHover = Color(0xFF2A74E6);
  static const brandPressed = Color(0xFF0F55C2);
  static const onBrand = Color(0xFFFFFFFF);
  static const primary = Color(0xFF1565E0);
  static const primaryPressed = Color(0xFF0F55C2);
  static const primarySoft = Color(0xFFEAF2FE);
  static const primaryBorder = Color(0xFFC9DCFA);
  // Chữ trên nền `primarySoft` (chip đang chọn, nhãn ngữ cảnh)
  static const primaryText = Color(0xFF0F4FB0);
  static const focusRing = Color(0xFFD6E5FC);
  static const accent = Color(0xFF94DEBD);
  static const accentSoft = Color(0xFFEEFAF4);
  static const accentText = Color(0xFF1F7A59);
  static const wordmarkCare = Color(0xFF1565E0);

  // Nền, bề mặt, chữ, viền
  static const background = Color(0xFFF5F8FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF8FAFC);
  static const textPrimary = Color(0xFF1B2433);
  static const textSecondary = Color(0xFF4A5568);
  static const textMuted = Color(0xFF66728A);
  static const textDisabled = Color(0xFFA3AEBD);
  static const border = Color(0xFFE6EBF4);
  static const borderStrong = Color(0xFFD5DCE7);
  static const track = Color(0xFFF1F3F6);
  static const overlay = Color(0x521B2433);

  // Phản hồi: thông điệp vừa xảy ra, khác trạng thái bản ghi
  static const success = Color(0xFF12A150);
  static const successText = Color(0xFF0B7A3B);
  static const successSoft = Color(0xFFE7F7EE);
  static const successBorder = Color(0xFFC4EAD3);
  static const warning = Color(0xFFE8890C);
  static const warningText = Color(0xFF9A5100);
  static const warningSoft = Color(0xFFFFF4E5);
  static const warningBorder = Color(0xFFFFE1BC);
  static const danger = Color(0xFFE03131);
  static const dangerText = Color(0xFFC92A2A);
  static const dangerSoft = Color(0xFFFDECEC);
  static const dangerBorder = Color(0xFFF8CACA);
  static const info = Color(0xFF1565E0);
  static const infoText = Color(0xFF0F4FB0);
  static const infoSoft = Color(0xFFEAF2FE);
  static const infoBorder = Color(0xFFD3E3FB);

  // Tông trạng thái bản ghi (§6.1): màu chính / chữ / nền
  static const toneGray = Color(0xFF7B8AA0);
  static const toneGrayText = Color(0xFF556377);
  static const toneGraySoft = Color(0xFFF1F3F6);
  static const toneOrange = Color(0xFFF5820B);
  static const toneOrangeText = Color(0xFF944F06);
  static const toneOrangeSoft = Color(0xFFFFF0DE);
  static const toneBlue = Color(0xFF1565E0);
  static const toneBlueText = Color(0xFF0F4FB0);
  static const toneBlueSoft = Color(0xFFEAF2FE);
  static const toneApproval = Color(0xFFF5B400);
  static const toneApprovalText = Color(0xFF835C00);
  static const toneApprovalSoft = Color(0xFFFDF3D6);
  static const toneRed = Color(0xFFF0475A);
  static const toneRedText = Color(0xFFA63749);
  static const toneRedSoft = Color(0xFFFDE2E5);
  static const toneGreen = Color(0xFF22B573);
  static const toneGreenText = Color(0xFF176F51);
  static const toneGreenSoft = Color(0xFFE3F6EC);
  static const toneTeal = Color(0xFF13B5B1);
  static const toneTealText = Color(0xFF0F6C71);
  static const toneTealSoft = Color(0xFFD9F3F3);

  // Avatar (§7.3): cặp nền/chữ theo tông 0–4
  static const avatarBackgrounds = [
    Color(0xFFEAF2FE),
    Color(0xFFFCE7F3),
    Color(0xFFDCFCE7),
    Color(0xFFFEF3C7),
    Color(0xFFDEF5F4),
  ];
  static const avatarForegrounds = [
    Color(0xFF1565E0),
    Color(0xFFBE185D),
    Color(0xFF15803D),
    Color(0xFFB45309),
    Color(0xFF0F6C71),
  ];
}

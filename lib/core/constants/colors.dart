import 'package:flutter/painting.dart';

/// Màu gốc CareNest, cùng mã với web (DESIGN.md §4.1–4.2, §6.1, §7.3).
/// Widget không dùng trực tiếp; đọc qua Theme/ThemeExtension.
abstract final class AppColors {
  // Thương hiệu: `brand` là nền nút chính, `primary` là link/icon nhấn/focus (§4.1)
  static const brand = Color(0xFF4FB0F5);
  static const brandHover = Color(0xFF71C6FD);
  static const brandPressed = Color(0xFF95CFF9);
  static const onBrand = Color(0xFF0E3F63);
  static const primary = Color(0xFF0B72BC);
  static const primaryPressed = Color(0xFF0A6AAE);
  static const primarySoft = Color(0xFFE2F2FD);
  static const primaryBorder = Color(0xFF95CFF9);
  static const focusRing = Color(0xFFC5E5FC);
  static const accent = Color(0xFF94DEBD);
  static const accentSoft = Color(0xFFEEFAF4);
  static const accentText = Color(0xFF1F7A59);
  static const wordmarkCare = Color(0xFF0269C5);

  // Nền, bề mặt, chữ, viền
  static const background = Color(0xFFF1F9FE);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF8FAFC);
  static const textPrimary = Color(0xFF1B2433);
  static const textSecondary = Color(0xFF4A5568);
  static const textMuted = Color(0xFF66728A);
  static const textDisabled = Color(0xFFA3AEBD);
  static const border = Color(0xFFE3E9F2);
  static const borderStrong = Color(0xFFCDD6E3);
  static const track = Color(0xFFEEF1F5);
  static const overlay = Color(0x520E3F63);

  // Phản hồi (§4.2): thông điệp vừa xảy ra, khác trạng thái bản ghi
  static const success = Color(0xFF12A150);
  static const successText = Color(0xFF0B7A3B);
  static const successSoft = Color(0xFFE7F7EE);
  static const successBorder = Color(0xFFB5E5C8);
  static const warning = Color(0xFFE8890C);
  static const warningText = Color(0xFF9A5100);
  static const warningSoft = Color(0xFFFFF4E3);
  static const warningBorder = Color(0xFFF7D49C);
  static const danger = Color(0xFFE03131);
  static const dangerText = Color(0xFFC92A2A);
  static const dangerSoft = Color(0xFFFDECEC);
  static const dangerBorder = Color(0xFFF6B9B9);
  static const info = Color(0xFF0B72BC);
  static const infoText = Color(0xFF0E3F63);
  static const infoSoft = Color(0xFFE2F2FD);
  static const infoBorder = Color(0xFF95CFF9);

  // Tông trạng thái bản ghi (§6.1): màu chính / chữ / nền
  static const toneGray = Color(0xFF7B8AA0);
  static const toneGrayText = Color(0xFF556377);
  static const toneGraySoft = Color(0xFFEAECF0);
  static const toneOrange = Color(0xFFF5820B);
  static const toneOrangeText = Color(0xFF944F06);
  static const toneOrangeSoft = Color(0xFFFDEBD8);
  static const toneBlue = Color(0xFF2BA0F3);
  static const toneBlueText = Color(0xFF0E3F63);
  static const toneBlueSoft = Color(0xFFDDF0FD);
  static const toneApproval = Color(0xFFF5B400);
  static const toneApprovalText = Color(0xFF835C00);
  static const toneApprovalSoft = Color(0xFFFDF3D6);
  static const toneRed = Color(0xFFF0475A);
  static const toneRedText = Color(0xFFA63749);
  static const toneRedSoft = Color(0xFFFDE2E5);
  static const toneGreen = Color(0xFF22B573);
  static const toneGreenText = Color(0xFF176F51);
  static const toneGreenSoft = Color(0xFFDCF3E9);
  static const toneTeal = Color(0xFF13B5B1);
  static const toneTealText = Color(0xFF0F6C71);
  static const toneTealSoft = Color(0xFFD9F3F3);

  // Avatar (§7.3): cặp nền/chữ theo tông 0–4
  static const avatarBackgrounds = [
    Color(0xFFE2F2FD),
    Color(0xFFFCE7F3),
    Color(0xFFDCFCE7),
    Color(0xFFFEF3C7),
    Color(0xFFDEF5F4),
  ];
  static const avatarForegrounds = [
    Color(0xFF0B72BC),
    Color(0xFFBE185D),
    Color(0xFF15803D),
    Color(0xFFB45309),
    Color(0xFF0F6C71),
  ];
}

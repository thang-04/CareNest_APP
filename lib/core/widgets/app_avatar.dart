import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';

/// Avatar chữ cái theo Figma App: một chữ đầu của tên gọi, nền `primarySoft`, chữ `primary`.
/// `toneOf`/`initialsOf` giữ cách tính của web để đối chiếu (DESIGN.md §7.3).
/// Không dùng ảnh trẻ trong mock/test (AGENTS.md nguyên tắc 4).
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.name, this.size = AppSizes.avatar});

  final String name;
  final double size;

  /// Tổng mã UTF-16 đầu của từng ký tự mod 5, khớp `[...name].reduce(charCodeAt(0))` của web.
  static int toneOf(String name) {
    var sum = 0;
    for (final rune in name.runes) {
      sum += rune > 0xFFFF ? ((rune - 0x10000) >> 10) + 0xD800 : rune;
    }
    return sum % 5;
  }

  /// Chữ đầu của hai từ cuối, viết hoa (web `initials`).
  static String initialsOf(String name) {
    final words = name.split(' ').where((word) => word.isNotEmpty).toList();
    final lastTwo = words.length > 2 ? words.sublist(words.length - 2) : words;
    return lastTwo
        .map((word) => String.fromCharCode(word.runes.first))
        .join()
        .toUpperCase();
  }

  /// Chữ đầu của từ cuối (tên gọi), viết hoa: "Nguyễn Minh Anh" ⇒ "A".
  static String letterOf(String name) {
    final words = name.split(' ').where((word) => word.isNotEmpty);
    if (words.isEmpty) return '';
    return String.fromCharCode(words.last.runes.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          shape: BoxShape.circle,
        ),
        // Chữ phóng lớn ⇒ thu chữ trong vòng tròn thay vì cắt
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            letterOf(name),
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

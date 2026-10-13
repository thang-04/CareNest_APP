import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';

/// Avatar chữ cái, màu theo tên giống web `avatarTone`/`initials` (DESIGN.md §7.3).
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

  @override
  Widget build(BuildContext context) {
    final tone = toneOf(name);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.avatarBackgrounds[tone],
          shape: BoxShape.circle,
        ),
        child: Text(
          initialsOf(name),
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
            color: AppColors.avatarForegrounds[tone],
          ),
        ),
      ),
    );
  }
}

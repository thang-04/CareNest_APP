import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';

/// Ô tìm kiếm viên thuốc có icon kính lúp; không có nhãn trên nên đặt nhãn semantics riêng.
/// Lọc trên danh sách đã tải là việc của màn; tìm phía BE khi có API.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.semanticLabel,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      textField: true,
      label: semanticLabel ?? hint,
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
          prefixIcon: const Icon(
            AppIcons.search,
            size: AppSizes.iconInline,
            color: AppColors.textMuted,
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            borderSide: const BorderSide(color: AppColors.borderStrong),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            borderSide: const BorderSide(color: AppColors.borderStrong),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

/// Lọc theo tên, không phân biệt hoa thường và dấu tiếng Việt.
bool matchesSearch(String text, String query) {
  final q = foldVietnamese(query.trim());
  return q.isEmpty || foldVietnamese(text).contains(q);
}

String foldVietnamese(String value) {
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  final buffer = StringBuffer();
  for (final char in value.toLowerCase().split('')) {
    final base = groups.entries
        .where((entry) => entry.value.contains(char))
        .map((entry) => entry.key)
        .firstOrNull;
    buffer.write(base ?? char);
  }
  return buffer.toString();
}

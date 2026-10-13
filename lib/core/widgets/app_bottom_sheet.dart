import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';

/// Sheet trắng bo trên 32, scrim `overlay` không blur (DESIGN.md §7.1).
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.space4,
        right: AppSpacing.space4,
        bottom:
            MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.space6,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            builder(sheetContext),
          ],
        ),
      ),
    ),
  );
}

/// Một lựa chọn trong sheet: đang chọn nền `primarySoft` + dấu tích.
class AppSheetOption extends StatelessWidget {
  const AppSheetOption({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.leading,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: AppSpacing.space3),
                  ],
                  Expanded(child: child),
                  Visibility(
                    visible: selected,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Icon(
                      AppIcons.check,
                      color: AppStatusColors.of(context).link,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

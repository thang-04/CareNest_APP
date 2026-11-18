import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/parent/evaluation/domain/evaluation.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/evaluation_labels.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/widgets/evaluation_widgets.dart';

/// Mục Chủ đề (OBS-27): chủ đề nhóm theo học kỳ, mới nhất trước; chạm mở kết quả chi tiết.
class EvaluationThemesTab extends StatelessWidget {
  const EvaluationThemesTab({
    super.key,
    required this.themes,
    required this.onOpenTheme,
  });

  /// Chủ đề mới nhất trước
  final List<ThemeResult> themes;
  final ValueChanged<String> onOpenTheme;

  @override
  Widget build(BuildContext context) {
    if (themes.isEmpty) {
      return const AppEmptyState(
        icon: AppIcons.menuBook,
        title: 'Chưa có kết quả chủ đề',
        message: 'Kết quả có sau khi chủ đề kết thúc và cô xác nhận.',
      );
    }
    final semesters = {for (final theme in themes) theme.semester}.toList()
      ..sort((a, b) => b.compareTo(a));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < semesters.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sectionGap),
          EvaluationSectionTitle(EvaluationLabels.semester(semesters[i])),
          const SizedBox(height: AppSpacing.space3),
          AppCard(
            flush: true,
            child: AppDividedColumn(
              children: [
                for (final theme in themes)
                  if (theme.semester == semesters[i])
                    _ThemeRow(
                      theme: theme,
                      onOpen: () => onOpenTheme(theme.id),
                    ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.space4),
        Text(
          'Bé đạt chủ đề khi đạt từ ${themes.first.passPercent}% số mục tiêu.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({required this.theme, required this.onOpen});

  final ThemeResult theme;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final dates =
        '${DateLabels.dayMonth(theme.from)} – ${DateLabels.dayMonth(theme.to)}';
    if (theme.status == PeriodStatus.pending) {
      return AppListRow(
        title: theme.name,
        subtitle: Text('Đang học · $dates'),
        trailing: const AppStatusBadge(
          label: 'Chưa có kết quả',
          tone: AppStatusTone.gray,
        ),
      );
    }
    return AppListRow(
      title: theme.name,
      subtitle: Text('$dates · ${theme.metGoals}/${theme.totalGoals} mục tiêu'),
      trailing: ResultMark(met: theme.passed ?? false),
      showChevron: true,
      onTap: onOpen,
    );
  }
}

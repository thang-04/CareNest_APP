import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/integration/load_failure.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/parent/evaluation/data/fake_evaluation_source.dart';
import 'package:carenest_app/features/parent/evaluation/domain/evaluation.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/widgets/evaluation_widgets.dart';
import 'package:carenest_app/features/parent/parent_home/domain/parent_today.dart';

/// Kết quả cuối chủ đề của bé (OBS-27): MT chưa đạt trước, MT đạt sau, hiện đủ (user 18/11).
class ThemeResultScreen extends StatefulWidget {
  const ThemeResultScreen({
    super.key,
    required this.child,
    required this.themeId,
    this.source = const FakeEvaluationSource(),
  });

  final ChildSummary child;
  final String themeId;
  final EvaluationSource source;

  @override
  State<ThemeResultScreen> createState() => _ThemeResultScreenState();
}

class _ThemeResultScreenState extends State<ThemeResultScreen> {
  late Future<EvaluationBook> _book = widget.source.load(widget.child.id);

  void _retry() {
    setState(() {
      _book = widget.source.load(widget.child.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuối chủ đề')),
      body: FutureBuilder<EvaluationBook>(
        future: _book,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: AppErrorState(
                title: 'Chưa tải được kết quả chủ đề',
                message: loadFailureMessage(snapshot.error),
                onRetry: _retry,
              ),
            );
          }
          final book = snapshot.data;
          if (book == null) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 3),
            );
          }
          final theme = book.themeById(widget.themeId);
          if (theme == null || theme.status == PeriodStatus.pending) {
            return const Center(
              child: AppEmptyState(
                icon: AppIcons.searchOff,
                title: 'Không tìm thấy kết quả chủ đề',
                message: 'Chủ đề chưa có kết quả hoặc không thuộc bé này.',
              ),
            );
          }
          return _ThemeResultView(
            theme: theme,
            className: widget.child.className,
          );
        },
      ),
    );
  }
}

class _ThemeResultView extends StatelessWidget {
  const _ThemeResultView({required this.theme, required this.className});

  final ThemeResult theme;
  final String className;

  @override
  Widget build(BuildContext context) {
    final passed = theme.passed;
    final notMet = theme.goals.where((goal) => !goal.met).toList();
    final met = theme.goals.where((goal) => goal.met).toList();
    final confirmedBy = theme.confirmedBy;
    final confirmedAt = theme.confirmedAt;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        AppCard(
          child: EvaluationResultSummary(
            eyebrow: 'Chủ đề',
            title: theme.name,
            meta: '${DateLabels.range(theme.from, theme.to)} · $className',
            met: theme.metGoals,
            total: theme.totalGoals,
            unit: 'mục tiêu đạt',
            badge: passed == null
                ? null
                : AppStatusBadge(
                    label: passed ? 'Đạt chủ đề' : 'Chưa đạt chủ đề',
                    tone: passed ? AppStatusTone.green : AppStatusTone.red,
                    icon: passed ? AppIcons.check : AppIcons.minus,
                  ),
            caption: switch (theme.passPercent) {
              final percent? =>
                'Bé đạt chủ đề khi đạt từ $percent% số mục tiêu.',
              null => null,
            },
          ),
        ),
        if (notMet.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.cardGap),
          AppCard(child: GoalGroup(met: false, goals: notMet)),
        ],
        if (met.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.cardGap),
          AppCard(child: GoalGroup(met: true, goals: met)),
        ],
        if (confirmedBy != null && confirmedAt != null) ...[
          const SizedBox(height: AppSpacing.space4),
          ConfirmedNote(by: confirmedBy, at: confirmedAt),
        ],
      ],
    );
  }
}

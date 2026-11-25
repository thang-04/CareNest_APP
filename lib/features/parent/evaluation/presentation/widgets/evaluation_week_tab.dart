import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/parent/evaluation/domain/evaluation.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/evaluation_labels.dart';

/// Mục Tuần (OBS-29): nhận xét cô đã gửi, mới nhất mở sẵn; tuần cũ trích 3 dòng.
class EvaluationWeekTab extends StatefulWidget {
  const EvaluationWeekTab({super.key, required this.comments});

  /// Tuần mới nhất trước
  final List<WeeklyComment> comments;

  @override
  State<EvaluationWeekTab> createState() => _EvaluationWeekTabState();
}

class _EvaluationWeekTabState extends State<EvaluationWeekTab> {
  final _open = <int>{0};

  @override
  Widget build(BuildContext context) {
    if (widget.comments.isEmpty) {
      return const AppEmptyState(
        icon: AppIcons.review,
        title: 'Chưa có nhận xét tuần',
        message: 'Cô gửi nhận xét vào ngày học cuối của mỗi tuần.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.comments.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.cardGap),
          _WeekCard(
            comment: widget.comments[i],
            open: _open.contains(i),
            onOpen: () => setState(() => _open.add(i)),
          ),
        ],
      ],
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.comment,
    required this.open,
    required this.onOpen,
  });

  static const _excerptLines = 3;

  final WeeklyComment comment;
  final bool open;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sentAt = comment.sentAt;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            EvaluationLabels.week(comment.weekLabel, comment.from, comment.to),
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.space2),
          LayoutBuilder(
            builder: (context, constraints) {
              final text = comment.paragraphs.join(' ');
              final longer = !open && _overflows(context, text, constraints);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (open || !longer)
                    for (var i = 0; i < comment.paragraphs.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.space3),
                      Text(comment.paragraphs[i], style: textTheme.bodyLarge),
                    ]
                  else
                    Text(
                      text,
                      maxLines: _excerptLines,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge,
                    ),
                  const SizedBox(height: AppSpacing.space2),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.space2,
                    children: [
                      Text(
                        '${comment.teacherName} · gửi '
                        '${DateLabels.dayMonth(sentAt)}, ${DateLabels.time24(sentAt)}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (longer)
                        AppButton(
                          label: 'Đọc tiếp',
                          variant: AppButtonVariant.text,
                          small: true,
                          onPressed: onOpen,
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Trích đoạn dài hơn 3 dòng ở bề rộng hiện tại ⇒ cần nút "Đọc tiếp".
  static bool _overflows(
    BuildContext context,
    String text,
    BoxConstraints constraints,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: Theme.of(context).textTheme.bodyLarge),
      maxLines: _excerptLines,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: constraints.maxWidth);
    final overflows = painter.didExceedMaxLines;
    painter.dispose();
    return overflows;
  }
}

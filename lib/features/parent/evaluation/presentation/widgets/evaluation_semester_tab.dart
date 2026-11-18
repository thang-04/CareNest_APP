import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/parent/evaluation/domain/evaluation.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/evaluation_labels.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/widgets/evaluation_widgets.dart';

/// Mục Học kỳ (OBS-06): ‹ › đổi học kỳ; lĩnh vực chưa đạt mở sẵn.
class EvaluationSemesterTab extends StatefulWidget {
  const EvaluationSemesterTab({super.key, required this.semesters});

  /// Học kỳ mới nhất trước
  final List<SemesterResult> semesters;

  @override
  State<EvaluationSemesterTab> createState() => _EvaluationSemesterTabState();
}

class _EvaluationSemesterTabState extends State<EvaluationSemesterTab> {
  var _index = 0;

  static String? _themesLine(GoalResult goal) => goal.themesAssessed == null
      ? null
      : 'Đạt ở ${goal.themesMet}/${goal.themesAssessed} chủ đề';

  @override
  Widget build(BuildContext context) {
    if (widget.semesters.isEmpty) {
      return const AppEmptyState(
        icon: AppIcons.calendar,
        title: 'Chưa có kết quả học kỳ',
        message: 'Kết quả có sau khi học kỳ kết thúc và cô xác nhận.',
      );
    }
    final semester = widget.semesters[_index];
    final label = EvaluationLabels.semester(semester.semester);
    final confirmedBy = semester.confirmedBy;
    final confirmedAt = semester.confirmedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EvaluationPeriodStepper(
          title: label,
          subtitle: DateLabels.range(semester.from, semester.to),
          previousLabel: 'Học kỳ trước',
          nextLabel: 'Học kỳ sau',
          onPrevious: _index < widget.semesters.length - 1
              ? () => setState(() => _index++)
              : null,
          onNext: _index > 0 ? () => setState(() => _index--) : null,
        ),
        const SizedBox(height: AppSpacing.space3),
        if (semester.status == PeriodStatus.pending)
          AppEmptyState(
            icon: AppIcons.calendar,
            title: '$label chưa có kết quả',
            message: 'Kết quả có sau khi học kỳ kết thúc và cô xác nhận.',
          )
        else ...[
          AppCard(
            child: EvaluationResultSummary(
              met: semester.domainsMet,
              total: semester.domainsTotal,
              unit: 'lĩnh vực đạt',
              caption:
                  'Kết quả mỗi mục tiêu lấy từ các chủ đề bé đã học trong học kỳ.',
            ),
          ),
          const SizedBox(height: AppSpacing.cardGap),
          AppCard(
            flush: true,
            child: AppDividedColumn(
              children: [
                for (final domain in semester.domains)
                  DomainTile(
                    key: ValueKey('${semester.semester}-${domain.name}'),
                    domain: domain,
                    initiallyExpanded: domain.met == false,
                    describe: _themesLine,
                  ),
              ],
            ),
          ),
          if (confirmedBy != null && confirmedAt != null) ...[
            const SizedBox(height: AppSpacing.space4),
            ConfirmedNote(by: confirmedBy, at: confirmedAt),
          ],
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/parent/evaluation/data/fake_evaluation_source.dart';
import 'package:carenest_app/features/parent/evaluation/domain/evaluation.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/widgets/evaluation_day_tab.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/widgets/evaluation_semester_tab.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/widgets/evaluation_themes_tab.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/widgets/evaluation_week_tab.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/widgets/evaluation_year_end_tab.dart';
import 'package:carenest_app/features/parent/parent_home/domain/parent_today.dart';

enum EvaluationTab { day, week, theme, semester, yearEnd }

/// Phụ huynh · Đánh giá (user 18/11, canvas "Đánh giá của bé"): mở từ ô "Đánh giá" ở Trang chủ;
/// 5 mục Ngày | Tuần | Chủ đề | Học kỳ | Cuối năm. Dữ liệu giả, chưa nối BE.
class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({
    super.key,
    required this.child,
    required this.onOpenTheme,
    this.initialTab = EvaluationTab.day,
    this.source = const FakeEvaluationSource(),
  });

  final ChildSummary child;

  /// Mở kết quả một chủ đề theo id
  final ValueChanged<String> onOpenTheme;
  final EvaluationTab initialTab;
  final EvaluationSource source;

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  late Future<EvaluationBook> _book = widget.source.load(widget.child.id);
  late EvaluationTab _tab = widget.initialTab;

  void _retry() {
    setState(() {
      _book = widget.source.load(widget.child.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá')),
      body: FutureBuilder<EvaluationBook>(
        future: _book,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: AppErrorState(
                title: 'Chưa tải được đánh giá',
                message: 'Kiểm tra kết nối mạng rồi thử lại.',
                onRetry: _retry,
              ),
            );
          }
          final book = snapshot.data;
          if (book == null) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 4),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              _ChildLine(child: widget.child),
              const SizedBox(height: AppSpacing.space4),
              AppSegmented<EvaluationTab>(
                segments: const [
                  (EvaluationTab.day, 'Ngày'),
                  (EvaluationTab.week, 'Tuần'),
                  (EvaluationTab.theme, 'Chủ đề'),
                  (EvaluationTab.semester, 'Học kỳ'),
                  (EvaluationTab.yearEnd, 'Cuối năm'),
                ],
                selected: _tab,
                onChanged: (tab) => setState(() => _tab = tab),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              switch (_tab) {
                EvaluationTab.day => EvaluationDayTab(weeks: book.weeks),
                EvaluationTab.week => EvaluationWeekTab(
                  comments: book.weeklyComments,
                ),
                EvaluationTab.theme => EvaluationThemesTab(
                  themes: book.themes,
                  onOpenTheme: widget.onOpenTheme,
                ),
                EvaluationTab.semester => EvaluationSemesterTab(
                  semesters: book.semesters,
                ),
                EvaluationTab.yearEnd => EvaluationYearEndTab(
                  yearEnd: book.yearEnd,
                ),
              },
            ],
          );
        },
      ),
    );
  }
}

/// Bé đang xem: ảnh chữ cái, họ tên, lớp và tuổi.
class _ChildLine extends StatelessWidget {
  const _ChildLine({required this.child});

  final ChildSummary child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        AppAvatar(name: child.fullName),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(child.fullName, style: textTheme.titleSmall),
              Text(
                child.classAndAge,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

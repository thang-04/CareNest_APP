import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/integration/load_failure.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/parent/parent_home/domain/parent_today.dart';
import 'package:carenest_app/features/parent/rewards/data/fake_reward_source.dart';
import 'package:carenest_app/features/parent/rewards/domain/rewards.dart';
import 'package:carenest_app/features/parent/rewards/presentation/widgets/rewards_guide.dart';
import 'package:carenest_app/features/parent/rewards/presentation/widgets/rewards_month_tab.dart';
import 'package:carenest_app/features/parent/rewards/presentation/widgets/rewards_week_tab.dart';
import 'package:carenest_app/features/parent/rewards/presentation/widgets/rewards_year_end_tab.dart';

enum RewardsTab { week, month, yearEnd }

/// Phụ huynh · Khen thưởng (user 18/11, canvas "Khen thưởng của bé"): mở từ ô "Khen thưởng" ở Trang chủ;
/// 3 mục Tuần | Tháng | Cuối năm, nút "?" giải thích cách nhận. Dữ liệu giả, chưa nối BE.
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({
    super.key,
    required this.child,
    required this.onOpenDailyEvaluation,
    this.initialTab = RewardsTab.week,
    this.source = const FakeRewardSource(),
  });

  final ChildSummary child;

  /// Mở trang Đánh giá (mục Ngày) để xem cờ gắn với từng ngày
  final VoidCallback onOpenDailyEvaluation;
  final RewardsTab initialTab;
  final RewardSource source;

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late Future<RewardBook> _book = widget.source.load(widget.child.id);
  late RewardsTab _tab = widget.initialTab;

  void _retry() {
    setState(() {
      _book = widget.source.load(widget.child.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RewardBook>(
      future: _book,
      builder: (context, snapshot) {
        final book = snapshot.hasError ? null : snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Khen thưởng'),
            actions: [
              if (book?.rules case final rules?)
                IconButton(
                  tooltip: 'Cách bé nhận khen thưởng',
                  onPressed: () => showRewardsGuide(context, rules),
                  icon: const Icon(AppIcons.help),
                ),
            ],
          ),
          body: snapshot.hasError
              ? Center(
                  child: AppErrorState(
                    title: 'Chưa tải được khen thưởng',
                    message: loadFailureMessage(snapshot.error),
                    onRetry: _retry,
                  ),
                )
              : book == null
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.pagePadding),
                  child: AppSkeletonList(rows: 4),
                )
              : _content(book),
        );
      },
    );
  }

  Widget _content(RewardBook book) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        _ChildLine(child: widget.child),
        const SizedBox(height: AppSpacing.space4),
        AppSegmented<RewardsTab>(
          segments: const [
            (RewardsTab.week, 'Tuần'),
            (RewardsTab.month, 'Tháng'),
            (RewardsTab.yearEnd, 'Cuối năm'),
          ],
          selected: _tab,
          onChanged: (tab) => setState(() => _tab = tab),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        switch (_tab) {
          RewardsTab.week => RewardsWeekTab(
            weeks: book.weeks,
            rules: book.rules,
            onOpenDailyEvaluation: widget.onOpenDailyEvaluation,
          ),
          RewardsTab.month => RewardsMonthTab(
            months: book.months,
            rules: book.rules,
          ),
          RewardsTab.yearEnd => RewardsYearEndTab(
            schoolYear: book.schoolYear,
            yearEnd: book.yearEnd,
            totals: book.totals,
          ),
        },
      ],
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

import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/motion.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/parent/health_book/data/fake_health_book_source.dart';
import 'package:carenest_app/features/parent/health_book/domain/health_book.dart';
import 'package:carenest_app/features/parent/health_book/presentation/health_labels.dart';
import 'package:carenest_app/features/parent/health_book/presentation/widgets/health_exams_tab.dart';
import 'package:carenest_app/features/parent/health_book/presentation/widgets/health_trend_tab.dart';
import 'package:carenest_app/features/parent/health_book/presentation/widgets/health_widgets.dart';
import 'package:carenest_app/features/parent/parent_home/domain/parent_today.dart';

enum HealthBookTab { rounds, exams, trend }

/// Phụ huynh · Sổ sức khỏe (user 17/11, canvas "Sổ sức khỏe"): mở từ ô "Sổ sức khỏe" ở Trang chủ;
/// ba phần Kỳ cân đo | Đợt khám | Xu hướng. Dữ liệu giả, chưa nối BE.
class HealthBookScreen extends StatefulWidget {
  const HealthBookScreen({
    super.key,
    required this.child,
    required this.onOpenExam,
    this.initialTab = HealthBookTab.rounds,
    this.source = const FakeHealthBookSource(),
  });

  final ChildSummary child;

  /// Mở màn Chi tiết đợt khám theo id đợt
  final ValueChanged<String> onOpenExam;
  final HealthBookTab initialTab;
  final HealthBookSource source;

  @override
  State<HealthBookScreen> createState() => _HealthBookScreenState();
}

class _HealthBookScreenState extends State<HealthBookScreen> {
  late Future<HealthBook> _book = widget.source.load(widget.child.id);
  late HealthBookTab _tab = widget.initialTab;

  void _retry() {
    setState(() {
      _book = widget.source.load(widget.child.id);
    });
  }

  void _showTab(HealthBookTab tab) {
    setState(() {
      _tab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sổ sức khỏe')),
      body: FutureBuilder<HealthBook>(
        future: _book,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: AppErrorState(
                title: 'Chưa tải được sổ sức khỏe',
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
              AppSegmented<HealthBookTab>(
                segments: const [
                  (HealthBookTab.rounds, 'Kỳ cân đo'),
                  (HealthBookTab.exams, 'Đợt khám'),
                  (HealthBookTab.trend, 'Xu hướng'),
                ],
                selected: _tab,
                onChanged: _showTab,
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              switch (_tab) {
                HealthBookTab.rounds => _RoundsTab(
                  rounds: book.rounds,
                  onOpenExams: () => _showTab(HealthBookTab.exams),
                ),
                HealthBookTab.exams => HealthExamsTab(
                  exams: book.exams,
                  onOpenExam: widget.onOpenExam,
                ),
                HealthBookTab.trend => HealthTrendTab(
                  growth: book.growth,
                  interpretation: book.interpretation,
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

/// Kỳ cân đo dạng accordion (user 17/11): kỳ mới nhất mở sẵn, chạm để mở hoặc đóng từng kỳ.
class _RoundsTab extends StatefulWidget {
  const _RoundsTab({required this.rounds, required this.onOpenExams});

  final List<MeasurementRound> rounds;
  final VoidCallback onOpenExams;

  @override
  State<_RoundsTab> createState() => _RoundsTabState();
}

class _RoundsTabState extends State<_RoundsTab> {
  late final Set<String> _open = {
    if (widget.rounds.isNotEmpty) widget.rounds.first.id,
  };

  void _toggle(String id) {
    setState(() {
      if (!_open.remove(id)) _open.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HealthSectionHeader(
          title: 'Kỳ cân đo',
          caption: 'Cô giáo cân đo trên lớp, thường 3 tháng một lần.',
        ),
        const SizedBox(height: AppSpacing.space3),
        if (widget.rounds.isEmpty)
          const AppEmptyState(
            icon: AppIcons.heart,
            title: 'Chưa có kết quả cân đo',
            message: 'Kết quả hiện ở đây ngay khi cô giáo lưu số đo trên lớp.',
          ),
        for (final round in widget.rounds) ...[
          _RoundTile(
            round: round,
            open: _open.contains(round.id),
            onToggle: () => _toggle(round.id),
          ),
          const SizedBox(height: AppSpacing.space3),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: AppLinkButton(
            label: 'Số đo khi khám sức khỏe xem ở tab Đợt khám ›',
            onPressed: widget.onOpenExams,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          'Kết quả đo do giáo viên công bố, chỉ để theo dõi, không thay thế chẩn đoán y tế.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _RoundTile extends StatelessWidget {
  const _RoundTile({
    required this.round,
    required this.open,
    required this.onToggle,
  });

  final MeasurementRound round;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = HealthLabels.bmiLevel(round.bmiLevel);
    final height = HealthLabels.number(round.heightCm);
    final weight = HealthLabels.number(round.weightKg);
    return AppCard(
      flush: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            child: AppListRow(
              title: round.name,
              // Nhãn BMI dưới dòng số đo để tên kỳ và số đo không bị bẻ dòng
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateLabels.date(round.date)} · $height cm · $weight kg',
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  AppStatusBadge(label: label, tone: tone),
                ],
              ),
              trailing: AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppMotion.fast,
                child: const Icon(
                  AppIcons.chevronDown,
                  size: AppSizes.iconNavigation,
                  color: AppColors.textMuted,
                ),
              ),
              onTap: onToggle,
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.cardPaddingDense,
                right: AppSpacing.cardPaddingDense,
                bottom: AppSpacing.cardPaddingDense,
              ),
              child: _RoundDetail(round: round, height: height, weight: weight),
            ),
        ],
      ),
    );
  }
}

class _RoundDetail extends StatelessWidget {
  const _RoundDetail({
    required this.round,
    required this.height,
    required this.weight,
  });

  final MeasurementRound round;
  final String height;
  final String weight;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (label, tone) = HealthLabels.bmiLevel(round.bmiLevel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HealthMetricRow(
          metrics: [
            HealthMetric('Chiều cao', '$height cm'),
            HealthMetric('Cân nặng', '$weight kg'),
            HealthMetric('BMI', HealthLabels.number(round.bmi)),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            Text('BMI theo tuổi', style: textTheme.titleSmall),
            AppStatusBadge(label: label, tone: tone),
          ],
        ),
        if (round.note case final note?) ...[
          const SizedBox(height: AppSpacing.space3),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardGap),
              child: Text.rich(
                TextSpan(
                  text: 'Ghi chú của cô: ',
                  style: textTheme.titleSmall,
                  children: [TextSpan(text: note, style: textTheme.bodyLarge)],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.space3),
        Text(
          'Ngày đo ${DateLabels.date(round.date)} · ${HealthLabels.age(round.ageMonths)} · đã công bố',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

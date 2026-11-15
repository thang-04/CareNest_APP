import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/nutrition_balance/data/fake_nutrition_balance_source.dart';
import 'package:carenest_app/features/nutrition_balance/domain/nutrition_balance.dart';

/// Phó HT · Cân đối dinh dưỡng ngày — mockup V07. Chỉ xem; số và nhãn "Đạt / Thiếu" do BE tính (NUT-06).
class NutritionBalanceScreen extends StatefulWidget {
  const NutritionBalanceScreen({
    super.key,
    required this.groupId,
    required this.day,
    this.campusId = 'campus-main',
    this.source = const FakeNutritionBalanceSource(),
  });

  final String groupId;
  final DateTime day;
  final String campusId;
  final NutritionBalanceSource source;

  @override
  State<NutritionBalanceScreen> createState() => _NutritionBalanceScreenState();
}

class _NutritionBalanceScreenState extends State<NutritionBalanceScreen> {
  late Future<NutritionBalance?> _data = _load();

  Future<NutritionBalance?> _load() => widget.source.load(
    campusId: widget.campusId,
    groupId: widget.groupId,
    day: widget.day,
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<NutritionBalance?>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cân đối dinh dưỡng'),
                if (data != null)
                  Text(
                    '${data.groupLabel} · ${DateLabels.weekdayDayMonth(data.date)} · chỉ xem',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          body: switch (snapshot) {
            AsyncSnapshot(hasError: true) => Center(
              child: AppErrorState(
                title: 'Chưa tải được cân đối dinh dưỡng',
                message: 'Kiểm tra kết nối mạng rồi thử lại.',
                onRetry: () => setState(() => _data = _load()),
              ),
            ),
            AsyncSnapshot(connectionState: ConnectionState.waiting) =>
              const Padding(
                padding: EdgeInsets.all(AppSpacing.pagePadding),
                child: AppSkeletonList(rows: 5),
              ),
            _ when data == null => const Center(
              child: AppEmptyState(
                icon: AppIcons.menuBook,
                title: 'Chưa có cân đối dinh dưỡng',
                message: 'Nhóm tuổi này không có thực đơn đã duyệt trong ngày.',
              ),
            ),
            _ => _Body(data: data),
          },
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data});

  final NutritionBalance data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = AppStatusColors.of(context);
    final success = status.feedbackOf(AppFeedback.success);
    final muted = textTheme.labelMedium?.copyWith(color: AppColors.textMuted);
    final number = textTheme.titleSmall?.copyWith(
      fontFeatures: AppTextStyles.tabularFigures,
    );
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Semantics(
          container: true,
          label: 'Năng lượng cả ngày: ${data.energy}. ${data.energyNote}',
          excludeSemantics: true,
          child: AppCard(
            dense: true,
            child: Column(
              // stretch: Wrap rộng hết thẻ thì spaceBetween mới dàn hai đầu
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: AppSpacing.space2,
                  children: [
                    Text('Năng lượng cả ngày', style: textTheme.titleSmall),
                    Text(
                      data.energy,
                      style: number?.copyWith(
                        color: data.energyMet
                            ? success.foreground
                            : status.tone(AppStatusTone.orange).foreground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: data.energyRatio.clamp(0, 1).toDouble(),
                    minHeight: 8,
                    color: data.energyMet
                        ? success.main
                        : status.tone(AppStatusTone.orange).main,
                    backgroundColor: status.track,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  data.energyNote,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        AppCard(
          dense: true,
          child: Column(
            children: [
              for (final (i, row) in data.nutrients.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpacing.space3),
                Semantics(
                  container: true,
                  label:
                      '${row.name}: ${row.value}, ${row.standard}, ${row.verdictLabel}',
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(row.name, style: textTheme.titleSmall),
                            Text(row.standard, style: muted),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          row.value,
                          textAlign: TextAlign.end,
                          style: textTheme.bodyMedium?.copyWith(
                            fontFeatures: AppTextStyles.tabularFigures,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      AppStatusBadge(
                        label: row.verdictLabel,
                        tone: row.verdict == NutrientVerdict.met
                            ? AppStatusTone.green
                            : AppStatusTone.orange,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space5),
        Semantics(
          header: true,
          child: Text('Năng lượng theo bữa', style: textTheme.titleSmall),
        ),
        const SizedBox(height: AppSpacing.space2),
        AppCard(
          dense: true,
          child: Column(
            children: [
              for (final (i, meal) in data.meals.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpacing.space3),
                Semantics(
                  container: true,
                  label: '${meal.mealLabel}: ${meal.energy}',
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      const Icon(
                        AppIcons.meal,
                        size: AppSizes.iconInline,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Text(meal.mealLabel, style: textTheme.bodyLarge),
                      ),
                      Text(meal.energy, style: number),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (data.warning case final warning?) ...[
          const SizedBox(height: AppSpacing.space4),
          AppBanner(kind: AppBannerKind.warning, message: warning),
        ],
      ],
    );
  }
}

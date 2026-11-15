import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/kitchen_meals/presentation/widgets/meal_count_table.dart';
import 'package:carenest_app/features/meal_count_confirm/data/fake_meal_count_confirm_source.dart';
import 'package:carenest_app/features/meal_count_confirm/domain/meal_count_draft.dart';

/// Phó HT · Chốt suất ăn trong ngày — mockup V04. Người xác nhận PENDING P-05 (mockup giao Phó HT).
/// Số do BE tổng hợp từ điểm danh; APP chỉ xem và gửi xác nhận.
class MealCountConfirmScreen extends StatefulWidget {
  const MealCountConfirmScreen({super.key, this.source});

  final MealCountConfirmSource? source;

  @override
  State<MealCountConfirmScreen> createState() => _MealCountConfirmScreenState();
}

class _MealCountConfirmScreenState extends State<MealCountConfirmScreen> {
  late final MealCountConfirmSource _source =
      widget.source ?? FakeMealCountConfirmSource.shared;
  late Future<MealCountDraft> _draft = _source.loadToday();
  bool _confirming = false;

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    try {
      final updated = await _source.confirm();
      if (!mounted) return;
      setState(() => _draft = Future.value(updated));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Chưa gửi được. Thử lại sau.')),
        );
      }
    }
    if (mounted) setState(() => _confirming = false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<MealCountDraft>(
      future: _draft,
      builder: (context, snapshot) {
        final draft = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chốt suất ăn'),
                if (draft != null)
                  Text(
                    '${DateLabels.weekdayDayMonth(draft.date)} · tổng hợp lúc ${DateLabels.time24(draft.summarizedAt)}',
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
                title: 'Chưa tải được số suất',
                message: 'Kiểm tra kết nối mạng rồi thử lại.',
                onRetry: () => setState(() => _draft = _source.loadToday()),
              ),
            ),
            _ when draft == null => const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 5),
            ),
            _ => ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                AppStatRow(
                  tiles: [
                    AppStatTile(
                      value: '${draft.total}',
                      label: 'Tổng suất',
                      tone: AppStatusTone.blue,
                    ),
                    AppStatTile(value: '${draft.regular}', label: 'Thường'),
                    AppStatTile(
                      value: '${draft.alternative}',
                      label: 'Thay thế',
                      tone: AppStatusTone.teal,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space3),
                if (draft.confirmedAt case final at?) ...[
                  AppBanner(
                    kind: AppBannerKind.success,
                    message:
                        'Đã gửi bếp lúc ${DateLabels.time24(at)} · ${draft.mealLabel} ${draft.total} suất',
                  ),
                  const SizedBox(height: AppSpacing.space3),
                ] else ...[
                  AppBanner(
                    kind: AppBannerKind.info,
                    message:
                        '${draft.mealLabel} · hạn xác nhận ${DateLabels.time24(draft.deadline)}',
                  ),
                  const SizedBox(height: AppSpacing.space3),
                ],
                MealCountTable(classes: draft.classes),
                if (draft.adjustmentNote case final note?) ...[
                  const SizedBox(height: AppSpacing.space3),
                  AppBanner(kind: AppBannerKind.warning, message: note),
                ],
                const SizedBox(height: AppSpacing.space3),
                Text(
                  'Số suất tự tổng hợp từ điểm danh, Phó HT chỉ xem và xác nhận. Sửa sau giờ chốt đi qua mục Yêu cầu chờ duyệt.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          },
          bottomNavigationBar: draft == null || draft.confirmed
              ? null
              : AppBottomDock(
                  children: [
                    AppButton(
                      label: 'Xác nhận gửi bếp (${draft.total} suất)',
                      loadingLabel: 'Đang gửi bếp',
                      isLoading: _confirming,
                      expand: true,
                      onPressed: _confirm,
                    ),
                  ],
                ),
        );
      },
    );
  }
}

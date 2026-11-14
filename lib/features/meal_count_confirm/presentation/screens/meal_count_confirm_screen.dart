import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/features/kitchen_meals/domain/kitchen_meals.dart';
import 'package:carenest_app/features/meal_count_confirm/data/fake_meal_count_confirm_source.dart';
import 'package:carenest_app/features/meal_count_confirm/domain/meal_count_draft.dart';
import 'package:carenest_app/features/vice_principal_home/presentation/widgets/stat_strip.dart';

/// Phó HT · Số suất hôm nay — Figma PHT 04, chỉ xem (AUTH-21, BE ADR-0026). Số do BE tổng hợp từ điểm danh (NUT-01);
/// PHT xác nhận gửi bếp trên CareNest Web (NUT-02), App chỉ hiện trạng thái.
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = AppStatusColors.of(context);
    return FutureBuilder<MealCountDraft>(
      future: _draft,
      builder: (context, snapshot) {
        final draft = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Số suất hôm nay'),
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
                StatStrip(
                  tinted: true,
                  items: [
                    StatStripItem(
                      value: '${draft.total}',
                      label: 'Tổng suất',
                      color: AppColors.primary,
                    ),
                    StatStripItem(value: '${draft.regular}', label: 'Thường'),
                    StatStripItem(
                      value: '${draft.alternative}',
                      label: 'Thay thế',
                      color: status.tone(AppStatusTone.teal).foreground,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space3),
                _ClassCountTable(classes: draft.classes),
                if (draft.adjustmentNote case final note?) ...[
                  const SizedBox(height: AppSpacing.space3),
                  AppBanner(kind: AppBannerKind.warning, message: note),
                ],
                const SizedBox(height: AppSpacing.space4),
                // Trạng thái xác nhận đặt dưới bảng như mockup PHT 04
                if (draft.confirmedAt case final at?)
                  AppBanner(
                    kind: AppBannerKind.success,
                    message:
                        'Đã xác nhận gửi bếp lúc ${DateLabels.time24(at)} · ${draft.mealLabel} ${draft.total} suất',
                  )
                else
                  const AppBanner(
                    kind: AppBannerKind.warning,
                    message: 'Chưa xác nhận — xác nhận trên CareNest Web',
                  ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  'Chỉ xem. Số suất tự tổng hợp từ điểm danh; xác nhận gửi bếp và mở lại điểm danh thực hiện trên CareNest Web.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          },
        );
      },
    );
  }
}

/// Bảng suất theo lớp của PHT 04: ghi chú dị ứng dưới tên lớp, lớp có điều chỉnh (NUT-04) tô nền cam.
/// Số và ghi chú do BE trả; không tên trẻ.
class _ClassCountTable extends StatelessWidget {
  const _ClassCountTable({required this.classes});

  final List<ClassMealCount> classes;

  static const _classFlex = 5;
  static const _numberFlex = 3;

  @override
  Widget build(BuildContext context) {
    final header = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted);
    return AppCard(
      flush: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                AppSpacing.space3 + 2,
                AppSpacing.space4,
                AppSpacing.space2,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: _classFlex,
                    child: Text('LỚP', style: header),
                  ),
                  Expanded(
                    flex: _numberFlex,
                    child: Text(
                      'THƯỜNG',
                      textAlign: TextAlign.center,
                      style: header,
                    ),
                  ),
                  Expanded(
                    flex: _numberFlex,
                    child: Text(
                      'THAY THẾ',
                      textAlign: TextAlign.end,
                      style: header,
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final (i, row) in classes.indexed) ...[
            // Dòng tô nền đã tự tách ⇒ bỏ kẻ quanh nó
            if (!row.changed && !(i > 0 && classes[i - 1].changed))
              const Divider(
                indent: AppSpacing.space4,
                endIndent: AppSpacing.space4,
              ),
            _ClassCountRow(row: row),
          ],
          const SizedBox(height: AppSpacing.space1),
        ],
      ),
    );
  }
}

class _ClassCountRow extends StatelessWidget {
  const _ClassCountRow({required this.row});

  final ClassMealCount row;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final teal = AppStatusColors.of(context).tone(AppStatusTone.teal);
    final number = textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      fontFeatures: AppTextStyles.tabularFigures,
    );
    final note = row.note;
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: _ClassCountTable._classFlex,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(row.className, style: textTheme.titleSmall),
              if (note != null && note.isNotEmpty)
                Text(
                  '${note[0].toUpperCase()}${note.substring(1)}',
                  style: textTheme.labelMedium?.copyWith(
                    color: teal.foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          flex: _ClassCountTable._numberFlex,
          child: Text(
            '${row.regular}',
            textAlign: TextAlign.center,
            style: number,
          ),
        ),
        Expanded(
          flex: _ClassCountTable._numberFlex,
          child: Text(
            '${row.alternative}',
            textAlign: TextAlign.end,
            style: number?.copyWith(
              color: teal.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
    return Semantics(
      container: true,
      label: [
        row.className,
        '${row.regular} suất thường',
        '${row.alternative} suất thay thế',
        ?note,
        if (row.changed) 'có điều chỉnh',
      ].join(', '),
      excludeSemantics: true,
      child: row.changed
          // Lớp có số đổi do GV sửa điểm danh (NUT-04): dải nền cam lùi vào trong card, chữ vẫn thẳng cột
          ? Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space1 + 2,
                vertical: 2,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2 + 2,
                vertical: AppSpacing.space2,
              ),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: content,
            )
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space3,
              ),
              child: content,
            ),
    );
  }
}

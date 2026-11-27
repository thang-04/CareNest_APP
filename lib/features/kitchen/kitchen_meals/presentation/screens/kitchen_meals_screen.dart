import 'package:flutter/material.dart';

import 'package:carenest_app/core/integration/load_failure.dart';
import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/kitchen/kitchen_meals/data/fake_kitchen_meals_source.dart';
import 'package:carenest_app/features/kitchen/kitchen_meals/domain/kitchen_meals.dart';
import 'package:carenest_app/features/kitchen/kitchen_meals/presentation/widgets/meal_count_table.dart';

/// Suất ăn đã chốt theo lớp từng bữa (BE `KitchenDayResponse.servings`). Chỉ xem, chỉ số đã xác
/// nhận (NUT-02, NUT-03); không có tên trẻ (AUTH-05). Số đổi chỉ khi PHT xác nhận lại.
class KitchenMealsScreen extends StatefulWidget {
  const KitchenMealsScreen({super.key, this.source});

  final KitchenMealsSource? source;

  @override
  State<KitchenMealsScreen> createState() => _KitchenMealsScreenState();
}

class _KitchenMealsScreenState extends State<KitchenMealsScreen> {
  late final KitchenMealsSource _source =
      widget.source ?? FakeKitchenMealsSource();
  late Future<MealCountSheet?> _sheet = _source.loadSheet();

  /// Bữa đang xem; chưa chọn ⇒ bữa đầu tiên đã xác nhận
  String? _session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suất ăn theo lớp')),
      body: FutureBuilder<MealCountSheet?>(
        future: _sheet,
        builder: (context, snapshot) {
          final sheet = snapshot.data;
          return switch (snapshot) {
            AsyncSnapshot(hasError: true) => Center(
              child: AppErrorState(
                title: 'Chưa tải được suất ăn',
                message: loadFailureMessage(snapshot.error),
                onRetry: () => setState(() {
                  _sheet = _source.loadSheet();
                }),
              ),
            ),
            AsyncSnapshot(connectionState: ConnectionState.waiting) =>
              const Padding(
                padding: EdgeInsets.all(AppSpacing.pagePadding),
                child: AppSkeletonList(rows: 5),
              ),
            _ when sheet == null || sheet.sessions.isEmpty => const Center(
              child: AppEmptyState(
                icon: AppIcons.meal,
                title: 'Chưa có số suất đã chốt',
                message:
                    'Số suất hiện khi PHT xác nhận. Chưa có số thì chưa nấu theo số nào.',
              ),
            ),
            _ => _SheetBody(
              sheet: sheet,
              session:
                  sheet.sessions
                      .where((item) => item.session == _session)
                      .firstOrNull ??
                  sheet.sessions.first,
              onSelect: (session) => setState(() {
                _session = session;
              }),
            ),
          };
        },
      ),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.sheet,
    required this.session,
    required this.onSelect,
  });

  final MealCountSheet sheet;
  final SessionMealCount session;
  final ValueChanged<String> onSelect;

  /// Nhãn ngắn cho thanh chọn bữa, như Cấu hình thời gian trên web
  static String _short(SessionMealCount item) => switch (item.session) {
    'MORNING' => 'Phụ sáng',
    'LUNCH' => 'Trưa',
    'AFTERNOON' => 'Chiều',
    _ => item.label,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final block = session.blockNote;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Text(
          'PHT xác nhận ${DateLabels.time24(sheet.confirmedAt)} · chỉ xem',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        if (sheet.sessions.length > 1) ...[
          const SizedBox(height: AppSpacing.space3),
          AppSegmented<String>(
            segments: [
              for (final item in sheet.sessions) (item.session, _short(item)),
            ],
            selected: session.session,
            onChanged: onSelect,
          ),
        ],
        const SizedBox(height: AppSpacing.space4),
        Semantics(
          header: true,
          child: Text(
            [session.label, ?block].join(' · '),
            style: textTheme.titleMedium,
          ),
        ),
        if (block != null)
          Text(
            'Chỉ lớp $block ăn bữa này.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        const SizedBox(height: AppSpacing.space3),
        AppStatRow(
          tiles: [
            AppStatTile(
              value: '${session.total}',
              label: 'Tổng suất',
              tone: AppStatusTone.blue,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        MealCountTable(
          classes: session.classes,
          // NUT-23 (25/11): bếp không còn suất thay thế
          showAlternative: false,
          footer: 'Chỉ xem. Số đổi khi PHT xác nhận lại điểm danh.',
        ),
      ],
    );
  }
}

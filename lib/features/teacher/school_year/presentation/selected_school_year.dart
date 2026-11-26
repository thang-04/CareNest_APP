import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_bottom_sheet.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher/school_year/data/fake_school_year_source.dart';
import 'package:carenest_app/features/teacher/school_year/domain/school_year.dart';

/// Năm học đang chọn — dùng chung các màn GV như ô "Năm học" trên Web (SchoolYearContext):
/// mặc định năm đang chạy; đăng xuất ⇒ về mặc định.
abstract final class SelectedSchoolYear {
  static final notifier = ValueNotifier<SchoolYear>(
    FakeSchoolYearSource.years.firstWhere(
      (year) => year.status == SchoolYearStatus.active,
    ),
  );

  static SchoolYear get value => notifier.value;

  /// `schoolYearId` gửi BE: null ⇒ BE lấy năm đang chạy; năm đã đóng / sắp tới gửi id.
  static String? get apiYearId =>
      value.status == SchoolYearStatus.active ? null : value.id;

  /// Nguồn danh sách năm cho [SchoolYearChip]; phiên thật đặt bản gọi BE.
  static SchoolYearSource source = const FakeSchoolYearSource();

  static void reset() {
    source = const FakeSchoolYearSource();
    notifier.value = FakeSchoolYearSource.years.firstWhere(
      (year) => year.status == SchoolYearStatus.active,
    );
  }
}

/// Ô chọn năm học: "Năm học 2026–2027"; năm đã đóng kèm nhãn "Chỉ xem".
class SchoolYearChip extends StatelessWidget {
  const SchoolYearChip({super.key, this.source});

  /// null ⇒ [SelectedSchoolYear.source].
  final SchoolYearSource? source;

  Future<void> _pick(BuildContext context) async {
    final years = await (source ?? SelectedSchoolYear.source).loadYears();
    if (!context.mounted) return;
    final picked = await showAppBottomSheet<SchoolYear>(
      context: context,
      title: 'Chọn năm học',
      builder: (sheetContext) => Column(
        children: [
          for (final year in years)
            AppSheetOption(
              selected: year.id == SelectedSchoolYear.value.id,
              onTap: () => Navigator.of(sheetContext).pop(year),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Năm học ${year.label}',
                          style: Theme.of(sheetContext).textTheme.titleSmall,
                        ),
                        Text(
                          'Lớp ${year.className}',
                          style: Theme.of(sheetContext).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (year.readOnly)
                    const AppStatusBadge(
                      label: 'Chỉ xem',
                      tone: AppStatusTone.gray,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked != null) SelectedSchoolYear.notifier.value = picked;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SchoolYear>(
      valueListenable: SelectedSchoolYear.notifier,
      builder: (context, year, _) => Wrap(
        spacing: AppSpacing.space2,
        runSpacing: AppSpacing.space2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppFilterChip(
            label: 'Năm học ${year.label}',
            icon: AppIcons.calendar,
            selected: false,
            onSelected: () => _pick(context),
          ),
          if (year.readOnly)
            const AppStatusBadge(label: 'Chỉ xem', tone: AppStatusTone.gray),
        ],
      ),
    );
  }
}

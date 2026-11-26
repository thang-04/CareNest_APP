import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_context_chip.dart';
import 'package:carenest_app/features/teacher/shared/class_option.dart';

/// Thanh "Lớp · Ngày": mỗi giáo viên chỉ một lớp (user 26/11) nên chip lớp chỉ hiện tên,
/// không đổi lớp; chip ngày chọn tối đa hôm nay. Ngày khác hôm nay ⇒ màn chỉ xem.
class ClassDateBar extends StatelessWidget {
  const ClassDateBar({
    super.key,
    required this.classes,
    required this.classId,
    required this.date,
    required this.today,
    @Deprecated('Mỗi giáo viên một lớp: không còn đổi lớp') this.onClassChanged,
    this.onDateChanged,
  });

  final List<ClassOption> classes;
  final String classId;
  final DateTime date;

  /// Hôm nay theo giờ nhà trường; ngày chọn không vượt quá mốc này.
  final DateTime today;
  final ValueChanged<String>? onClassChanged; // ignore: unreachable_from_main
  final ValueChanged<DateTime>? onDateChanged;

  bool get _isToday =>
      date.year == today.year &&
      date.month == today.month &&
      date.day == today.day;

  ClassOption? get _current =>
      classes.where((item) => item.id == classId).firstOrNull;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date.isAfter(today) ? today : date,
      firstDate: DateTime(today.year - 2),
      lastDate: today,
      helpText: 'Chọn ngày',
    );
    if (picked != null) {
      onDateChanged?.call(DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppContextChip(
          label: current == null ? 'Lớp' : current.name,
          leading: const Icon(AppIcons.classGroup, size: 20),
          onTap: null,
        ),
        AppContextChip(
          label: _isToday ? 'Hôm nay' : DateLabels.date(date),
          leading: const Icon(AppIcons.calendar, size: 20),
          onTap: onDateChanged == null ? null : () => _pickDate(context),
        ),
      ],
    );
  }
}

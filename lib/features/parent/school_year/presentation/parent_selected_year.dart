import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/integration/load_failure.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_bottom_sheet.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/parent/school_year/domain/child_school_year.dart';

/// Năm học phụ huynh đang chọn, nhớ riêng từng bé (như ô "Năm học" Web/GV): mặc định năm đang chạy,
/// bé không học năm đang chạy ⇒ năm mới nhất; đăng xuất ⇒ xóa (AUTH-22).
abstract final class ParentSelectedYear {
  static final changes = ChangeNotifier();
  static final Map<String, String> _byChild = {};

  /// Năm đang chọn của bé trong [years] (BE xếp mới trước); null khi bé chưa có năm nào.
  static ChildSchoolYear? of(String childId, List<ChildSchoolYear> years) {
    final picked = _byChild[childId];
    return years.where((year) => year.id == picked).firstOrNull ??
        years
            .where((year) => year.status == ChildSchoolYearStatus.active)
            .firstOrNull ??
        years
            .where((year) => year.status != ChildSchoolYearStatus.planned)
            .firstOrNull ??
        years.firstOrNull;
  }

  static void select(String childId, String yearId) {
    _byChild[childId] = yearId;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    changes.notifyListeners();
  }

  static void reset() {
    _byChild.clear();
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    changes.notifyListeners();
  }
}

/// Năm học đang chọn cho cây màn dưới [ParentYearGate].
class ParentYearScope extends InheritedWidget {
  const ParentYearScope({
    super.key,
    required this.childId,
    required this.year,
    required this.years,
    required super.child,
  });

  final String childId;
  final ChildSchoolYear year;
  final List<ChildSchoolYear> years;

  static ParentYearScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ParentYearScope>();

  @override
  bool updateShouldNotify(ParentYearScope oldWidget) =>
      oldWidget.year.id != year.id || oldWidget.years != years;
}

/// Tải năm học của bé rồi dựng màn với năm đang chọn; đổi năm ⇒ dựng lại màn (tải lại dữ liệu năm đó).
class ParentYearGate extends StatefulWidget {
  const ParentYearGate({
    super.key,
    required this.childId,
    required this.source,
    required this.builder,
    this.title = '',
  });

  final String childId;
  final ChildSchoolYearSource source;
  final Widget Function(ChildSchoolYear year) builder;

  /// Tiêu đề thanh trên khi chưa có màn (đang tải, lỗi, chưa có năm).
  final String title;

  @override
  State<ParentYearGate> createState() => _ParentYearGateState();
}

class _ParentYearGateState extends State<ParentYearGate> {
  late Future<List<ChildSchoolYear>> _years = widget.source.loadYears(
    widget.childId,
  );

  @override
  void didUpdateWidget(ParentYearGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Đổi bé ⇒ tải năm của bé mới; kết quả của bé cũ không được dùng
    if (oldWidget.childId != widget.childId) {
      _years = widget.source.loadYears(widget.childId);
    }
  }

  Widget _frame(Widget body) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: body,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ChildSchoolYear>>(
      future: _years,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _frame(
            AppErrorState(
              title: 'Chưa tải được năm học của bé',
              message: loadFailureMessage(snapshot.error),
              onRetry: () => setState(
                () => _years = widget.source.loadYears(widget.childId),
              ),
            ),
          );
        }
        final years = snapshot.data;
        if (years == null) {
          return _frame(
            const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 3),
            ),
          );
        }
        return ListenableBuilder(
          listenable: ParentSelectedYear.changes,
          builder: (context, _) {
            final year = ParentSelectedYear.of(widget.childId, years);
            if (year == null) {
              return _frame(
                const AppEmptyState(
                  title: 'Bé chưa có năm học',
                  message: 'Khi bé được xếp lớp, dữ liệu sẽ hiện ở đây.',
                ),
              );
            }
            return ParentYearScope(
              childId: widget.childId,
              year: year,
              years: years,
              child: KeyedSubtree(
                key: ValueKey('${widget.childId}/${year.id}'),
                child: widget.builder(year),
              ),
            );
          },
        );
      },
    );
  }
}

/// Ô chọn năm học: "Năm học 2026–2027"; năm không đang chạy kèm nhãn "Chỉ xem". Không có
/// [ParentYearScope] (Xem thử ngoài cổng) ⇒ không hiện.
class ParentYearChip extends StatelessWidget {
  const ParentYearChip({super.key});

  Future<void> _pick(BuildContext context, ParentYearScope scope) async {
    final picked = await showAppBottomSheet<ChildSchoolYear>(
      context: context,
      title: 'Chọn năm học',
      builder: (sheetContext) => Column(
        children: [
          for (final year in scope.years)
            AppSheetOption(
              selected: year.id == scope.year.id,
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
                        if (year.className.isNotEmpty)
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
    if (picked != null) ParentSelectedYear.select(scope.childId, picked.id);
  }

  @override
  Widget build(BuildContext context) {
    final scope = ParentYearScope.maybeOf(context);
    if (scope == null) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppFilterChip(
          label: 'Năm học ${scope.year.label}',
          icon: AppIcons.calendar,
          selected: false,
          onSelected: () => _pick(context, scope),
        ),
        if (scope.year.readOnly)
          const AppStatusBadge(label: 'Chỉ xem', tone: AppStatusTone.gray),
      ],
    );
  }
}

/// Ô Năm học đứng riêng (Bé của tôi): tự tải năm của bé; chọn năm ⇒ các màn theo năm của bé dùng năm đó.
/// Đang tải / lỗi / chưa có năm ⇒ không hiện ô.
class ParentYearPicker extends StatefulWidget {
  const ParentYearPicker({
    super.key,
    required this.childId,
    required this.source,
  });

  final String childId;
  final ChildSchoolYearSource source;

  @override
  State<ParentYearPicker> createState() => _ParentYearPickerState();
}

class _ParentYearPickerState extends State<ParentYearPicker> {
  late Future<List<ChildSchoolYear>> _years = widget.source.loadYears(
    widget.childId,
  );

  @override
  void didUpdateWidget(ParentYearPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.childId != widget.childId) {
      _years = widget.source.loadYears(widget.childId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ChildSchoolYear>>(
      future: _years,
      builder: (context, snapshot) {
        final years = snapshot.data;
        if (years == null) return const SizedBox.shrink();
        return ListenableBuilder(
          listenable: ParentSelectedYear.changes,
          builder: (context, _) {
            final year = ParentSelectedYear.of(widget.childId, years);
            if (year == null) return const SizedBox.shrink();
            return ParentYearScope(
              childId: widget.childId,
              year: year,
              years: years,
              child: const ParentYearChip(),
            );
          },
        );
      },
    );
  }
}

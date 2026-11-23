import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_bottom_sheet.dart';
import 'package:carenest_app/core/widgets/app_search_field.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/parent/evaluation/data/fake_evaluation_source.dart';
import 'package:carenest_app/features/parent/evaluation/domain/evaluation.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/screens/evaluation_screen.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/widgets/evaluation_day_tab.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/widgets/evaluation_semester_tab.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/widgets/evaluation_themes_tab.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/widgets/evaluation_week_tab.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/widgets/evaluation_year_end_tab.dart';
import 'package:carenest_app/features/parent/parent_home/domain/parent_today.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/class_roster/domain/class_roster.dart';

/// GV · Đánh giá một bé — CHỈ XEM (đánh giá nhập trên Web). Cùng giao diện trang Đánh giá
/// của phụ huynh (5 mục Ngày | Tuần | Chủ đề | Học kỳ | Cuối năm, dùng lại các tab của
/// phụ huynh) để hai bên đồng nhất; thêm đổi bé nhanh trong lớp (‹ › và ô chọn bé).
/// Dữ liệu giả `FakeEvaluationSource`, chưa nối BE.
class KidEvaluationScreen extends StatefulWidget {
  const KidEvaluationScreen({
    super.key,
    required this.childId,
    required this.onOpenTheme,
    this.initialTab = EvaluationTab.day,
    this.classId = FakeClassRosterSource.classId,
    this.rosterSource,
    this.source = const FakeEvaluationSource(),
  });

  final String childId;

  /// Mở kết quả một chủ đề của bé đang xem: (childId, themeId).
  final void Function(String childId, String themeId) onOpenTheme;
  final EvaluationTab initialTab;
  final String classId;
  final ClassRosterSource? rosterSource;
  final EvaluationSource source;

  /// Bé trong lớp ⇒ `ChildSummary` dùng chung với màn phụ huynh.
  static ChildSummary summaryOf(RosterKid kid, ClassRoster roster) =>
      ChildSummary(
        id: kid.id,
        fullName: kid.fullName,
        shortName: kid.shortName,
        className: roster.className,
        campusName: roster.campusName,
        ageLabel: kid.ageLabel,
        homeroomTeacher: '',
      );

  @override
  State<KidEvaluationScreen> createState() => _KidEvaluationScreenState();
}

class _KidEvaluationScreenState extends State<KidEvaluationScreen> {
  late final ClassRosterSource _roster =
      widget.rosterSource ?? FakeClassRosterSource();
  late final Future<ClassRoster> _class = _roster.loadRoster(widget.classId);
  late String _childId = widget.childId;
  late Future<EvaluationBook> _book = widget.source.load(_childId);
  late EvaluationTab _tab = widget.initialTab;

  void _show(String childId) {
    if (childId == _childId) return;
    setState(() {
      _childId = childId;
      _book = widget.source.load(childId);
    });
  }

  Future<void> _pickKid(ClassRoster roster) async {
    final picked = await showAppBottomSheet<String>(
      context: context,
      title: 'Chọn bé',
      builder: (sheetContext) => _KidPicker(
        kids: roster.kids,
        selectedId: _childId,
        onPicked: (id) => Navigator.of(sheetContext).pop(id),
      ),
    );
    if (picked != null && mounted) _show(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá')),
      body: FutureBuilder<ClassRoster>(
        future: _class,
        builder: (context, rosterSnap) {
          final roster = rosterSnap.data;
          return FutureBuilder<EvaluationBook>(
            future: _book,
            builder: (context, snapshot) {
              if (snapshot.hasError || rosterSnap.hasError) {
                return Center(
                  child: AppErrorState(
                    title: 'Chưa tải được đánh giá',
                    message: 'Kiểm tra kết nối mạng rồi thử lại.',
                    onRetry: () => setState(() {
                      _book = widget.source.load(_childId);
                    }),
                  ),
                );
              }
              final book = snapshot.data;
              if (book == null || roster == null) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.pagePadding),
                  child: AppSkeletonList(rows: 4),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                children: [
                  _KidSwitcher(
                    roster: roster,
                    childId: _childId,
                    onShow: _show,
                    onPick: () => _pickKid(roster),
                  ),
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
                  // Đổi bé ⇒ tab tạo lại, không giữ tuần/kỳ đang xem của bé trước
                  KeyedSubtree(
                    key: ValueKey('$_childId-${_tab.name}'),
                    child: switch (_tab) {
                      EvaluationTab.day => EvaluationDayTab(weeks: book.weeks),
                      EvaluationTab.week => EvaluationWeekTab(
                        comments: book.weeklyComments,
                      ),
                      EvaluationTab.theme => EvaluationThemesTab(
                        themes: book.themes,
                        onOpenTheme: (themeId) =>
                            widget.onOpenTheme(_childId, themeId),
                      ),
                      EvaluationTab.semester => EvaluationSemesterTab(
                        semesters: book.semesters,
                      ),
                      EvaluationTab.yearEnd => EvaluationYearEndTab(
                        yearEnd: book.yearEnd,
                      ),
                    },
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    'Chỉ xem · đánh giá trên Web.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Bé đang xem + ‹ › sang bé trước/sau trong lớp; chạm tên mở danh sách chọn bé.
class _KidSwitcher extends StatelessWidget {
  const _KidSwitcher({
    required this.roster,
    required this.childId,
    required this.onShow,
    required this.onPick,
  });

  final ClassRoster roster;
  final String childId;
  final ValueChanged<String> onShow;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final kids = roster.kids;
    final index = kids.indexWhere((kid) => kid.id == childId);
    final kid = index < 0 ? null : kids[index];
    return Row(
      children: [
        IconButton(
          tooltip: 'Bé trước',
          icon: const Icon(AppIcons.back),
          onPressed: index > 0 ? () => onShow(kids[index - 1].id) : null,
        ),
        Expanded(
          child: Semantics(
            button: true,
            label: 'Chọn bé khác',
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: onPick,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSizes.minimumTapTarget,
                ),
                child: Row(
                  children: [
                    AppAvatar(name: kid?.fullName ?? ''),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kid?.fullName ?? '',
                            style: textTheme.titleSmall,
                          ),
                          Text(
                            '${roster.className} · ${index + 1}/${kids.length}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      AppIcons.chevronDown,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Bé sau',
          icon: const Icon(AppIcons.chevronRight),
          onPressed: index >= 0 && index < kids.length - 1
              ? () => onShow(kids[index + 1].id)
              : null,
        ),
      ],
    );
  }
}

class _KidPicker extends StatefulWidget {
  const _KidPicker({
    required this.kids,
    required this.selectedId,
    required this.onPicked,
  });

  final List<RosterKid> kids;
  final String selectedId;
  final ValueChanged<String> onPicked;

  @override
  State<_KidPicker> createState() => _KidPickerState();
}

class _KidPickerState extends State<_KidPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final kids = widget.kids
        .where((kid) => kid.fullName.toLowerCase().contains(query))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSearchField(
          hint: 'Tìm tên bé…',
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: AppSpacing.space2),
        for (final kid in kids)
          AppSheetOption(
            selected: kid.id == widget.selectedId,
            leading: AppAvatar(name: kid.fullName),
            onTap: () => widget.onPicked(kid.id),
            child: Text(kid.fullName),
          ),
      ],
    );
  }
}

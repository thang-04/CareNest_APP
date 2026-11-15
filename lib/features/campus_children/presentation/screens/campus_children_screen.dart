import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_bottom_sheet.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_coming_soon.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_search_field.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/campus_children/data/fake_campus_children_source.dart';
import 'package:carenest_app/features/campus_children/domain/campus_children.dart';
import 'package:carenest_app/features/class_roster/domain/class_roster.dart';
import 'package:carenest_app/features/class_roster/presentation/screens/class_roster_screen.dart';

enum _TagFilter { all, allergy, diet }

/// Phó HT · Trẻ của cơ sở (chỉ xem) — mockup V10. Chỉ trẻ thuộc cơ sở được phân công (AUTH-02);
/// ghi chú dị ứng / chế độ ăn là mã BE trả (HLT-06). Thêm trẻ, xếp lớp làm trên Web.
class CampusChildrenScreen extends StatefulWidget {
  const CampusChildrenScreen({
    super.key,
    this.campusId = 'campus-main',
    this.title = 'Trẻ của cơ sở',
    this.initialClassId,
    this.source,
  });

  final String campusId;
  final String title;

  /// Mở sẵn một lớp (Hiệu trưởng chạm lớp ở danh sách toàn trường).
  final String? initialClassId;
  final CampusChildrenSource? source;

  @override
  State<CampusChildrenScreen> createState() => _CampusChildrenScreenState();
}

class _CampusChildrenScreenState extends State<CampusChildrenScreen> {
  late final CampusChildrenSource _source =
      widget.source ?? FakeCampusChildrenSource();
  late Future<CampusChildren> _data = _source.load(widget.campusId);
  String _query = '';
  late String? _classId = widget.initialClassId;
  _TagFilter _tag = _TagFilter.all;

  bool _matchesTag(CampusChild child) => switch (_tag) {
    _TagFilter.all => true,
    _TagFilter.allergy => child.tag?.kind == RosterTagKind.allergy,
    _TagFilter.diet => child.tag?.kind == RosterTagKind.diet,
  };

  void _pickClass(CampusChildren data) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Chọn lớp',
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (id, label) in [
            (null, 'Tất cả các lớp (${data.classes.length} lớp)'),
            for (final item in data.classes) (item.id, item.name),
          ])
            AppSheetOption(
              selected: _classId == id,
              onTap: () {
                setState(() => _classId = id);
                Navigator.of(sheetContext).pop();
              },
              child: Text(label),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<CampusChildren>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        // Lớp không thuộc cơ sở (ID cũ, sai) ⇒ coi như chưa chọn lớp
        final classId =
            data?.classes.any((item) => item.id == _classId) ?? false
            ? _classId
            : null;
        final inClass = data?.children
            .where((child) => classId == null || child.classId == classId)
            .toList();
        final visible = inClass
            ?.where(
              (child) =>
                  _matchesTag(child) && matchesSearch(child.fullName, _query),
            )
            .toList();
        final header = <Widget>[
          AppSearchField(
            hint: 'Tìm tên bé…',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: AppSpacing.space3),
          if (data != null && inClass != null) ...[
            AppSelectField(
              label: 'Lớp',
              value:
                  data.classes
                      .where((item) => item.id == classId)
                      .firstOrNull
                      ?.name ??
                  'Tất cả các lớp (${data.classes.length} lớp)',
              onTap: () => _pickClass(data),
            ),
            const SizedBox(height: AppSpacing.space2),
            Wrap(
              spacing: AppSpacing.space2,
              children: [
                for (final (filter, label) in [
                  (_TagFilter.all, 'Tất cả'),
                  (
                    _TagFilter.allergy,
                    'Dị ứng (${inClass.where((child) => child.tag?.kind == RosterTagKind.allergy).length})',
                  ),
                  (
                    _TagFilter.diet,
                    'Ăn kiêng (${inClass.where((child) => child.tag?.kind == RosterTagKind.diet).length})',
                  ),
                ])
                  AppFilterChip(
                    label: label,
                    selected: _tag == filter,
                    onSelected: () => setState(() => _tag = filter),
                  ),
              ],
            ),
          ],
        ];
        final Widget list;
        if (snapshot.hasError) {
          list = ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              AppErrorState(
                title: 'Chưa tải được danh sách trẻ',
                message: 'Kiểm tra kết nối mạng rồi thử lại.',
                onRetry: () =>
                    setState(() => _data = _source.load(widget.campusId)),
              ),
            ],
          );
        } else if (visible == null) {
          list = const Padding(
            padding: EdgeInsets.all(AppSpacing.pagePadding),
            child: AppSkeletonList(rows: 6),
          );
        } else {
          final empty = visible.isEmpty ? 1 : 0;
          // Danh sách cả cơ sở ⇒ dựng theo nhu cầu, key theo ID trẻ; +1 dòng ghi chú cuối
          list = ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.space2,
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
            ),
            itemCount: visible.length + empty + 1,
            itemBuilder: (context, i) {
              if (i < visible.length) {
                return _ChildRow(
                  key: ValueKey(visible[i].id),
                  child: visible[i],
                );
              }
              if (empty == 1 && i == visible.length) {
                return AppEmptyState(
                  title: 'Không có bé nào khớp',
                  message: _query.isEmpty
                      ? 'Không có bé nào theo bộ lọc đang chọn.'
                      : 'Không tìm thấy “$_query” theo bộ lọc đang chọn.',
                );
              }
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.space2),
                child: Text(
                  'Chạm một bé để xem hồ sơ. Thêm trẻ, xếp lớp, nhập Excel thực hiện trên CareNest Web.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              );
            },
          );
        }
        // Ô tìm và bộ lọc nằm ngoài danh sách: cuộn không làm mất chữ đang gõ
        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.pagePadding,
                AppSpacing.pagePadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: header,
              ),
            ),
            Expanded(child: list),
          ],
        );
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              if (data != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.space4),
                  child: Center(
                    child: Text(
                      // Mở từ một lớp ⇒ sĩ số lớp; còn lại ⇒ cả cơ sở
                      '${(widget.initialClassId != null ? inClass : null)?.length ?? data.children.length} bé',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: body,
        );
      },
    );
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({super.key, required this.child});

  final CampusChild child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: AppCard(
        flush: true,
        child: AppListRow(
          leading: AppAvatar(name: child.fullName),
          title: child.fullName,
          subtitle: Text('${child.className} · ${child.ageLabel}'),
          trailing: child.tag == null
              ? null
              : AppStatusBadge(label: child.tag!.label, tone: child.tag!.tone),
          onTap: () => openComingSoon(context, child.fullName),
        ),
      ),
    );
  }
}

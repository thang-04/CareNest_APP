import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_coming_soon.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_search_field.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/campus_children/data/fake_campus_children_source.dart';
import 'package:carenest_app/features/campus_children/domain/campus_children.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Hiệu trưởng · Danh sách trẻ toàn trường — mockup H06 (AUTH-01). Danh sách lớp theo cơ sở;
/// gõ tìm ⇒ thêm trẻ khớp tên. Chạm lớp ⇒ trẻ của lớp; thêm trẻ, xếp lớp làm trên Web.
class SchoolChildrenScreen extends StatefulWidget {
  const SchoolChildrenScreen({
    super.key,
    this.campusIds = const [
      FakeCampusChildrenSource.mainCampusId,
      FakeCampusChildrenSource.secondCampusId,
    ],
    this.source,
  });

  final List<String> campusIds;
  final CampusChildrenSource? source;

  @override
  State<SchoolChildrenScreen> createState() => _SchoolChildrenScreenState();
}

class _SchoolChildrenScreenState extends State<SchoolChildrenScreen> {
  late final CampusChildrenSource _source =
      widget.source ?? FakeCampusChildrenSource();
  late Future<List<(String, CampusChildren)>> _data = _load();
  String? _campusId;
  String _query = '';

  Future<List<(String, CampusChildren)>> _load() => Future.wait([
    for (final id in widget.campusIds)
      _source.load(id).then((data) => (id, data)),
  ]);

  // "Cơ sở chính – Thượng Hồng" ⇒ "Cơ sở chính"
  static String _short(String campusName) => campusName.split(' – ').first;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<List<(String, CampusChildren)>>(
      future: _data,
      builder: (context, snapshot) {
        final campuses = snapshot.data;
        final total = campuses?.fold<int>(
          0,
          (sum, item) => sum + item.$2.children.length,
        );
        final Widget list;
        if (snapshot.hasError) {
          list = ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              AppErrorState(
                title: 'Chưa tải được danh sách trẻ',
                message: 'Kiểm tra kết nối mạng rồi thử lại.',
                onRetry: () => setState(() => _data = _load()),
              ),
            ],
          );
        } else if (campuses == null) {
          list = const Padding(
            padding: EdgeInsets.all(AppSpacing.pagePadding),
            child: AppSkeletonList(rows: 6),
          );
        } else {
          list = _list(context, campuses);
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Danh sách trẻ'),
            actions: [
              if (total != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.space4),
                  child: Center(
                    child: Text(
                      '$total bé',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Bộ lọc nằm ngoài danh sách: cuộn không làm mất chữ đang gõ
          body: Column(
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
                  children: [
                    if (campuses != null && campuses.length > 1) ...[
                      AppSegmented<String?>(
                        segments: [
                          (null, 'Tất cả cơ sở'),
                          for (final (id, data) in campuses)
                            (id, _short(data.campusName)),
                        ],
                        selected: _campusId,
                        onChanged: (value) => setState(() => _campusId = value),
                      ),
                      const SizedBox(height: AppSpacing.space3),
                    ],
                    AppSearchField(
                      hint: 'Tìm tên bé, lớp…',
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ],
                ),
              ),
              Expanded(child: list),
            ],
          ),
        );
      },
    );
  }

  Widget _list(BuildContext context, List<(String, CampusChildren)> campuses) {
    final textTheme = Theme.of(context).textTheme;
    final shown = campuses
        .where((item) => _campusId == null || item.$1 == _campusId)
        .toList();
    final rows = <Widget>[
      for (final (campusId, data) in shown)
        for (final item in data.classes)
          if (matchesSearch(item.name, _query))
            _ClassRow(
              key: ValueKey(item.id),
              name: item.name,
              campus: _short(data.campusName),
              count: data.children
                  .where((child) => child.classId == item.id)
                  .length,
              onTap: () => context.push(
                RoutePaths.principalClassChildrenOf(campusId, item.id),
              ),
            ),
      // Có từ khoá ⇒ thêm trẻ khớp tên, kèm lớp và cơ sở
      if (_query.trim().isNotEmpty)
        for (final (_, data) in shown)
          for (final child in data.children)
            if (matchesSearch(child.fullName, _query))
              _ChildRow(
                key: ValueKey(child.id),
                child: child,
                campus: _short(data.campusName),
              ),
    ];
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.space3,
        AppSpacing.pagePadding,
        AppSpacing.pagePadding,
      ),
      itemCount: rows.length + 1,
      itemBuilder: (context, i) {
        if (i < rows.length) return rows[i];
        if (rows.isEmpty) {
          return AppEmptyState(
            title: 'Không có lớp hoặc bé nào khớp',
            message: 'Không tìm thấy “$_query”.',
          );
        }
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.space2),
          child: Text(
            'Chạm một lớp để xem danh sách trẻ. Thêm trẻ, xếp lớp thực hiện trên CareNest Web.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        );
      },
    );
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({
    super.key,
    required this.name,
    required this.campus,
    required this.count,
    required this.onTap,
  });

  final String name;
  final String campus;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: AppCard(
        flush: true,
        child: AppListRow(
          leading: const AppIconTile(icon: AppIcons.classGroup),
          title: name,
          subtitle: Text(campus),
          trailing: Text(
            '$count bé',
            style: textTheme.titleSmall?.copyWith(
              fontFeatures: AppTextStyles.tabularFigures,
            ),
          ),
          showChevron: true,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({super.key, required this.child, required this.campus});

  final CampusChild child;
  final String campus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: AppCard(
        flush: true,
        child: AppListRow(
          leading: AppAvatar(name: child.fullName),
          title: child.fullName,
          subtitle: Text('${child.className} · $campus'),
          showChevron: true,
          onTap: () => openComingSoon(context, child.fullName),
        ),
      ),
    );
  }
}

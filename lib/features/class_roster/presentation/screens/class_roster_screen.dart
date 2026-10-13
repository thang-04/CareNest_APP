import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_coming_soon.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_search_field.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/class_roster/domain/class_roster.dart';

extension RosterTagView on RosterTag {
  AppStatusTone get tone => switch (kind) {
    RosterTagKind.allergy => AppStatusTone.teal,
    RosterTagKind.leave => AppStatusTone.orange,
    RosterTagKind.meal => AppStatusTone.approval,
    RosterTagKind.diet => AppStatusTone.green,
  };
}

/// Tab Lớp học — mockup T09: danh sách trẻ lớp được phân công (AUTH-03), tìm theo tên.
class ClassRosterScreen extends StatefulWidget {
  const ClassRosterScreen({
    super.key,
    this.classId = FakeClassRosterSource.classId,
    this.source = const FakeClassRosterSource(),
  });

  final String classId;
  final ClassRosterSource source;

  @override
  State<ClassRosterScreen> createState() => _ClassRosterScreenState();
}

class _ClassRosterScreenState extends State<ClassRosterScreen> {
  late Future<ClassRoster> _roster = widget.source.loadRoster(widget.classId);
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      child: FutureBuilder<ClassRoster>(
        future: _roster,
        builder: (context, snapshot) {
          final roster = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              Semantics(
                header: true,
                child: Text.rich(
                  TextSpan(
                    text: 'Lớp học',
                    children: [
                      if (roster != null)
                        TextSpan(
                          text:
                              ' · ${roster.className} · ${roster.kids.length} bé',
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                  style: textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              AppSearchField(
                hint: 'Tìm tên bé…',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: AppSpacing.space4),
              if (snapshot.hasError)
                AppErrorState(
                  title: 'Chưa tải được danh sách lớp',
                  message: 'Kiểm tra kết nối mạng rồi thử lại.',
                  onRetry: () => setState(
                    () => _roster = widget.source.loadRoster(widget.classId),
                  ),
                )
              else if (roster == null)
                const AppSkeletonList(rows: 6)
              else
                ..._rows(roster),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _rows(ClassRoster roster) {
    final kids = roster.kids
        .where((kid) => matchesSearch(kid.fullName, _query))
        .toList();
    if (kids.isEmpty) {
      return [
        AppEmptyState(
          title: 'Không có bé nào khớp',
          message: 'Không tìm thấy “$_query” trong lớp ${roster.className}.',
        ),
      ];
    }
    return [
      for (final kid in kids) ...[
        AppCard(
          flush: true,
          child: AppListRow(
            leading: AppAvatar(name: kid.fullName),
            title: kid.fullName,
            // Nhãn dưới tên: ở khổ 360 nhãn + mũi tên bên phải làm tràn dòng
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${kid.ageLabel} · ${kid.guardianLine}'),
                if (kid.tag case final tag?) ...[
                  const SizedBox(height: AppSpacing.space1),
                  AppStatusBadge(label: tag.label, tone: tag.tone),
                ],
              ],
            ),
            showChevron: true,
            onTap: () => openComingSoon(context, kid.fullName),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
      ],
    ];
  }
}

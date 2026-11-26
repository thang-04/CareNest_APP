import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_search_field.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_child_health_source.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/class_roster/domain/child_health.dart';
import 'package:carenest_app/features/teacher/class_roster/domain/class_roster.dart';
import 'package:carenest_app/features/teacher/class_roster/presentation/screens/child_detail_screen.dart';
import 'package:carenest_app/features/teacher/school_year/presentation/selected_school_year.dart';

extension RosterTagView on RosterTag {
  AppStatusTone get tone => switch (kind) {
    RosterTagKind.allergy => AppStatusTone.teal,
    RosterTagKind.leave => AppStatusTone.orange,
    RosterTagKind.meal => AppStatusTone.approval,
    RosterTagKind.diet => AppStatusTone.green,
  };
}

/// Tab Lớp học — mockup T09: danh sách bé lớp được phân công (AUTH-03), tìm theo tên.
/// Chạm một bé xem hồ sơ sức khỏe (chỉ xem, BE trả).
class ClassRosterScreen extends StatefulWidget {
  const ClassRosterScreen({
    super.key,
    this.classId = FakeClassRosterSource.classId,
    this.source = const FakeClassRosterSource(),
    this.childHealthSource,
  });

  final String classId;
  final ClassRosterSource source;

  /// null ⇒ dữ liệu giả; phiên thật truyền nguồn gọi BE.
  final ChildHealthSource? childHealthSource;

  @override
  State<ClassRosterScreen> createState() => _ClassRosterScreenState();
}

class _ClassRosterScreenState extends State<ClassRosterScreen> {
  late Future<ClassRoster> _roster = widget.source.loadRoster(widget.classId);
  String _query = '';

  void _open(RosterKid kid, ClassRoster roster) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ChildDetailScreen(
          kid: kid,
          className: roster.className,
          source: widget.childHealthSource ?? const FakeChildHealthSource(),
        ),
      ),
    );
  }

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
              const SchoolYearChip(),
              const SizedBox(height: AppSpacing.space3),
              Semantics(
                header: true,
                child: Text.rich(
                  TextSpan(
                    text: 'Lớp học',
                    children: [
                      if (roster != null && roster.className.isNotEmpty)
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
                ..._content(roster),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _content(ClassRoster roster) {
    final kids = roster.kids
        .where((kid) => matchesSearch(kid.fullName, _query))
        .toList();
    if (roster.kids.isEmpty) {
      return const [
        AppEmptyState(
          title: 'Lớp chưa có bé',
          message: 'Bé được xếp vào lớp sẽ hiện ở đây.',
        ),
      ];
    }
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
                Text(
                  [
                    kid.ageLabel,
                    kid.guardianLine,
                  ].where((s) => s.isNotEmpty).join(' · '),
                ),
                if (kid.dateOfBirth != null)
                  Text('Ngày sinh ${DateLabels.date(kid.dateOfBirth!)}'),
                if (kid.tag != null ||
                    kid.status != RosterKidStatus.active) ...[
                  const SizedBox(height: AppSpacing.space1),
                  Wrap(
                    spacing: AppSpacing.space2,
                    runSpacing: AppSpacing.space1,
                    children: [
                      if (kid.status != RosterKidStatus.active)
                        AppStatusBadge(
                          label: rosterStatusLabel(kid.status),
                          tone: AppStatusTone.gray,
                        ),
                      if (kid.tag case final tag?)
                        AppStatusBadge(label: tag.label, tone: tag.tone),
                    ],
                  ),
                ],
              ],
            ),
            showChevron: true,
            onTap: () => _open(kid, roster),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
      ],
    ];
  }
}

import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_coming_soon.dart';
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
  };
}

/// Tab Lớp học — Figma GV09: danh sách trẻ lớp được phân công (AUTH-03), tìm theo tên.
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
    return FutureBuilder<ClassRoster>(
      future: _roster,
      builder: (context, snapshot) {
        final roster = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Figma GV09: thanh tiêu đề trắng của tab (không nút quay lại), kẻ dưới mảnh
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding,
                    vertical: AppSpacing.space3,
                  ),
                  child: Semantics(
                    header: true,
                    child: Text.rich(
                      TextSpan(
                        text: 'Lớp học',
                        children: [
                          if (roster != null)
                            TextSpan(
                              text:
                                  ' · ${roster.className} · ${roster.kids.length} bé',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      style: textTheme.headlineSmall,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                children: [
                  AppSearchField(
                    hint: 'Tìm tên bé…',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  if (snapshot.hasError)
                    AppErrorState(
                      title: 'Chưa tải được danh sách lớp',
                      message: 'Kiểm tra kết nối mạng rồi thử lại.',
                      onRetry: () => setState(
                        () =>
                            _roster = widget.source.loadRoster(widget.classId),
                      ),
                    )
                  else if (roster == null)
                    const AppSkeletonList(rows: 6)
                  else
                    ..._rows(roster),
                ],
              ),
            ),
          ],
        );
      },
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
          child: _KidRow(
            kid: kid,
            onTap: () => openComingSoon(context, kid.fullName),
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
      ],
    ];
  }
}

/// Một bé: avatar · tên + nhãn nổi bật cùng dòng · tuổi, phụ huynh · mũi tên (Figma GV09).
class _KidRow extends StatelessWidget {
  const _KidRow({required this.kid, required this.onTap});

  final RosterKid kid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tag = kid.tag;
    final badge = tag == null
        ? null
        : AppStatusBadge(label: tag.label, tone: tag.tone);
    final name = Text(
      kid.fullName,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: textTheme.titleSmall,
    );
    // Chữ phóng lớn ⇒ nhãn xuống dưới dòng phụ huynh thay vì ép tên
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSizes.listRowMinHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space4,
              AppSpacing.space3,
              AppSpacing.space2,
              AppSpacing.space3,
            ),
            child: Row(
              children: [
                AppAvatar(name: kid.fullName),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (badge == null || stacked)
                        name
                      else
                        Row(
                          children: [
                            Expanded(child: name),
                            const SizedBox(width: AppSpacing.space2),
                            badge,
                          ],
                        ),
                      Text(
                        '${kid.ageLabel} · ${kid.guardianLine}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (badge != null && stacked) ...[
                        const SizedBox(height: AppSpacing.space1),
                        badge,
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.space1),
                const Icon(
                  AppIcons.chevronRight,
                  size: AppSizes.iconNavigation,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

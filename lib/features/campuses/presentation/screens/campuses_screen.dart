import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/campuses/data/fake_campus_source.dart';
import 'package:carenest_app/features/campuses/domain/campus.dart';

/// Hiệu trưởng · Cơ sở & Phó HT phụ trách (chỉ xem) — mockup H08 (AUTH-02).
class CampusesScreen extends StatefulWidget {
  const CampusesScreen({super.key, this.source});

  final CampusSource? source;

  @override
  State<CampusesScreen> createState() => _CampusesScreenState();
}

class _CampusesScreenState extends State<CampusesScreen> {
  late final CampusSource _source = widget.source ?? FakeCampusSource();
  late Future<List<Campus>> _campuses = _source.loadCampuses();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cơ sở của trường'),
            Text(
              'Năm học ${_source.schoolYear} · chỉ xem',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Campus>>(
        future: _campuses,
        builder: (context, snapshot) {
          final campuses = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              if (snapshot.hasError)
                AppErrorState(
                  title: 'Chưa tải được danh sách cơ sở',
                  message: 'Kiểm tra kết nối mạng rồi thử lại.',
                  onRetry: () =>
                      setState(() => _campuses = _source.loadCampuses()),
                )
              else if (campuses == null)
                const AppSkeletonList(rows: 2)
              else if (campuses.isEmpty)
                const AppEmptyState(
                  icon: AppIcons.building,
                  title: 'Chưa có cơ sở',
                  message: 'Cơ sở được thêm trên CareNest Web.',
                )
              else
                for (final campus in campuses) ...[
                  _CampusCard(campus: campus),
                  const SizedBox(height: AppSpacing.space3),
                ],
              const SizedBox(height: AppSpacing.space2),
              const AppBanner(
                message:
                    'Thêm cơ sở, đổi Phó HT phụ trách và phân quyền thực hiện trên CareNest Web.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CampusCard extends StatelessWidget {
  const _CampusCard({required this.campus});

  final Campus campus;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(AppIcons.building, color: AppColors.primary),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(campus.name, style: textTheme.titleSmall),
                    Text(
                      '${campus.address} · ${campus.classCount} lớp · ${campus.childCount} bé',
                      style: muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.space6),
          Text('Phó hiệu trưởng phụ trách', style: muted),
          Text(campus.vicePrincipal, style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.space3),
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              for (final scope in campus.scopes)
                AppStatusBadge(label: scope, tone: AppStatusTone.blue),
            ],
          ),
        ],
      ),
    );
  }
}

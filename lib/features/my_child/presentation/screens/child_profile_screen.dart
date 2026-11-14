import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_coming_soon.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/my_child/data/fake_my_child_source.dart';
import 'package:carenest_app/features/my_child/domain/my_child.dart';
import 'package:carenest_app/features/my_child/presentation/widgets/my_child_widgets.dart';

/// Hồ sơ của bé (Figma PH13). Chỉ xem; thông tin do nhà trường quản lý (AUTH-04, HLT-06).
class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({
    super.key,
    required this.childId,
    this.source = const FakeMyChildSource(),
  });

  final String childId;
  final MyChildSource source;

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  late Future<ChildProfile> _profile = widget.source.loadProfile(
    widget.childId,
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ của bé')),
      body: FutureBuilder<ChildProfile>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: AppErrorState(
                title: 'Chưa tải được hồ sơ',
                message: 'Kiểm tra kết nối mạng rồi thử lại.',
                onRetry: () => setState(
                  () => _profile = widget.source.loadProfile(widget.childId),
                ),
              ),
            );
          }
          final profile = snapshot.data;
          if (profile == null) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 4),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              AppCard(
                dense: true,
                child: Row(
                  children: [
                    const AppIconTile(icon: AppIcons.childFace, size: 56),
                    const SizedBox(width: AppSpacing.space4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.fullName, style: textTheme.titleMedium),
                          Text(profile.classLine, style: muted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              AppCard(
                dense: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin chung', style: textTheme.titleSmall),
                    InfoLine(label: 'Ngày sinh', value: profile.birthDate),
                    InfoLine(label: 'Giới tính', value: profile.gender),
                    InfoLine(label: 'Cơ sở', value: profile.campus),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              AppCard(
                dense: true,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Giáo viên chủ nhiệm',
                            style: textTheme.titleSmall,
                          ),
                          Text(profile.teachers, style: muted),
                        ],
                      ),
                    ),
                    // Gọi điện cần plugin mở trình quay số ⇒ chưa thêm thư viện, mở "Sắp có"
                    IconButton.filledTonal(
                      tooltip: 'Gọi giáo viên chủ nhiệm',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primarySoft,
                        foregroundColor: AppColors.primary,
                      ),
                      onPressed: () => openComingSoon(context, 'Gọi giáo viên'),
                      icon: const Icon(AppIcons.call),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              AppCard(
                dense: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      AppIcons.heart,
                      size: AppSizes.iconTile,
                      color: AppStatusColors.of(
                        context,
                      ).feedbackOf(AppFeedback.danger).main,
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sức khỏe đã khai báo',
                            style: textTheme.titleSmall,
                          ),
                          Text(profile.healthLine, style: muted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              AppCard(
                dense: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Người đưa đón đã đăng ký',
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    _GuardianGrid(guardians: profile.guardians),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                'Thông tin do nhà trường quản lý. Cần điều chỉnh, vui lòng liên hệ giáo viên chủ nhiệm.',
                style: muted,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Người đưa đón hai cột như Figma PH13; chữ lớn ⇒ một cột để tên không bị cắt.
class _GuardianGrid extends StatelessWidget {
  const _GuardianGrid({required this.guardians});

  final List<Guardian> guardians;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      for (final (i, guardian) in guardians.indexed)
        _GuardianTile(guardian: guardian, alternate: i.isOdd),
    ];
    if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.space3),
            tiles[i],
          ],
        ],
      );
    }
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: AppSpacing.space3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: tiles[i]),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: i + 1 < tiles.length
                    ? tiles[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _GuardianTile extends StatelessWidget {
  const _GuardianTile({required this.guardian, required this.alternate});

  final Guardian guardian;

  /// Người thứ hai trở đi đổi tông ô icon để dễ phân biệt (Figma).
  final bool alternate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        AppIconTile(
          icon: AppIcons.person,
          tone: alternate ? AppStatusTone.green : null,
          size: 36,
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${guardian.relation} – ${guardian.name}',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                guardian.phone,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

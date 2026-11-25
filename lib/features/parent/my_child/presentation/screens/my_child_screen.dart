import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_coming_soon.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/parent/my_child/data/fake_my_child_source.dart';
import 'package:carenest_app/features/parent/my_child/domain/my_child.dart';
import 'package:carenest_app/features/parent/parent_home/presentation/selected_child.dart';

/// Tab "Bé của tôi" (user 18/11, canvas "Bé của tôi gộp Hồ sơ"): hồ sơ của bé đang chọn
/// ở Trang chủ. Chỉ xem; thông tin do nhà trường quản lý (AUTH-04, CHD-05).
class MyChildScreen extends StatelessWidget {
  const MyChildScreen({super.key, this.source = const FakeMyChildSource()});

  final MyChildSource source;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Không có thanh chọn bé: đổi bé ở Trang chủ, tab này theo bé đang chọn
    return ValueListenableBuilder<String>(
      valueListenable: SelectedChild.notifier,
      builder: (context, childId, _) => SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            Semantics(
              header: true,
              child: Text('Bé của tôi', style: textTheme.headlineSmall),
            ),
            const SizedBox(height: AppSpacing.space4),
            _ProfileLoader(
              key: ValueKey(childId),
              load: () => source.loadProfile(childId),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tải hồ sơ theo bé; khóa theo bé nên kết quả của bé cũ không đè lên bé mới.
class _ProfileLoader extends StatefulWidget {
  const _ProfileLoader({super.key, required this.load});

  final Future<ChildProfile> Function() load;

  @override
  State<_ProfileLoader> createState() => _ProfileLoaderState();
}

class _ProfileLoaderState extends State<_ProfileLoader> {
  late Future<ChildProfile> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChildProfile>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AppErrorState(
            title: 'Chưa tải được thông tin của bé',
            message: 'Kiểm tra kết nối mạng rồi thử lại.',
            // Thân khối: closure trả Future vào setState thì Flutter báo lỗi
            onRetry: () => setState(() {
              _future = widget.load();
            }),
          );
        }
        final profile = snapshot.data;
        if (profile == null) return const AppSkeletonList(rows: 4);
        return _ProfileContent(profile: profile);
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});

  final ChildProfile profile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);
    final health = profile.health;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileCard(profile: profile),
        const SizedBox(height: AppSpacing.sectionGap),
        const _SectionHeader('Thông tin chung'),
        const SizedBox(height: AppSpacing.space2),
        _InfoCard(
          rows: [
            _InfoRow(label: 'Ngày sinh', value: profile.birthDate),
            _InfoRow(label: 'Giới tính', value: profile.gender),
            if (profile.campus case final campus?)
              _InfoRow(label: 'Cơ sở', value: campus),
          ],
        ),
        if (profile.teachers case final teachers?) ...[
          const SizedBox(height: AppSpacing.sectionGap),
          const _SectionHeader('Giáo viên chủ nhiệm'),
          const SizedBox(height: AppSpacing.space2),
          AppCard(
            dense: true,
            child: Row(
              children: [
                Expanded(child: Text(teachers, style: textTheme.titleSmall)),
                const SizedBox(width: AppSpacing.space3),
                // Gọi điện cần plugin mở trình quay số ⇒ chưa thêm thư viện, mở "Sắp có"
                IconButton.filledTonal(
                  tooltip: 'Gọi giáo viên chủ nhiệm',
                  onPressed: () => openComingSoon(context, 'Gọi giáo viên'),
                  icon: const Icon(AppIcons.call),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sectionGap),
        const _SectionHeader('Sức khỏe đã khai báo'),
        const SizedBox(height: AppSpacing.space2),
        _InfoCard(
          rows: [
            _InfoRow(
              label: 'Dị ứng',
              value: _stateLabel(health.allergyState),
              valueWidget:
                  health.allergyState == DeclarationState.reported &&
                      health.allergies.isNotEmpty
                  ? _AllergyBadges(names: health.allergies)
                  : null,
            ),
            _InfoRow(label: 'Chế độ ăn', value: _dietLabel(health.diet)),
            _InfoRow(
              label: 'Tiền sử bản thân',
              value: _historyLabel(health.selfHistory),
            ),
            _InfoRow(
              label: 'Tiền sử gia đình',
              value: _historyLabel(health.familyHistory),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        const _SectionHeader('Người đưa đón đã đăng ký'),
        const SizedBox(height: AppSpacing.space2),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (profile.guardians.isEmpty)
                Text('Nhà trường chưa ghi người đưa đón.', style: muted),
              for (final (i, guardian) in profile.guardians.indexed) ...[
                if (i > 0) const Divider(height: AppSpacing.space6),
                MergeSemantics(
                  child: Row(
                    children: [
                      AppIconTile(
                        icon: AppIcons.person,
                        tone: i.isEven ? null : AppStatusTone.green,
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${guardian.relation} – ${guardian.name}',
                              style: textTheme.titleSmall,
                            ),
                            if (guardian.phone case final phone?)
                              Text(phone, style: muted),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          'Thông tin do nhà trường quản lý. Cần điều chỉnh, vui lòng liên hệ '
          'giáo viên chủ nhiệm.',
          style: muted,
        ),
      ],
    );
  }

  /// Nhãn trạng thái khai báo khi không có chữ đi kèm (CHD-06).
  static String _stateLabel(DeclarationState state) => switch (state) {
    DeclarationState.reported => 'Có',
    DeclarationState.noneReported => 'Không',
    DeclarationState.notProvided => 'Chưa cung cấp',
  };

  /// Không có chế độ ăn riêng ⇒ ăn như các bạn.
  static String _dietLabel(DeclaredItem diet) =>
      diet.state == DeclarationState.noneReported
      ? 'Bình thường'
      : diet.text ?? _stateLabel(diet.state);

  /// Tiền sử ghi như web: "Có — tên bệnh" / "Không" / "Chưa cung cấp".
  static String _historyLabel(DeclaredItem item) {
    final text = item.text;
    return text == null ? _stateLabel(item.state) : 'Có — $text';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// Thẻ đầu: dải bìa, ảnh chữ cái lớn đè nửa dưới dải, tên, lớp · tuổi, năm học.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  static const _avatarSize = AppSizes.avatar * 2;

  final ChildProfile profile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      flush: true,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(AppColors.surface, AppColors.brand, 0.32)!,
                      Color.lerp(AppColors.surface, AppColors.brand, 0.12)!,
                    ],
                  ),
                ),
                child: const SizedBox(height: _avatarSize),
              ),
              // Chừa nửa dưới ảnh chữ cái nằm đè lên dải bìa
              const SizedBox(height: AppSizes.avatar),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.cardPadding,
                  AppSpacing.cardGap,
                  AppSpacing.cardPadding,
                  AppSpacing.cardPadding,
                ),
                child: Column(
                  children: [
                    Text(
                      profile.fullName,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall,
                    ),
                    Text(
                      [profile.className, ?profile.ageLabel].join(' · '),
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (profile.schoolYear case final year?)
                      Text(
                        'Năm học $year',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: AppSizes.avatar,
            left: 0,
            right: 0,
            child: Center(
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.surface,
                    width: AppSpacing.space1,
                  ),
                ),
                child: AppAvatar(name: profile.fullName, size: _avatarSize),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ nhiều dòng "nhãn — giá trị", ngăn bằng đường kẻ mảnh.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const Divider(height: AppSpacing.space6),
            row,
          ],
        ],
      ),
    );
  }
}

/// Nhãn bên trái, giá trị canh phải; chữ lớn thì cả hai xuống dòng, không tràn.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueWidget});

  final String label;
  final String value;

  /// Thay chữ [value] khi cần hiển thị khác (chip dị ứng).
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            flex: 3,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child:
                  valueWidget ??
                  Text(
                    value,
                    textAlign: TextAlign.end,
                    style: textTheme.titleSmall,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mỗi chất gây dị ứng một chip tông đỏ có icon (DESIGN.md: chip phân loại dị ứng `red`).
class _AllergyBadges extends StatelessWidget {
  const _AllergyBadges({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.space1,
      runSpacing: AppSpacing.space1,
      children: [
        for (final name in names)
          AppStatusBadge(
            label: name,
            tone: AppStatusTone.red,
            icon: AppIcons.alertTriangle,
          ),
      ],
    );
  }
}

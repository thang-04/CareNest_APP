import 'package:flutter/material.dart';

import 'package:carenest_app/core/config/app_info.dart';
import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_coming_soon.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/account/data/fake_account_source.dart';
import 'package:carenest_app/features/account/domain/account_profile.dart';

/// Tài khoản — mockup P14, dùng chung 5 vai trò (DESIGN.md §8.5 Tài khoản).
class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.role,
    required this.onOpenProfile,
    required this.onChangePassword,
    required this.onLogout,
    this.onOpenCampuses,
    this.source = const FakeAccountSource(),
  });

  final AppRole role;
  final VoidCallback onOpenProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  /// Hiệu trưởng: mở "Cơ sở của trường" (mockup H08); vai trò khác để null.
  final VoidCallback? onOpenCampuses;
  final AccountSource source;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late Future<AccountProfile> _profile = widget.source.loadProfile(widget.role);

  @override
  void didUpdateWidget(AccountScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Đổi vai trò/nguồn ⇒ tải lại, không giữ hồ sơ của người trước
    if (oldWidget.role != widget.role || oldWidget.source != widget.source) {
      _profile = widget.source.loadProfile(widget.role);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      child: FutureBuilder<AccountProfile>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: AppErrorState(
                title: 'Chưa tải được tài khoản',
                message: 'Kiểm tra kết nối rồi thử lại.',
                onRetry: () => setState(
                  () => _profile = widget.source.loadProfile(widget.role),
                ),
              ),
            );
          }
          final profile = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              Semantics(
                header: true,
                child: Text('Tài khoản', style: textTheme.headlineSmall),
              ),
              const SizedBox(height: AppSpacing.space4),
              if (profile == null)
                const AppSkeletonCard()
              else ...[
                AppCard(
                  dense: true,
                  child: Row(
                    children: [
                      AppAvatar(name: profile.fullName),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.fullName,
                              style: textTheme.titleMedium,
                            ),
                            Text(
                              '${profile.phone} · ${profile.role.label}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (profile.contextValue != null) ...[
                  const SizedBox(height: AppSpacing.space3),
                  _ContextStrip(profile: profile),
                ],
              ],
              const SizedBox(height: AppSpacing.space3),
              AppCard(
                flush: true,
                child: AppDividedColumn(
                  children: [
                    AppListRow(
                      title: 'Thông tin cá nhân',
                      leading: const Icon(AppIcons.person),
                      showChevron: true,
                      onTap: widget.onOpenProfile,
                    ),
                    if (widget.onOpenCampuses != null)
                      AppListRow(
                        title: 'Cơ sở của trường',
                        leading: const Icon(AppIcons.building),
                        showChevron: true,
                        onTap: widget.onOpenCampuses,
                      ),
                    AppListRow(
                      title: 'Đổi mật khẩu',
                      leading: const Icon(AppIcons.lock),
                      showChevron: true,
                      onTap: widget.onChangePassword,
                    ),
                    AppListRow(
                      title: 'Cài đặt thông báo',
                      leading: const Icon(AppIcons.bell),
                      showChevron: true,
                      onTap: () => openComingSoon(context, 'Cài đặt thông báo'),
                    ),
                    AppListRow(
                      title: 'Hỗ trợ & giới thiệu',
                      leading: const Icon(AppIcons.info),
                      showChevron: true,
                      onTap: () =>
                          openComingSoon(context, 'Hỗ trợ & giới thiệu'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space5),
              AppButton(
                label: 'Đăng xuất',
                variant: AppButtonVariant.danger,
                expand: true,
                onPressed: widget.onLogout,
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                'CareNest ${AppInfo.version} · ${AppInfo.schoolShortName}',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ContextStrip extends StatelessWidget {
  const _ContextStrip({required this.profile});

  final AccountProfile profile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text.rich(
        TextSpan(
          text: '${profile.contextLabel}: ',
          children: [
            TextSpan(
              text: profile.contextValue,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        style: textTheme.bodyMedium?.copyWith(color: AppColors.onBrand),
      ),
    );
  }
}

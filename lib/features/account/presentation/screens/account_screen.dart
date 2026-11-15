import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/config/app_info.dart';
import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_coming_soon.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/account/data/fake_account_source.dart';
import 'package:carenest_app/features/account/domain/account_profile.dart';
import 'package:carenest_app/features/account/domain/app_modes.dart';
import 'package:carenest_app/features/account/presentation/app_mode.dart';
import 'package:carenest_app/features/account/presentation/widgets/logout_confirm_dialog.dart';

/// Tài khoản (Figma PH14), dùng chung 5 vai trò (DESIGN.md §8.5 Tài khoản). Tài khoản GV kiêm phụ huynh
/// chuyển chế độ ở đây (AUTH-21, user chốt 2026-11-14).
class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.role,
    required this.onOpenProfile,
    required this.onChangePassword,
    required this.onLogout,
    this.onOpenCampuses,
    this.onSwitchMode,
    this.source = const FakeAccountSource(),
  });

  final AppRole role;
  final VoidCallback onOpenProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  /// Hiệu trưởng: mở "Cơ sở của trường" (mockup H08); vai trò khác để null.
  final VoidCallback? onOpenCampuses;

  /// Mở chế độ khác; null ⇒ chuyển tới màn đầu của chế độ đó.
  final ValueChanged<AppRole>? onSwitchMode;
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

  Future<void> _logout() async {
    final confirmed = await confirmLogout(context, widget.role);
    if (!confirmed || !mounted) return;
    AppMode.endSession();
    widget.onLogout();
  }

  void _switchMode(AppRole mode) {
    AppMode.switchTo(mode);
    final onSwitchMode = widget.onSwitchMode;
    if (onSwitchMode != null) {
      onSwitchMode(mode);
    } else {
      context.go(homePathOf(mode));
    }
  }

  List<_MenuItem> _menu(BuildContext context) {
    final other = AppMode.otherThan(widget.role);
    return [
      _MenuItem(AppIcons.person, 'Thông tin cá nhân', widget.onOpenProfile),
      if (other != null)
        _MenuItem(
          other == AppRole.parent ? AppIcons.child : AppIcons.school,
          'Chuyển sang chế độ ${other.label.toLowerCase()}',
          () => _switchMode(other),
        ),
      if (widget.onOpenCampuses case final openCampuses?)
        _MenuItem(AppIcons.building, 'Cơ sở của trường', openCampuses),
      _MenuItem(AppIcons.lock, 'Đổi mật khẩu', widget.onChangePassword),
      _MenuItem(
        AppIcons.bell,
        'Cài đặt thông báo',
        () => openComingSoon(context, 'Cài đặt thông báo'),
      ),
      _MenuItem(
        AppIcons.info,
        'Hỗ trợ & giới thiệu',
        () => openComingSoon(context, 'Hỗ trợ & giới thiệu'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Tài khoản'),
        titleTextStyle: textTheme.headlineSmall,
      ),
      body: FutureBuilder<AccountProfile>(
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
              if (profile == null)
                const AppSkeletonCard()
              else ...[
                AppCard(
                  dense: true,
                  child: Row(
                    children: [
                      const AppIconTile(icon: AppIcons.person, size: 48),
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
              for (final item in _menu(context)) ...[
                _MenuCard(item: item),
                const SizedBox(height: AppSpacing.space2),
              ],
              const SizedBox(height: AppSpacing.space3),
              _LogoutButton(onPressed: _logout),
              const SizedBox(height: AppSpacing.space3),
              Text(
                'CareNest ${AppInfo.version} · ${AppInfo.schoolShortName}',
                textAlign: TextAlign.center,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
}

/// Mỗi lối vào là một card riêng: icon chữ phụ + tên, cả card bấm được (Figma PH14).
class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item});

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      flush: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.minimumTapTarget + AppSpacing.space1,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space3,
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: AppSizes.iconInline,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Đăng xuất: nền trắng, viền và chữ đỏ (Figma PH14); hỏi lại ở hộp thoại trước khi thoát.
class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final danger = AppStatusColors.of(context).feedbackOf(AppFeedback.danger);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: danger.foreground,
        backgroundColor: AppColors.surface,
        side: BorderSide(color: danger.foreground),
        minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
      ),
      child: const Text('Đăng xuất'),
    );
  }
}

/// Dòng ngữ cảnh dưới thẻ tài khoản (con, lớp, cơ sở): nền `primarySoft`, viền cùng tông.
class _ContextStrip extends StatelessWidget {
  const _ContextStrip({required this.profile});

  final AccountProfile profile;

  static IconData _iconOf(AppRole role) => switch (role) {
    AppRole.parent => AppIcons.childFace,
    AppRole.teacher => AppIcons.classGroup,
    AppRole.kitchen => AppIcons.kitchen,
    AppRole.vicePrincipal || AppRole.principal => AppIcons.building,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Đậm phần đầu (tên bé / lớp), phần sau " · " giữ chữ thường như Figma
    final value = profile.contextValue!;
    final split = value.indexOf(' · ');
    final strong = split < 0 ? value : value.substring(0, split);
    final rest = split < 0 ? '' : value.substring(split);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Row(
        children: [
          Icon(
            _iconOf(profile.role),
            size: AppSizes.iconInline,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '${profile.contextLabel}: ',
                children: [
                  TextSpan(
                    text: strong,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: rest),
                ],
              ),
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_bottom_sheet.dart';
import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/widgets/app_hero_header.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/parent_home/domain/parent_today.dart';
import 'package:carenest_app/features/parent_home/presentation/selected_child.dart';
import 'package:carenest_app/features/parent_home/presentation/widgets/parent_home_cards.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Phụ huynh · Trang chủ — bố cục H (thẻ ví xếp chồng các bé): lời chào → thẻ bé đang chọn + bé khác ló ra → Việc nhanh.
class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key, this.source});

  final ParentHomeSource? source;

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  late final ParentHomeSource _source = widget.source ?? FakeParentHomeSource();
  List<ChildSummary> _children = const [];
  ParentToday? _today;
  Object? _error;
  bool _loading = true;
  int _requestId = 0;

  String get _childId => SelectedChild.notifier.value;

  @override
  void initState() {
    super.initState();
    SelectedChild.notifier.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    SelectedChild.notifier.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    // Đổi con giữa chừng ⇒ bỏ kết quả của lần tải cũ
    final requestId = ++_requestId;
    setState(() {
      _loading = _today?.child.id != _childId;
      _error = null;
    });
    try {
      if (_children.isEmpty) _children = await _source.loadChildren();
      final today = await _source.loadToday(_childId);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _today = today;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _pickChild() {
    showAppBottomSheet<void>(
      context: context,
      title: 'Chọn bé',
      builder: (sheetContext) => Column(
        children: [
          for (final child in _children)
            AppSheetOption(
              selected: child.id == _childId,
              leading: AppAvatar(name: child.fullName),
              onTap: () {
                Navigator.of(sheetContext).pop();
                SelectedChild.notifier.value = child.id;
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.fullName,
                    style: Theme.of(sheetContext).textTheme.titleSmall,
                  ),
                  Text(
                    '${child.className} · ${child.campusName}',
                    style: Theme.of(sheetContext).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _push(String path) => context.push(RoutePaths.withChild(path, _childId));

  // Thẻ bé khác ló ra dưới thẻ đang chọn một đoạn này
  static const double _peekOverlap = AppSpacing.space6;

  bool get _hasPeek =>
      !_loading && _error == null && _today != null && _children.length > 1;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          topInset + AppSpacing.space4,
          AppSpacing.pagePadding,
          AppSpacing.space6,
        ),
        children: [
          Row(
            children: [
              Expanded(
                // container: tách lời chào khỏi nút chuông, không gộp thành một câu đọc
                child: Semantics(
                  container: true,
                  header: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào,',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        _today?.greetingName ?? '',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Semantics(
                container: true,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.buttonSecondary,
                  ),
                  child: IconTheme.merge(
                    data: const IconThemeData(color: AppColors.textPrimary),
                    child: AppHeroBell(
                      unread: _today?.unreadNotifications ?? 0,
                      onPressed: () =>
                          context.go(RoutePaths.parentNotifications),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space5),
          _buildWallet(),
          // Phần ló được kéo lên ⇒ trừ đúng đoạn đó để khoảng cách tới mục sau vẫn bằng sectionGap
          SizedBox(
            height: _hasPeek
                ? AppSpacing.sectionGap - _peekOverlap
                : AppSpacing.sectionGap,
          ),
          Semantics(
            header: true,
            child: Text('Việc nhanh', style: textTheme.titleMedium),
          ),
          const SizedBox(height: AppSpacing.space3),
          UtilityGrid(
            items: [
              UtilityItem(
                AppIcons.calendarOff,
                'Xin nghỉ cho bé',
                () => _push(RoutePaths.parentLeaveNew),
                tone: AppStatusTone.orange,
              ),
              UtilityItem(
                AppIcons.image,
                'Hoạt động & đánh giá',
                () => _push(RoutePaths.parentActivities),
                tone: AppStatusTone.blue,
              ),
              UtilityItem(
                AppIcons.menuBook,
                'Thực đơn tuần',
                () => _push(RoutePaths.parentMenu),
                tone: AppStatusTone.green,
              ),
              UtilityItem(
                AppIcons.heart,
                'Sức khỏe',
                () => context.go(
                  Uri(
                    path: RoutePaths.parentChild,
                    queryParameters: {'tab': 'health'},
                  ).toString(),
                ),
                tone: AppStatusTone.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWallet() {
    if (_loading) return const AppSkeletonCard(lines: 4);
    final today = _today;
    if (_error != null || today == null) {
      return AppErrorState(
        title: 'Chưa tải được thông tin hôm nay',
        message: 'Kiểm tra kết nối mạng rồi thử lại.',
        onRetry: _load,
      );
    }
    final others = _children.where((item) => item.id != _childId).toList();
    final card = ChildWalletCard(
      today: today,
      onOpenAttendance: () => _push(RoutePaths.parentAttendance),
      onOpenMenu: () => _push(RoutePaths.parentMenu),
      onOpenActivities: () => _push(RoutePaths.parentActivities),
      onOpenProfile: () => _push(RoutePaths.parentChildProfile),
    );
    if (others.isEmpty) return card;
    // Bé khác nằm dưới thẻ đang chọn: vẽ trước, kéo lên, thẻ đang chọn đè lên mép trên
    return Column(
      verticalDirection: VerticalDirection.up,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Transform.translate(
          offset: const Offset(0, -_peekOverlap),
          child: OtherChildrenPeek(
            others: others,
            onSelect: (child) => SelectedChild.notifier.value = child.id,
            onOpenPicker: _pickChild,
          ),
        ),
        card,
      ],
    );
  }
}

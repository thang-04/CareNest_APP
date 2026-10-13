import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_bottom_sheet.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_hero_header.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/parent_home/domain/parent_today.dart';
import 'package:carenest_app/features/parent_home/presentation/selected_child.dart';
import 'package:carenest_app/features/parent_home/presentation/widgets/parent_home_cards.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Phụ huynh · Trang chủ — mockup P02: hero + thẻ bé → Hôm nay → Tiện ích.
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

  @override
  Widget build(BuildContext context) {
    final today = _today;
    final child = _children.where((item) => item.id == _childId).firstOrNull;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          AppHeroHeader(
            greeting: 'Xin chào,',
            name: today?.greetingName ?? '',
            trailing: AppHeroBell(
              unread: today?.unreadNotifications ?? 0,
              onPressed: () => context.go(RoutePaths.parentNotifications),
            ),
            card: child == null
                ? const AppSkeletonCard(lines: 1)
                : ChildHeroCard(
                    child: child,
                    onOpenProfile: () => _push(RoutePaths.parentChildProfile),
                    onSwitchChild: _children.length > 1 ? _pickChild : null,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.space5,
              AppSpacing.pagePadding,
              AppSpacing.space6,
            ),
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Column(
        children: [
          AppSkeletonCard(lines: 3),
          SizedBox(height: AppSpacing.cardGap),
          AppSkeletonCard(lines: 2),
        ],
      );
    }
    final today = _today;
    if (_error != null || today == null) {
      return AppErrorState(
        title: 'Chưa tải được thông tin hôm nay',
        message: 'Kiểm tra kết nối mạng rồi thử lại.',
        onRetry: _load,
      );
    }
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Hôm nay · ${DateLabels.weekdayDayMonth(today.date)}',
              style: textTheme.titleSmall,
            ),
            AppLinkButton(
              label: 'Xem lịch ›',
              onPressed: () => _push(RoutePaths.parentAttendance),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        TodaySummaryCard(
          today: today,
          onOpenAttendance: () => _push(RoutePaths.parentAttendance),
          onOpenMenu: () => _push(RoutePaths.parentMenu),
          onOpenActivities: () => _push(RoutePaths.parentActivities),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        Semantics(
          header: true,
          child: Text('Tiện ích', style: textTheme.titleSmall),
        ),
        const SizedBox(height: AppSpacing.space3),
        UtilityGrid(
          items: [
            UtilityItem(
              AppIcons.calendarOff,
              'Xin nghỉ cho bé',
              () => _push(RoutePaths.parentLeaveNew),
            ),
            UtilityItem(
              AppIcons.image,
              'Hoạt động & đánh giá',
              () => _push(RoutePaths.parentActivities),
            ),
            UtilityItem(
              AppIcons.menuBook,
              'Thực đơn tuần',
              () => _push(RoutePaths.parentMenu),
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
            ),
          ],
        ),
      ],
    );
  }
}

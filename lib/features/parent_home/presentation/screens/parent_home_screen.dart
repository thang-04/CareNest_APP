import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Phụ huynh · Trang chủ (Figma PH02): dải chào + thẻ bé đè mép → Hôm nay → Tiện ích.
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
    final ready = !_loading && _error == null && today != null;
    // Dải đầu màn nền xanh ⇒ icon thanh trạng thái màu sáng
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.space6),
          children: [
            AppHeroHeader(
              greeting: 'Xin chào,',
              name: today?.greetingName ?? '',
              trailing: AppHeroBell(
                unread: today?.unreadNotifications ?? 0,
                onPressed: () => context.go(RoutePaths.parentNotifications),
              ),
              card: _loading
                  ? const AppSkeletonCard(lines: 1)
                  : ready
                  ? ChildHeroCard(
                      child: today.child,
                      onOpenProfile: () => _push(RoutePaths.parentChildProfile),
                      onSwitchChild: _children.length > 1 ? _pickChild : null,
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.space3,
                AppSpacing.pagePadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    AppErrorState(
                      title: 'Chưa tải được thông tin hôm nay',
                      message: 'Kiểm tra kết nối mạng rồi thử lại.',
                      onRetry: _load,
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                  ] else if (ready) ...[
                    _SectionTitle(
                      title:
                          'Hôm nay · ${DateLabels.weekdayDayMonth(today.date)}',
                      action: AppLinkButton(
                        label: 'Xem lịch ›',
                        onPressed: () => _push(RoutePaths.parentAttendance),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    TodayCard(
                      today: today,
                      onOpenAttendance: () =>
                          _push(RoutePaths.parentAttendance),
                      onOpenMenu: () => _push(RoutePaths.parentMenu),
                      onOpenActivities: () =>
                          _push(RoutePaths.parentActivities),
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                  ],
                  const _SectionTitle(title: 'Tiện ích'),
                  const SizedBox(height: AppSpacing.space3),
                  UtilityGrid(
                    iconOnTop: true,
                    items: [
                      UtilityItem(
                        AppIcons.calendarOff,
                        'Xin nghỉ cho bé',
                        () => _push(RoutePaths.parentLeaveNew),
                      ),
                      UtilityItem(
                        AppIcons.gallery,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiêu đề mục + link tuỳ chọn bên phải.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
        ),
        ?action,
      ],
    );
  }
}

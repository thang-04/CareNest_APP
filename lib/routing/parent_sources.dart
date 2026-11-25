import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/parent/leave_notice/data/fake_leave_notice_source.dart';
import 'package:carenest_app/features/parent/my_child/domain/my_child.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/parent/parent_home/domain/parent_today.dart';

/// Nguồn dữ liệu các màn phụ huynh. Mặc định (Xem thử) mọi nguồn null ⇒ màn dùng bản giả;
/// phiên thật truyền bản gọi BE (`Live…Source`) và `live: true`.
class ParentSources {
  const ParentSources({this.live = false, this.home, this.leave, this.myChild});

  /// Phiên thật: màn chưa có API ở BE hiện "Sắp có", không hiện dữ liệu giả (user 25/11, Q1).
  final bool live;
  final ParentHomeSource? home;
  final LeaveNoticeSource? leave;
  final MyChildSource? myChild;

  /// Ngày mở lịch tháng (Điểm danh, Thực đơn): phiên thật = hôm nay; Xem thử = ngày của dữ liệu giả.
  DateTime get today {
    if (!live) return FakeParentHomeSource.today;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}

/// Màn con của phụ huynh mang ID con trên query: chờ danh sách con của phiên rồi mới dựng màn;
/// ID không thuộc danh sách ⇒ [notFound] (AUTH-04, BE vẫn kiểm 403).
class ParentChildGate extends StatefulWidget {
  const ParentChildGate({
    super.key,
    required this.childId,
    required this.loadChildren,
    required this.builder,
    required this.notFound,
  });

  final String? childId;
  final Future<List<ChildSummary>> Function() loadChildren;
  final Widget Function(ChildSummary child) builder;
  final Widget notFound;

  @override
  State<ParentChildGate> createState() => _ParentChildGateState();
}

class _ParentChildGateState extends State<ParentChildGate> {
  late Future<List<ChildSummary>> _children = widget.loadChildren();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ChildSummary>>(
      future: _children,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: AppErrorState(
              title: 'Chưa tải được thông tin của bé',
              message: 'Kiểm tra kết nối mạng rồi thử lại.',
              onRetry: () => setState(() => _children = widget.loadChildren()),
            ),
          );
        }
        final children = snapshot.data;
        if (children == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 3),
            ),
          );
        }
        final child = children
            .where((item) => item.id == widget.childId)
            .firstOrNull;
        return child == null ? widget.notFound : widget.builder(child);
      },
    );
  }
}

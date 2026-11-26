import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/rewards/data/fake_teacher_reward_source.dart';
import 'package:carenest_app/features/teacher/rewards/domain/teacher_rewards.dart';
import 'package:carenest_app/features/teacher/school_year/presentation/selected_school_year.dart';
import 'package:carenest_app/features/teacher/shared/class_option.dart';

enum _Top { tickets, proposals }

enum _Sub { all, weekly, monthly }

/// Khen thưởng — CHỈ XEM trên App (phát phiếu, lập danh sách làm trên Web). Hai mục như bản gốc:
/// "Phiếu bé ngoan" (Tất cả | Tuần | Tháng theo kỳ BE) và "Đề xuất" (danh hiệu từng bé).
class TeacherRewardsScreen extends StatefulWidget {
  const TeacherRewardsScreen({
    super.key,
    this.classId = FakeClassRosterSource.classId,
    this.source,
    this.classes = const [],
  });

  final String classId;
  final TeacherRewardSource? source;

  /// Giữ cho router; mỗi giáo viên một lớp nên không còn chọn lớp.
  final List<ClassOption> classes;

  @override
  State<TeacherRewardsScreen> createState() => _TeacherRewardsScreenState();
}

class _TeacherRewardsScreenState extends State<TeacherRewardsScreen> {
  late final TeacherRewardSource _source =
      widget.source ?? FakeTeacherRewardSource.shared;
  late final String _classId = widget.classId;
  _Top _top = _Top.tickets;
  _Sub _sub = _Sub.all;
  DateTime? _periodStart;

  TeacherRewards? _data;
  TicketBoard? _board;
  Object? _error;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    if (_classId.isNotEmpty) _load();
  }

  /// Tải phần đang xem; kết quả của lần gọi cũ (đổi lớp, kỳ, tab) bị bỏ qua.
  Future<void> _load() async {
    final seq = ++_seq;
    setState(() {
      _error = null;
      _board = null;
      _data = null;
    });
    try {
      if (_top == _Top.proposals || _sub == _Sub.all) {
        final data = await _source.load(_classId);
        if (mounted && seq == _seq) setState(() => _data = data);
      } else {
        final board = await _source.loadBoard(
          _classId,
          _sub == _Sub.weekly ? TicketKind.weekly : TicketKind.monthly,
          periodStart: _periodStart,
        );
        if (mounted && seq == _seq) setState(() => _board = board);
      }
    } catch (error) {
      if (mounted && seq == _seq) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Khen thưởng')),
      body: _classId.isEmpty
          ? const Center(
              child: AppEmptyState(
                title: 'Bạn chưa được phân công lớp',
                message: 'Chỉ giáo viên của lớp mới xem được khen thưởng.',
                icon: AppIcons.classGroup,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                const SchoolYearChip(),
                const SizedBox(height: AppSpacing.space3),
                AppSegmented<_Top>(
                  segments: const [
                    (_Top.tickets, 'Phiếu bé ngoan'),
                    (_Top.proposals, 'Đề xuất'),
                  ],
                  selected: _top,
                  onChanged: (value) {
                    _top = value;
                    _load();
                  },
                ),
                const SizedBox(height: AppSpacing.space3),
                if (_top == _Top.tickets)
                  ..._ticketsView()
                else
                  ..._proposals(),
              ],
            ),
    );
  }

  // ---- Phiếu bé ngoan ----

  List<Widget> _ticketsView() {
    final textTheme = Theme.of(context).textTheme;
    return [
      AppSegmented<_Sub>(
        segments: const [
          (_Sub.all, 'Tất cả'),
          (_Sub.weekly, 'Tuần'),
          (_Sub.monthly, 'Tháng'),
        ],
        selected: _sub,
        onChanged: (value) {
          _sub = value;
          _periodStart = null;
          _load();
        },
      ),
      const SizedBox(height: AppSpacing.space3),
      if (_error != null)
        AppErrorState(
          title: 'Chưa tải được khen thưởng',
          message: 'Kiểm tra kết nối mạng rồi thử lại.',
          onRetry: _load,
        )
      else if (_sub == _Sub.all)
        ..._allTickets()
      else
        ..._boardView(),
      const SizedBox(height: AppSpacing.space3),
      Text(
        'Chỉ xem · giáo viên phát phiếu trên Web.',
        style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
      ),
    ];
  }

  static String _periodText(TicketKind kind, TicketPeriod p) =>
      kind == TicketKind.monthly
      ? DateLabels.month(p.start)
      : p.weekNo != null
      ? 'Tuần ${p.weekNo} (${DateLabels.range(p.start, p.end)})'
      : DateLabels.range(p.start, p.end);

  List<Widget> _boardView() {
    final board = _board;
    if (board == null) return const [AppSkeletonList(rows: 5)];
    final period = board.period;
    final weekly = board.kind == TicketKind.weekly;
    if (period == null) {
      return const [
        AppEmptyState(
          title: 'Chưa tới ngày phát phiếu',
          message: 'Chưa có kỳ nào kết thúc để xem phiếu.',
        ),
      ];
    }
    // `periods` mới nhất trước: "trước" = chỉ số lớn hơn, "sau" = chỉ số nhỏ hơn
    final index = board.periods.indexWhere((p) => p.start == period.start);
    final rows = [...board.rows]
      ..sort((a, b) {
        int rank(TicketBoardRow r) => r.hasTicket
            ? 1
            : r.eligible
            ? 0
            : 2;
        final byRank = rank(a).compareTo(rank(b));
        return byRank != 0 ? byRank : a.fullName.compareTo(b.fullName);
      });
    final issued = rows.where((r) => r.hasTicket).length;
    final pending = rows.where((r) => r.eligible && !r.hasTicket).length;
    final flagNeed = board.rules['WEEK_MIN_FLAGS'];
    final ticketNeed = board.rules['MONTH_MIN_WEEKLY_TICKETS'];
    return [
      Row(
        children: [
          IconButton(
            tooltip: weekly ? 'Tuần trước' : 'Tháng trước',
            icon: const Icon(AppIcons.back),
            onPressed: index >= 0 && index < board.periods.length - 1
                ? () {
                    _periodStart = board.periods[index + 1].start;
                    _load();
                  }
                : null,
          ),
          Expanded(
            child: Text(
              _periodText(board.kind, period),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          IconButton(
            tooltip: weekly ? 'Tuần sau' : 'Tháng sau',
            icon: const Icon(AppIcons.chevronRight),
            onPressed: index > 0
                ? () {
                    _periodStart = board.periods[index - 1].start;
                    _load();
                  }
                : null,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.space2),
      AppStatRow(
        tiles: [
          AppStatTile(
            value: '$pending',
            label: 'Đủ điều kiện, chưa phát',
            tone: AppStatusTone.orange,
          ),
          AppStatTile(
            value: '$issued',
            label: 'Đã phát',
            tone: AppStatusTone.green,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.space3),
      if (rows.isEmpty)
        const AppEmptyState(
          title: 'Lớp chưa có trẻ',
          message: 'Lớp chưa có trẻ trong kỳ này.',
          icon: AppIcons.child,
        ),
      for (final row in rows) ...[
        AppCard(
          flush: true,
          child: AppListRow(
            leading: AppAvatar(name: row.fullName),
            title: row.fullName,
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekly
                      ? 'Ngày có mặt ${row.presentDays}/5 · Cờ bé ngoan ${row.flagCount}'
                            '${flagNeed == null ? '' : ' (cần $flagNeed)'}'
                      : 'Bé ngoan trong tháng ${row.weeklyTickets}'
                            '${ticketNeed == null ? '' : ' (cần $ticketNeed)'}',
                ),
                const SizedBox(height: AppSpacing.space1),
                _ticketBadge(row),
              ],
            ),
          ),
        ),
        if (row.hasTicket || !row.canIssue || row.issuedElsewhere)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.space4,
              top: AppSpacing.space1,
            ),
            child: Text(
              [
                if (row.hasTicket) 'Đã có phiếu trong kỳ',
                if (row.issuedAt case final at?)
                  '${DateLabels.date(at)} ${DateLabels.time24(at)}',
                if (row.issuedElsewhere) 'Đã phát tại lớp khác',
                if (!row.canIssue)
                  'Chỉ xem lịch sử · Trẻ không thuộc lớp cuối kỳ',
              ].join(' · '),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ),
        const SizedBox(height: AppSpacing.space2),
      ],
    ];
  }

  Widget _ticketBadge(TicketBoardRow row) {
    if (row.hasTicket) {
      return const AppStatusBadge(
        label: 'Đã phát',
        tone: AppStatusTone.green,
        icon: AppIcons.ticket,
      );
    }
    if (row.eligible) {
      return const AppStatusBadge(
        label: 'Đủ điều kiện',
        tone: AppStatusTone.orange,
      );
    }
    return const AppStatusBadge(
      label: 'Chưa đủ điều kiện',
      tone: AppStatusTone.gray,
    );
  }

  List<Widget> _allTickets() {
    final data = _data;
    if (data == null) return const [AppSkeletonList(rows: 5)];
    final weekly = data.children.fold(0, (sum, c) => sum + c.weeklyTickets);
    final monthly = data.children.fold(0, (sum, c) => sum + c.monthlyTickets);
    return [
      AppStatRow(
        tiles: [
          AppStatTile(
            value: '$weekly',
            label: 'Phiếu tuần',
            tone: AppStatusTone.blue,
          ),
          AppStatTile(
            value: '$monthly',
            label: 'Phiếu tháng',
            tone: AppStatusTone.green,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.space3),
      for (final child in data.children) ...[
        AppCard(
          flush: true,
          child: AppListRow(
            leading: AppAvatar(name: child.fullName),
            title: child.fullName,
            subtitle: Text(
              '${child.weeklyTickets} tuần · ${child.monthlyTickets} tháng',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
      ],
    ];
  }

  // ---- Đề xuất ----

  List<Widget> _proposals() {
    final textTheme = Theme.of(context).textTheme;
    final data = _data;
    return [
      if (_error != null)
        AppErrorState(
          title: 'Chưa tải được khen thưởng',
          message: 'Kiểm tra kết nối mạng rồi thử lại.',
          onRetry: _load,
        )
      else if (data == null)
        const AppSkeletonList(rows: 5)
      else ...[
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space1,
          children: [
            Text(
              '${data.className} · ${data.schoolYearLabel}',
              style: textTheme.bodyMedium,
            ),
            // Trạng thái danh sách của cả lớp (BE RewardClassDetail.status)
            AppStatusBadge(
              label: data.status?.label ?? 'Chưa lập',
              tone: _statusTone(data.status),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        if (data.children.isEmpty)
          const AppBanner(message: 'Lớp chưa có bé trong danh sách.'),
        for (final child in data.children) ...[
          AppCard(
            flush: true,
            child: AppListRow(
              leading: AppAvatar(name: child.fullName),
              title: child.fullName,
              subtitle: Text(_proposalLine(child)),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
        ],
        const SizedBox(height: AppSpacing.space2),
        Text(
          'Chỉ xem · giáo viên lập danh sách trên Web.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
      ],
    ];
  }

  /// "Có mặt 152/160 · Bé chăm ngoan"; chưa chọn ⇒ danh hiệu gợi ý kèm chữ "gợi ý" (OBS-14).
  static String _proposalLine(TeacherRewardChild child) {
    final attendance = 'Có mặt ${child.presentDays}/${child.schoolDays}';
    if (child.titles.isNotEmpty) {
      return '$attendance · ${child.titles.join(' · ')}';
    }
    if (child.suggested.isNotEmpty) {
      return '$attendance · ${child.suggested.join(' · ')} (gợi ý)';
    }
    return '$attendance · Chưa có danh hiệu';
  }

  static AppStatusTone _statusTone(RewardStatus? status) => switch (status) {
    null => AppStatusTone.gray,
    RewardStatus.draft => AppStatusTone.gray,
    RewardStatus.pendingVp ||
    RewardStatus.pendingPrincipal => AppStatusTone.approval,
    RewardStatus.approved => AppStatusTone.green,
    RewardStatus.returned => AppStatusTone.orange,
  };
}

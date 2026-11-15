import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/reward_proposals/data/fake_principal_reward_source.dart';
import 'package:carenest_app/features/reward_proposals/domain/reward_batch.dart';
import 'package:carenest_app/features/reward_proposals/domain/reward_proposal.dart';

/// Hiệu trưởng · Duyệt khen thưởng cuối năm — mockup H04 (OBS-10 PROPOSED, P-11 PENDING).
/// Mặc định chọn hết; đề xuất bỏ chọn và "Trả về Phó HT" cần ghi chú. BE kiểm tra lại khi gửi.
class RewardBatchScreen extends StatefulWidget {
  const RewardBatchScreen({
    super.key,
    required this.id,
    required this.onDone,
    this.source,
  });

  final String id;
  final VoidCallback onDone;
  final PrincipalRewardSource? source;

  @override
  State<RewardBatchScreen> createState() => _RewardBatchScreenState();
}

class _RewardBatchScreenState extends State<RewardBatchScreen> {
  static const _collapsedCount = 5;

  late final PrincipalRewardSource _source =
      widget.source ?? FakePrincipalRewardSource.shared;
  late Future<RewardBatch?> _batch = _load();
  final _note = TextEditingController();
  final _noteKey = GlobalKey();
  Set<String>? _selected;
  bool _expanded = false;
  String? _noteError;

  /// Nút đang chạy: true = duyệt, false = trả về.
  bool? _busy;

  Future<RewardBatch?> _load() async {
    final batch = await _source.loadBatch(widget.id);
    _selected ??= {...?batch?.proposals.map((item) => item.id)};
    return batch;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _showNoteError(String message) {
    setState(() => _noteError = message);
    // Ô ghi chú nằm cuối màn ⇒ cuộn tới để thấy lỗi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _noteKey.currentContext;
      if (target != null && target.mounted) {
        Scrollable.ensureVisible(target, alignment: 0.5);
      }
    });
  }

  Future<void> _submit(RewardBatch batch, {required bool approve}) async {
    final note = _note.text.trim();
    final selected = _selected ?? const <String>{};
    final unchecked = batch.proposals.length - selected.length;
    if (!approve && note.isEmpty) {
      _showNoteError('Nhập ghi chú để Phó HT biết vì sao trả về');
      return;
    }
    if (approve && unchecked > 0 && note.isEmpty) {
      _showNoteError('Nhập ghi chú cho $unchecked đề xuất bỏ chọn');
      return;
    }
    setState(() {
      _noteError = null;
      _busy = approve;
    });
    try {
      if (approve) {
        await _source.approve(
          batch.id,
          approvedIds: selected,
          note: note.isEmpty ? null : note,
        );
      } else {
        await _source.returnToVicePrincipal(batch.id, note: note);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = null);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Chưa gửi được. Thử lại sau.')),
      );
      return;
    }
    if (!mounted) return;
    // Bỏ trạng thái đang gửi trước khi rời màn: nơi gọi có thể không đóng màn ngay
    setState(() {
      _busy = null;
      _batch = _load();
    });
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          approve
              ? 'Đã duyệt ${selected.length} đề xuất'
              : 'Đã trả về Phó HT kèm ghi chú',
        ),
      ),
    );
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<RewardBatch?>(
      future: _batch,
      builder: (context, snapshot) {
        final batch = snapshot.data;
        final pending = batch?.status == RewardBatchStatus.pending;
        final selected = _selected ?? const <String>{};
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(batch?.title ?? 'Khen thưởng'),
                if (batch != null)
                  Text(
                    '${batch.campusName} · ${batch.proposals.length} đề xuất hợp lệ',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          body: switch (snapshot) {
            AsyncSnapshot(hasError: true) => Center(
              child: AppErrorState(
                title: 'Chưa tải được đề xuất',
                message: 'Kiểm tra kết nối mạng rồi thử lại.',
                onRetry: () => setState(() => _batch = _load()),
              ),
            ),
            AsyncSnapshot(connectionState: ConnectionState.waiting) =>
              const Padding(
                padding: EdgeInsets.all(AppSpacing.pagePadding),
                child: AppSkeletonList(rows: 5),
              ),
            _ when batch == null => const Center(
              child: AppEmptyState(
                icon: AppIcons.searchOff,
                title: 'Không tìm thấy đợt đề xuất',
                message: 'Đợt này không còn hoặc đã được xử lý ở nơi khác.',
              ),
            ),
            _ => _body(context, batch, pending, selected),
          },
          bottomNavigationBar: batch == null || !pending
              ? null
              : AppBottomDock(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Trả về Phó HT',
                            variant: AppButtonVariant.danger,
                            isLoading: _busy == false,
                            loadingLabel: 'Đang gửi',
                            expand: true,
                            onPressed: _busy == null
                                ? () => _submit(batch, approve: false)
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space3),
                        Expanded(
                          child: AppButton(
                            label: 'Duyệt (${selected.length})',
                            isLoading: _busy == true,
                            loadingLabel: 'Đang gửi',
                            expand: true,
                            onPressed: _busy == null && selected.isNotEmpty
                                ? () => _submit(batch, approve: true)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    RewardBatch batch,
    bool pending,
    Set<String> selected,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final shown = _expanded || batch.proposals.length <= _collapsedCount
        ? batch.proposals
        : batch.proposals.take(_collapsedCount).toList();
    final hidden = batch.proposals.length - shown.length;
    final unchecked = batch.proposals.length - selected.length;
    // Nội dung ngắn ⇒ dựng hết một lần để cuộn tới ô ghi chú được
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBanner(
            kind: pending ? AppBannerKind.success : AppBannerKind.neutral,
            message: pending
                ? batch.reviewNote
                : batch.decisionNote ?? 'Đợt này đã được xử lý.',
          ),
          const SizedBox(height: AppSpacing.space3),
          for (final item in shown) ...[
            _ProposalTile(
              item: item,
              checked: selected.contains(item.id),
              onChanged: pending && _busy == null
                  ? (value) => setState(() {
                      final next = {...selected};
                      value ? next.add(item.id) : next.remove(item.id);
                      _selected = next;
                    })
                  : null,
            ),
            const SizedBox(height: AppSpacing.space2),
          ],
          if (hidden > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _expanded = true),
                child: Text('+ $hidden đề xuất khác · Xem tất cả'),
              ),
            ),
          if (pending) ...[
            const SizedBox(height: AppSpacing.space3),
            AppTextField(
              key: _noteKey,
              label: 'Ghi chú (khi trả lại)',
              controller: _note,
              multiline: true,
              errorText: _noteError,
              maxLength: 200,
              helperText: unchecked > 0
                  ? '$unchecked đề xuất bỏ chọn sẽ trả về Phó HT kèm ghi chú này.'
                  : null,
            ),
          ],
          if (batch.proposals.isEmpty)
            Text(
              'Đợt này không còn đề xuất để xem trên app.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}

class _ProposalTile extends StatelessWidget {
  const _ProposalTile({
    required this.item,
    required this.checked,
    required this.onChanged,
  });

  final RewardProposal item;
  final bool checked;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final award = AppStatusColors.of(context).tone(AppStatusTone.orange);
    return AppCard(
      flush: true,
      // ListTile cần Material ngay trên để vẽ hiệu ứng chạm trong card có nền
      child: Material(
        type: MaterialType.transparency,
        child: CheckboxListTile(
          value: checked,
          onChanged: onChanged == null
              ? null
              : (value) => onChanged!(value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          title: Text.rich(
            TextSpan(
              text: item.childName,
              children: [
                TextSpan(
                  text: ' · ${item.className}',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            style: textTheme.titleSmall,
          ),
          subtitle: Text(item.awardTitle),
          secondary: Icon(
            AppIcons.trophy,
            size: AppSizes.iconTile,
            color: award.foreground,
          ),
        ),
      ),
    );
  }
}

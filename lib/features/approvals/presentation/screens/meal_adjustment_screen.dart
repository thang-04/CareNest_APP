import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/approvals/data/fake_meal_adjustment_source.dart';
import 'package:carenest_app/features/approvals/domain/meal_adjustment.dart';

/// Phó HT · Duyệt điều chỉnh suất — mockup V03 (NUT-03; P-04 PENDING). Số sau khi duyệt và
/// tình trạng bếp do BE trả; duyệt xong BE gửi số mới tới bếp.
class MealAdjustmentScreen extends StatefulWidget {
  const MealAdjustmentScreen({
    super.key,
    required this.id,
    required this.onDone,
    this.source,
  });

  final String id;
  final VoidCallback onDone;
  final MealAdjustmentSource? source;

  @override
  State<MealAdjustmentScreen> createState() => _MealAdjustmentScreenState();
}

class _MealAdjustmentScreenState extends State<MealAdjustmentScreen> {
  late final MealAdjustmentSource _source =
      widget.source ?? FakeMealAdjustmentSource.shared;
  late Future<MealAdjustment?> _item = _source.loadOne(widget.id);
  final _reason = TextEditingController();
  final _reasonKey = GlobalKey();
  String? _reasonError;
  bool? _deciding;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _decide({required bool approve}) async {
    final reason = _reason.text.trim();
    // Từ chối phải có lý do để trả về người gửi; BE kiểm tra lại
    if (!approve && reason.isEmpty) {
      setState(
        () => _reasonError = 'Nhập lý do để giáo viên biết vì sao bị từ chối',
      );
      // Ô lý do nằm cuối màn ⇒ cuộn tới để thấy lỗi
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _reasonKey.currentContext;
        if (target != null && target.mounted) {
          Scrollable.ensureVisible(target, alignment: 0.5);
        }
      });
      return;
    }
    setState(() {
      _reasonError = null;
      _deciding = approve;
    });
    try {
      await _source.decide(
        widget.id,
        approve: approve,
        reason: approve ? null : reason,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _deciding = null);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Chưa gửi được. Thử lại sau.')),
      );
      return;
    }
    if (!mounted) return;
    // Bỏ trạng thái đang gửi trước khi rời màn: nơi gọi có thể không đóng màn ngay
    setState(() {
      _deciding = null;
      _item = _source.loadOne(widget.id);
    });
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          approve
              ? 'Đã duyệt, số suất mới gửi tới bếp'
              : 'Đã từ chối, trả về người gửi',
        ),
      ),
    );
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<MealAdjustment?>(
      future: _item,
      builder: (context, snapshot) {
        final item = snapshot.data;
        final pending = item?.decision == RequestDecision.pending;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Điều chỉnh suất ăn'),
                if (item != null)
                  Text(
                    '${item.className} · ${item.cutoffLabel}',
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
                title: 'Chưa tải được yêu cầu',
                message: 'Kiểm tra kết nối mạng rồi thử lại.',
                onRetry: () =>
                    setState(() => _item = _source.loadOne(widget.id)),
              ),
            ),
            AsyncSnapshot(connectionState: ConnectionState.waiting) =>
              const Padding(
                padding: EdgeInsets.all(AppSpacing.pagePadding),
                child: AppSkeletonList(rows: 4),
              ),
            _ when item == null => const Center(
              child: AppEmptyState(
                icon: AppIcons.searchOff,
                title: 'Không tìm thấy yêu cầu',
                message:
                    'Yêu cầu không còn hoặc không thuộc cơ sở bạn phụ trách.',
              ),
            ),
            _ => _Body(
              item: item,
              reason: _reason,
              reasonError: _reasonError,
              reasonKey: _reasonKey,
              pending: pending,
            ),
          },
          bottomNavigationBar: item == null || !pending
              ? null
              : AppBottomDock(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Từ chối',
                            variant: AppButtonVariant.danger,
                            isLoading: _deciding == false,
                            loadingLabel: 'Đang gửi',
                            expand: true,
                            onPressed: _deciding == null
                                ? () => _decide(approve: false)
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space3),
                        Expanded(
                          child: AppButton(
                            label: 'Duyệt',
                            isLoading: _deciding == true,
                            loadingLabel: 'Đang gửi',
                            expand: true,
                            onPressed: _deciding == null
                                ? () => _decide(approve: true)
                                : null,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Duyệt xong, số suất mới tự gửi tới bếp.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.item,
    required this.reason,
    required this.reasonError,
    required this.reasonKey,
    required this.pending,
  });

  final MealAdjustment item;
  final TextEditingController reason;
  final String? reasonError;
  final GlobalKey reasonKey;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!pending) ...[
            AppBanner(
              kind: AppBannerKind.neutral,
              message: item.decision == RequestDecision.approved
                  ? 'Yêu cầu đã được duyệt.'
                  : 'Yêu cầu đã bị từ chối.',
            ),
            const SizedBox(height: AppSpacing.space3),
          ],
          AppCard(
            dense: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.space2,
                  runSpacing: AppSpacing.space2,
                  children: [
                    // Mũi tên vẽ bằng icon: font Be Vietnam Pro không có ký tự →
                    Semantics(
                      container: true,
                      label:
                          '${item.className}: từ ${item.fromCount} thành ${item.toCount} suất',
                      excludeSemantics: true,
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.space1,
                        children: [
                          Text(
                            '${item.className}: ${item.fromCount}',
                            style: textTheme.titleMedium,
                          ),
                          const Icon(
                            AppIcons.arrowRight,
                            size: AppSizes.iconInline,
                            color: AppColors.textSecondary,
                          ),
                          Text(
                            '${item.toCount} suất',
                            style: textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    AppStatusBadge(
                      label: item.statusLabel,
                      tone: AppStatusTone.orange,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  'Người gửi: ${item.senderName} · ${DateLabels.time24(item.sentAt)}',
                  style: muted,
                ),
                Text('Lý do: ${item.reason}', style: muted),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space5),
          Semantics(
            header: true,
            child: Text(item.childrenTitle, style: textTheme.titleSmall),
          ),
          const SizedBox(height: AppSpacing.space2),
          for (final child in item.children) ...[
            AppCard(
              dense: true,
              child: Row(
                children: [
                  AppAvatar(name: child.fullName),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(child.fullName, style: textTheme.titleSmall),
                        Text(child.note, style: muted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
          ],
          const SizedBox(height: AppSpacing.space3),
          Semantics(
            header: true,
            child: Text('Tình trạng bếp', style: textTheme.titleSmall),
          ),
          const SizedBox(height: AppSpacing.space2),
          AppCard(
            dense: true,
            child: Row(
              children: [
                const AppIconTile(
                  icon: AppIcons.kitchen,
                  tone: AppStatusTone.teal,
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.kitchenTitle, style: textTheme.titleSmall),
                      Text(item.kitchenNote, style: muted),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                AppStatusBadge(
                  label: item.kitchenBadge,
                  tone: AppStatusTone.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          AppCard(
            dense: true,
            child: Column(
              children: [
                _TotalRow(
                  label: 'Tổng suất hiện tại',
                  value: '${item.totalNow}',
                ),
                _TotalRow(label: 'Sau khi duyệt', value: '${item.totalAfter}'),
                _TotalRow(label: 'Thường / Thay thế', value: item.splitAfter),
              ],
            ),
          ),
          if (pending) ...[
            const SizedBox(height: AppSpacing.space4),
            AppTextField(
              key: reasonKey,
              label: 'Lý do (chỉ khi từ chối)',
              controller: reason,
              multiline: true,
              errorText: reasonError,
              maxLength: 200,
            ),
          ],
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              value,
              style: textTheme.titleSmall?.copyWith(
                fontFeatures: AppTextStyles.tabularFigures,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

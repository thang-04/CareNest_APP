import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/integration/load_failure.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher/pickup/data/fake_pickup_source.dart';
import 'package:carenest_app/features/teacher/pickup/domain/pickup.dart';
import 'package:carenest_app/features/teacher/pickup/presentation/screens/pickup_list_screen.dart';

/// Kết quả trả trẻ hôm nay của các lớp giáo viên — như trang "Kết quả trả trẻ" của Web (chỉ xem):
/// Trẻ, Lớp, Người đón, Xác minh, Kết quả, Ghi nhận lúc.
class PickupResultScreen extends StatefulWidget {
  const PickupResultScreen({super.key, this.source, this.today});

  final PickupSource? source;

  /// Hôm nay theo giờ nhà trường (tiêu đề); mặc định ngày máy (bản giả: ngày giả).
  final DateTime? today;

  @override
  State<PickupResultScreen> createState() => _PickupResultScreenState();
}

class _PickupResultScreenState extends State<PickupResultScreen> {
  late final PickupSource _source = widget.source ?? FakePickupSource.shared;
  late final DateTime _today =
      widget.today ??
      (_source is FakePickupSource ? FakePickupSource.today : DateTime.now());
  List<PickupRecord>? _results;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _results = null;
      _error = null;
    });
    try {
      final results = await _source.loadResults();
      if (mounted) setState(() => _results = results);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả trả trẻ')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Text(
            'Kết quả trả trẻ ngày ${DateLabels.date(_today)}',
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.space3),
          if (_error != null)
            AppErrorState(
              title: 'Chưa tải được kết quả trả trẻ',
              message: loadFailureMessage(_error),
              onRetry: _load,
            )
          else if (results == null)
            const AppSkeletonList(rows: 4)
          else if (results.isEmpty)
            const AppEmptyState(
              icon: AppIcons.clipboardCheck,
              title: 'Chưa có kết quả trả trẻ hôm nay',
              message:
                  'Chọn trẻ trong danh sách đón trẻ để xác minh người đón.',
            )
          else
            for (final result in results) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.space2,
                      runSpacing: AppSpacing.space1,
                      children: [
                        Text(
                          result.childName ?? '',
                          style: textTheme.titleSmall,
                        ),
                        result.verification.handedOver
                            ? const AppStatusBadge(
                                label: 'Đã trả trẻ',
                                tone: AppStatusTone.green,
                                icon: AppIcons.checkCircle,
                              )
                            : const AppStatusBadge(
                                label: 'Không trả trẻ',
                                tone: AppStatusTone.red,
                              ),
                      ],
                    ),
                    if ((result.className ?? '').isNotEmpty)
                      Text(result.className!, style: muted),
                    const SizedBox(height: AppSpacing.space2),
                    Text('Người đón: ${pickupPersonLabel(result)}'),
                    const SizedBox(height: AppSpacing.space2),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppStatusBadge(
                        label: result.verification.label,
                        tone: pickupVerificationTone(result.verification),
                      ),
                    ),
                    if ((result.note ?? '').isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.space2),
                      Text(result.note!, style: muted),
                    ],
                    if (result.recordedAt != null) ...[
                      const SizedBox(height: AppSpacing.space2),
                      Text(
                        'Ghi nhận lúc ${DateLabels.time24(result.recordedAt!)} ${DateLabels.date(result.recordedAt!)}',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
            ],
        ],
      ),
    );
  }
}

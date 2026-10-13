import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_search_field.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/pickup/data/fake_pickup_source.dart';
import 'package:carenest_app/features/pickup/domain/pickup.dart';

/// Đón trẻ — danh sách chờ đón (mockup T05). Chưa có rule BE (plan K4): bản giả ở debug.
class PickupListScreen extends StatefulWidget {
  const PickupListScreen({
    super.key,
    required this.onVerify,
    this.classId = FakeClassRosterSource.classId,
    this.source,
  });

  /// Mở màn xác minh người đón; trả về khi đóng để tải lại.
  final Future<void> Function(String childId) onVerify;
  final String classId;
  final PickupSource? source;

  @override
  State<PickupListScreen> createState() => _PickupListScreenState();
}

class _PickupListScreenState extends State<PickupListScreen> {
  late final PickupSource _source = widget.source ?? FakePickupSource.shared;
  List<PickupKid>? _kids;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final kids = await _source.loadClass(widget.classId);
    if (mounted) setState(() => _kids = kids);
  }

  Future<void> _verify(PickupKid kid) async {
    await widget.onVerify(kid.childId);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final kids = _kids;
    final picked = kids?.where((kid) => kid.pickedUp).length ?? 0;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Đón trẻ')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          if (kids == null)
            const AppSkeletonList(rows: 5)
          else ...[
            AppStatRow(
              tiles: [
                AppStatTile(
                  value: '$picked',
                  label: 'Đã đón',
                  tone: AppStatusTone.green,
                ),
                AppStatTile(
                  value: '${kids.length - picked}',
                  label: 'Chờ đón',
                  tone: AppStatusTone.orange,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
            AppSearchField(
              hint: 'Tìm tên bé…',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: AppSpacing.space3),
            for (final kid in kids.where(
              (kid) => matchesSearch(kid.fullName, _query),
            )) ...[
              AppCard(
                flush: true,
                child: AppListRow(
                  leading: AppAvatar(name: kid.fullName),
                  title: kid.fullName,
                  subtitle: Text(
                    kid.pickedUp
                        ? 'Đã đón ${DateLabels.time24(kid.pickedUpAt!)} · ${kid.pickedUpBy}'
                        : 'Đăng ký: ${kid.guardians.map(_shortName).join(', ')}',
                  ),
                  trailing: kid.pickedUp
                      ? const AppStatusBadge(
                          label: 'Đã đón',
                          tone: AppStatusTone.green,
                        )
                      : AppButton(
                          label: 'Giao bé',
                          small: true,
                          onPressed: () => _verify(kid),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
            ],
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Chạm “Giao bé” để xác minh người đón trước khi giao.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  /// "Mẹ Thu Lan": bỏ họ cho gọn dòng.
  static String _shortName(RegisteredGuardian guardian) {
    final parts = guardian.fullName.split(' ');
    final given = parts.length > 1
        ? parts.sublist(1).join(' ')
        : guardian.fullName;
    return '${guardian.relation} $given';
  }
}

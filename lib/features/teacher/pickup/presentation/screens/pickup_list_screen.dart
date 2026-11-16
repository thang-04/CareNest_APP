import 'package:flutter/material.dart';

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
import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/pickup/data/fake_pickup_source.dart';
import 'package:carenest_app/features/teacher/pickup/domain/pickup.dart';

/// Trả trẻ — bảng đón của lớp (mockup T05), dạng theo BE `PickupBoardResponse`: bé có mặt chia
/// Chờ đón / Đã đón; chạm "Trả trẻ" để đối chiếu phụ huynh trên hồ sơ (PCK-02).
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
  List<PickupRow>? _kids;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final kids = await _source.loadBoard(widget.classId);
    if (mounted) setState(() => _kids = kids);
  }

  Future<void> _verify(PickupRow kid) async {
    await widget.onVerify(kid.childId);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final kids = _kids;
    final picked =
        kids?.where((kid) => kid.status == PickupStatus.pickedUp).length ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Trả trẻ')),
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
                    kid.status == PickupStatus.pickedUp
                        ? _pickedLine(kid.pickup!)
                        : 'Chờ đón',
                  ),
                  trailing: kid.status == PickupStatus.pickedUp
                      ? const AppStatusBadge(
                          label: 'Đã đón',
                          tone: AppStatusTone.green,
                        )
                      : AppButton(
                          label: 'Trả trẻ',
                          small: true,
                          onPressed: () => _verify(kid),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
            ],
          ],
        ],
      ),
    );
  }

  /// "Đã đón 16:35 · Mẹ Nguyễn Thu Lan" / "· đã gọi xác nhận".
  static String _pickedLine(PickupRecord record) {
    final who = record.pickupPersonName == null
        ? 'đã gọi xác nhận'
        : '${record.pickupPersonRelationship?.label ?? ''} ${record.pickupPersonName}'
              .trim();
    final time = record.handedOverAt == null
        ? ''
        : ' ${DateLabels.time24(record.handedOverAt!)}';
    return 'Đã đón$time · $who';
  }
}

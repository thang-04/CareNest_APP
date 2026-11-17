import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_avatar.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher/daily_health/data/fake_daily_health_source.dart';
import 'package:carenest_app/features/teacher/daily_health/domain/daily_health.dart';
import 'package:carenest_app/features/teacher/daily_health/presentation/screens/daily_health_entry_screen.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Sức khỏe đầu ngày (HLT-07) và trong ngày (HLT-14): danh sách bé có mặt, chạm một bé để ghi
/// thân nhiệt, quan sát, triệu chứng, xử trí. Bé chưa ghi hiện "Chưa kiểm tra" — APP không tự
/// coi là bình thường; mức nhiệt và báo phụ huynh do BE xử lý.
class DailyHealthScreen extends StatefulWidget {
  const DailyHealthScreen({super.key, required this.classId, this.source});

  final String classId;
  final DailyHealthSource? source;

  @override
  State<DailyHealthScreen> createState() => _DailyHealthScreenState();
}

class _DailyHealthScreenState extends State<DailyHealthScreen> {
  late final DailyHealthSource _source =
      widget.source ?? FakeDailyHealthSource.shared;
  DailyHealthSheet? _sheet;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final sheet = await _source.loadSheet(widget.classId);
      if (!mounted) return;
      setState(() => _sheet = sheet);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  Future<void> _open(DailyHealthSheet sheet, DailyHealthKid kid) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            DailyHealthEntryScreen(sheet: sheet, kid: kid, source: _source),
      ),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sức khỏe đầu ngày')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          child: AppErrorState(
            title: 'Chưa tải được danh sách',
            message: 'Kiểm tra kết nối mạng rồi thử lại.',
            onRetry: _load,
          ),
        ),
      );
    }
    final sheet = _sheet;
    if (sheet == null) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.pagePadding),
        child: AppSkeletonList(rows: 6),
      );
    }
    if (sheet.kids.isEmpty) {
      return const Center(
        child: SingleChildScrollView(
          child: AppEmptyState(
            icon: AppIcons.heart,
            title: 'Chưa có bé có mặt',
            message: 'Lưu điểm danh trước, bé có mặt sẽ hiện ở đây.',
          ),
        ),
      );
    }
    final textTheme = Theme.of(context).textTheme;
    final checked = sheet.kids.where((kid) => kid.checked).length;
    final noted = sheet.kids
        .where((kid) => kid.latest?.observation == HealthObservation.noted)
        .length;
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: sheet.kids.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${sheet.className} · ${DateLabels.weekdayDayMonth(sheet.date)}',
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.space3),
              AppCard(
                flush: true,
                child: AppListRow(
                  leading: const AppIconTile(
                    icon: AppIcons.heart,
                    tone: AppStatusTone.blue,
                  ),
                  title: 'Cân nặng & chiều cao',
                  subtitle: const Text('Nhập nhanh trong đợt cân đo'),
                  showChevron: true,
                  onTap: () => context.push(RoutePaths.teacherHealth),
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              AppStatRow(
                tiles: [
                  AppStatTile(
                    value: '${sheet.kids.length}',
                    label: 'Có mặt',
                    tone: AppStatusTone.green,
                  ),
                  AppStatTile(value: '$checked', label: 'Đã kiểm tra'),
                  AppStatTile(
                    value: '$noted',
                    label: 'Cần lưu ý',
                    tone: AppStatusTone.orange,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              if (!sheet.canRecord) ...[
                const AppBanner(icon: AppIcons.lock, message: 'Chỉ xem'),
                const SizedBox(height: AppSpacing.space3),
              ],
            ],
          );
        }
        final kid = sheet.kids[index - 1];
        return Padding(
          key: ValueKey(kid.childId),
          padding: const EdgeInsets.only(bottom: AppSpacing.cardGap),
          child: AppCard(
            flush: true,
            child: AppListRow(
              leading: AppAvatar(name: kid.fullName),
              title: kid.fullName,
              subtitle: Text(_subtitle(kid)),
              trailing: _badge(kid),
              showChevron: sheet.canRecord,
              onTap: sheet.canRecord ? () => _open(sheet, kid) : null,
            ),
          ),
        );
      },
    );
  }

  static String _subtitle(DailyHealthKid kid) {
    final latest = kid.latest;
    if (latest == null) return 'Chưa kiểm tra';
    return [
      if (latest.temperature != null) formatTemperature(latest.temperature!),
      ...latest.symptoms.map((s) => s.label),
      if (latest.recordedAt != null) DateLabels.time24(latest.recordedAt!),
    ].join(' · ');
  }

  static Widget? _badge(DailyHealthKid kid) =>
      switch (kid.latest?.observation) {
        null => null,
        HealthObservation.noConcern => const AppStatusBadge(
          label: 'Bình thường',
          tone: AppStatusTone.green,
        ),
        HealthObservation.noted => const AppStatusBadge(
          label: 'Cần lưu ý',
          tone: AppStatusTone.orange,
        ),
      };
}

/// "37,8 °C" — dấu phẩy thập phân theo tiếng Việt.
String formatTemperature(double value) =>
    '${value.toStringAsFixed(1).replaceAll('.', ',')} °C';

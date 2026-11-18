import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_bottom_sheet.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/kitchen/food_samples/data/fake_food_sample_source.dart';
import 'package:carenest_app/features/kitchen/food_samples/domain/food_sample.dart';
import 'package:carenest_app/features/kitchen/kitchen_day/data/fake_kitchen_day_source.dart';
import 'package:carenest_app/features/kitchen/kitchen_day/domain/kitchen_day.dart';

/// Bếp · Sổ lưu mẫu thức ăn (NUT-21): mỗi bữa ghi món đã lưu mẫu và giờ lấy;
/// đủ 24 giờ thì ghi hủy. PHT dinh dưỡng duyệt trên Web; bản đã duyệt không sửa.
class FoodSampleLogScreen extends StatefulWidget {
  const FoodSampleLogScreen({
    super.key,
    this.daySource,
    this.sampleSource,
    this.now,
  });

  final KitchenDaySource? daySource;
  final FoodSampleSource? sampleSource;

  /// Giờ hiện tại, thay được khi test.
  final DateTime Function()? now;

  @override
  State<FoodSampleLogScreen> createState() => _FoodSampleLogScreenState();
}

typedef _LogData = (KitchenDay, List<FoodSample>);

class _FoodSampleLogScreenState extends State<FoodSampleLogScreen> {
  late final KitchenDaySource _days =
      widget.daySource ?? FakeKitchenDaySource();
  late final FoodSampleSource _samples =
      widget.sampleSource ?? FakeFoodSampleSource();
  late Future<_LogData> _data = _load();

  DateTime _now() => (widget.now ?? DateTime.now)();

  Future<_LogData> _load() async {
    final day = await _days.loadDay();
    // 7 ngày gần nhất: đủ để thấy mẫu còn chờ hủy
    final samples = await _samples.loadSamples(
      day.date.subtract(const Duration(days: 7)),
      day.date,
    );
    return (day, samples);
  }

  void _reload() {
    setState(() {
      _data = _load();
    });
  }

  Future<void> _openRecord(
    KitchenDay day,
    MealSession session,
    FoodSample? sample,
  ) async {
    final saved = await showAppBottomSheet<bool>(
      context: context,
      title: '${sample == null ? 'Lưu mẫu' : 'Sửa lưu mẫu'} · ${session.label}',
      builder: (_) => _RecordSheet(
        date: day.date,
        session: session,
        dishes: day.dishesOf(session),
        sample: sample,
        now: _now,
        onSubmit: (draft) => sample == null
            ? _samples.create(draft)
            : _samples.update(sample.id, draft),
      ),
    );
    if (saved == true && mounted) _reload();
  }

  Future<void> _openDispose(FoodSample sample) async {
    final saved = await showAppBottomSheet<bool>(
      context: context,
      title: 'Hủy mẫu · ${sample.session.label}',
      builder: (_) => _DisposeSheet(
        sample: sample,
        now: _now,
        onSubmit: (at) => _samples.dispose(sample.id, at),
      ),
    );
    if (saved == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sổ lưu mẫu')),
      body: FutureBuilder<_LogData>(
        future: _data,
        builder: (context, snapshot) => switch (snapshot) {
          AsyncSnapshot(hasError: true) => Center(
            child: AppErrorState(
              title: 'Chưa tải được sổ lưu mẫu',
              message: 'Kiểm tra kết nối mạng rồi thử lại.',
              onRetry: _reload,
            ),
          ),
          AsyncSnapshot(hasData: true, :final data?) => _body(data),
          _ => const Padding(
            padding: EdgeInsets.all(AppSpacing.pagePadding),
            child: AppSkeletonList(rows: 4),
          ),
        },
      ),
    );
  }

  Widget _body(_LogData data) {
    final (day, samples) = data;
    final textTheme = Theme.of(context).textTheme;
    final sessions = MealSession.values
        .where((session) => day.dishesOf(session).isNotEmpty)
        .toList();
    final today = DateUtils.dateOnly(day.date);
    final toDispose =
        samples
            .where(
              (s) =>
                  DateUtils.dateOnly(s.date).isBefore(today) &&
                  s.disposalStatus != FoodSampleDisposalStatus.approved,
            )
            .toList()
          ..sort((a, b) => a.sampledAt.compareTo(b.sampledAt));
    FoodSample? sampleOf(MealSession session) => samples
        .where(
          (s) => DateUtils.isSameDay(s.date, today) && s.session == session,
        )
        .firstOrNull;

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Text(
            'Hôm nay · ${DateLabels.weekdayDate(day.date)}',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.space3),
          if (day.dayOff || sessions.isEmpty)
            const AppEmptyState(
              icon: AppIcons.meal,
              title: 'Hôm nay không có bữa ăn',
              message: 'Chưa có thực đơn đã công bố cho ngày này.',
            )
          else
            for (final session in sessions) ...[
              _TodayCard(
                session: session,
                dishes: day.dishesOf(session),
                sample: sampleOf(session),
                onRecord: () => _openRecord(day, session, sampleOf(session)),
              ),
              const SizedBox(height: AppSpacing.space3),
            ],
          const SizedBox(height: AppSpacing.space4),
          Text('Hủy mẫu', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.space3),
          if (toDispose.isEmpty)
            Text(
              'Không có mẫu cần hủy.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            )
          else
            for (final sample in toDispose) ...[
              _DisposeCard(
                sample: sample,
                canDispose: sample.canDisposeAt(_now()),
                onDispose: () => _openDispose(sample),
              ),
              const SizedBox(height: AppSpacing.space3),
            ],
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.session,
    required this.dishes,
    required this.sample,
    required this.onRecord,
  });

  final MealSession session;
  final List<MenuDish> dishes;
  final FoodSample? sample;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sample = this.sample;
    final (badge, tone) = sample == null
        ? ('Chưa lưu mẫu', AppStatusTone.orange)
        : (
            sample.status.label,
            sample.status == FoodSampleStatus.approved
                ? AppStatusTone.green
                : AppStatusTone.approval,
          );
    final shown = sample?.dishes ?? dishes;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(session.label, style: textTheme.titleSmall)),
              AppStatusBadge(label: badge, tone: tone),
            ],
          ),
          if (sample != null)
            Text(
              'Lấy mẫu ${DateLabels.time24(sample.sampledAt)}',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            shown.map((dish) => dish.name).join(' · '),
            style: textTheme.bodyMedium,
          ),
          if (sample == null) ...[
            const SizedBox(height: AppSpacing.space3),
            AppButton(
              label: 'Lưu mẫu',
              icon: AppIcons.check,
              expand: true,
              onPressed: onRecord,
            ),
          ] else if (sample.editable) ...[
            const SizedBox(height: AppSpacing.space3),
            AppButton(
              label: 'Sửa',
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: onRecord,
            ),
          ],
        ],
      ),
    );
  }
}

class _DisposeCard extends StatelessWidget {
  const _DisposeCard({
    required this.sample,
    required this.canDispose,
    required this.onDispose,
  });

  final FoodSample sample;
  final bool canDispose;
  final VoidCallback onDispose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final disposedAt = sample.disposedAt;
    final (badge, tone) = switch (sample.disposalStatus) {
      FoodSampleDisposalStatus.none when canDispose => (
        'Cần hủy',
        AppStatusTone.orange,
      ),
      FoodSampleDisposalStatus.none => ('Chưa đủ 24 giờ', AppStatusTone.gray),
      final status => (status.label, AppStatusTone.approval),
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${sample.session.label} · ${DateLabels.dayMonth(sample.date)}',
                  style: textTheme.titleSmall,
                ),
              ),
              AppStatusBadge(label: badge, tone: tone),
            ],
          ),
          Text(
            disposedAt != null
                ? 'Đã hủy lúc ${DateLabels.time24(disposedAt)} ${DateLabels.dayMonth(disposedAt)}'
                : 'Hủy từ ${DateLabels.time24(sample.disposableFrom)} ${DateLabels.dayMonth(sample.disposableFrom)}',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          if (sample.awaitingDisposal && canDispose) ...[
            const SizedBox(height: AppSpacing.space3),
            AppButton(
              label: 'Ghi hủy',
              icon: AppIcons.check,
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: onDispose,
            ),
          ],
        ],
      ),
    );
  }
}

/// Chọn món đã lấy mẫu (mặc định đủ món của bữa), giờ lấy mẫu, ghi chú.
class _RecordSheet extends StatefulWidget {
  const _RecordSheet({
    required this.date,
    required this.session,
    required this.dishes,
    required this.sample,
    required this.now,
    required this.onSubmit,
  });

  final DateTime date;
  final MealSession session;
  final List<MenuDish> dishes;
  final FoodSample? sample;
  final DateTime Function() now;
  final Future<void> Function(FoodSampleDraft draft) onSubmit;

  @override
  State<_RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends State<_RecordSheet> {
  late final Set<int> _picked = {
    for (final dish in widget.sample?.dishes ?? widget.dishes) dish.id,
  };
  late TimeOfDay _time = TimeOfDay.fromDateTime(
    widget.sample?.sampledAt ?? widget.now(),
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.sample?.note,
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  DateTime get _sampledAt {
    final at = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      _time.hour,
      _time.minute,
    );
    // Không cho giờ sau hiện tại (BE kiểm tra lại)
    final now = widget.now();
    return at.isAfter(now) ? now : at;
  }

  Future<void> _chooseTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: 'Giờ lấy mẫu',
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (_picked.isEmpty) {
      setState(() => _error = 'Chọn ít nhất 1 món.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final note = _note.text.trim();
      await widget.onSubmit(
        FoodSampleDraft(
          date: widget.date,
          session: widget.session,
          dishIds: [
            for (final dish in widget.dishes)
              if (_picked.contains(dish.id)) dish.id,
          ],
          sampledAt: _sampledAt,
          note: note.isEmpty ? null : note,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Chưa lưu được. Kiểm tra mạng rồi thử lại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Món lưu mẫu', style: textTheme.titleSmall),
        const SizedBox(height: AppSpacing.space2),
        for (final dish in widget.dishes) ...[
          AppSheetOption(
            selected: _picked.contains(dish.id),
            onTap: _saving
                ? () {}
                : () => setState(() {
                    if (!_picked.remove(dish.id)) _picked.add(dish.id);
                    _error = null;
                  }),
            child: Text(dish.name, style: textTheme.bodyLarge),
          ),
          const SizedBox(height: AppSpacing.space1),
        ],
        const SizedBox(height: AppSpacing.space3),
        AppSelectField(
          label: 'Giờ lấy mẫu',
          value: _time.format(context),
          onTap: _saving ? null : _chooseTime,
        ),
        const SizedBox(height: AppSpacing.space3),
        AppTextField(
          label: 'Ghi chú',
          labelSuffix: '(không bắt buộc)',
          controller: _note,
          maxLength: 500,
          enabled: !_saving,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.space3),
          AppBanner(kind: AppBannerKind.danger, message: _error!),
        ],
        const SizedBox(height: AppSpacing.space4),
        AppButton(
          label: 'Lưu',
          icon: AppIcons.check,
          expand: true,
          isLoading: _saving,
          loadingLabel: 'Đang lưu',
          onPressed: _submit,
        ),
      ],
    );
  }
}

/// Ghi giờ hủy mẫu: mặc định giờ hiện tại, không trước mốc 24 giờ, không sau hiện tại.
class _DisposeSheet extends StatefulWidget {
  const _DisposeSheet({
    required this.sample,
    required this.now,
    required this.onSubmit,
  });

  final FoodSample sample;
  final DateTime Function() now;
  final Future<void> Function(DateTime disposedAt) onSubmit;

  @override
  State<_DisposeSheet> createState() => _DisposeSheetState();
}

class _DisposeSheetState extends State<_DisposeSheet> {
  late DateTime _at = widget.now();
  bool _saving = false;
  String? _error;

  Future<void> _chooseTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_at),
      helpText: 'Giờ hủy mẫu',
    );
    if (picked == null || !mounted) return;
    final now = widget.now();
    var at = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
    if (at.isAfter(now)) at = now;
    if (at.isBefore(widget.sample.disposableFrom)) {
      at = widget.sample.disposableFrom;
    }
    setState(() => _at = at);
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_at);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Chưa ghi được. Kiểm tra mạng rồi thử lại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sample = widget.sample;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Mẫu ngày ${DateLabels.dayMonth(sample.date)} · lấy lúc ${DateLabels.time24(sample.sampledAt)}',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          sample.dishes.map((dish) => dish.name).join(' · '),
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.space4),
        AppSelectField(
          label: 'Giờ hủy',
          value: DateLabels.time24(_at),
          onTap: _saving ? null : _chooseTime,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.space3),
          AppBanner(kind: AppBannerKind.danger, message: _error!),
        ],
        const SizedBox(height: AppSpacing.space4),
        AppButton(
          label: 'Ghi hủy',
          icon: AppIcons.check,
          expand: true,
          isLoading: _saving,
          loadingLabel: 'Đang ghi',
          onPressed: _submit,
        ),
      ],
    );
  }
}

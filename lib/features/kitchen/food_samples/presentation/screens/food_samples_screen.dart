import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:carenest_app/core/integration/load_failure.dart';
import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_bottom_sheet.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/kitchen/food_samples/data/fake_food_sample_source.dart';
import 'package:carenest_app/features/kitchen/food_samples/domain/food_samples.dart';
import 'package:carenest_app/features/kitchen/food_samples/presentation/food_samples_status.dart';
import 'package:carenest_app/features/kitchen/food_samples/presentation/widgets/food_sample_widgets.dart';

/// Bếp · Sổ lưu mẫu (NUT-21, canvas "Sổ lưu mẫu"): mỗi bữa ghi món đã lưu mẫu kèm khối lượng,
/// dụng cụ chứa, nhiệt độ (Mẫu 5); sửa khi PHT chưa duyệt; ghi hủy mẫu khi đến hạn. PHT duyệt và
/// in biểu mẫu trên Web. BE đã có `/nutrition/food-samples`; App chưa nối ⇒ dữ liệu giả.
class FoodSamplesScreen extends StatefulWidget {
  const FoodSamplesScreen({super.key, this.source});

  final FoodSampleSource? source;

  @override
  State<FoodSamplesScreen> createState() => _FoodSamplesScreenState();
}

class _FoodSamplesScreenState extends State<FoodSamplesScreen> {
  late final FoodSampleSource _source =
      widget.source ?? FakeFoodSampleSource.shared;
  late Future<FoodSampleDay> _day = _source.loadToday();

  /// Ô nhập theo bữa rồi theo món; giữ chữ đã nhập khi lưu lỗi
  final Map<String, Map<int, DishNoteControllers>> _forms = {};

  /// Bữa đã ghi đang sửa
  final Set<String> _editing = {};
  final Set<String> _saving = {};
  final Map<String, String> _saveErrors = {};
  final Set<int> _disposing = {};

  /// Khung từng thẻ bữa, để giữ thẻ trong màn khi form thu gọn
  final Map<String, GlobalKey> _cardKeys = {};
  final Map<int, String> _disposeErrors = {};

  static const _saveError = 'Chưa lưu được mẫu. Kiểm tra mạng rồi lưu lại.';
  static const _disposeError =
      'Chưa ghi được hủy mẫu. Kiểm tra mạng rồi thử lại.';

  @override
  void dispose() {
    for (final form in _forms.values) {
      for (final controllers in form.values) {
        controllers.dispose();
      }
    }
    super.dispose();
  }

  /// Bỏ form của bữa; huỷ controller sau khung hình kế tiếp, khi ô nhập đã gỡ khỏi cây
  void _dropForm(String session) {
    final form = _forms.remove(session);
    if (form == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controllers in form.values) {
        controllers.dispose();
      }
    });
  }

  /// Món gần nhất đã ghi dụng cụ chứa / nhiệt độ: điền sẵn cho bữa mới, bếp sửa nếu khác
  static SampleDish? _lastNoted(FoodSampleDay day) {
    final samples = [
      for (final session in day.sessions) ?session.sample,
      ...day.toDispose,
    ]..sort((a, b) => b.sampledAt.compareTo(a.sampledAt));
    for (final sample in samples) {
      for (final dish in sample.dishes) {
        if (dish.container.isNotEmpty || dish.temperature.isNotEmpty) {
          return dish;
        }
      }
    }
    return null;
  }

  Map<int, DishNoteControllers> _formFor(
    SampleSession session,
    FoodSampleDay day,
  ) => _forms.putIfAbsent(session.session, () {
    final sample = session.sample;
    if (sample != null) {
      return {
        for (final dish in sample.dishes) dish.id: DishNoteControllers(dish),
      };
    }
    final last = _lastNoted(day);
    return {
      for (final dish in session.dishes)
        dish.id: DishNoteControllers(
          SampleDish(
            id: dish.id,
            name: dish.name,
            container: last?.container ?? '',
            temperature: last?.temperature ?? '',
          ),
        ),
    };
  });

  Future<void> _save(SampleSession session) async {
    final form = _forms[session.session];
    if (form == null) return;
    setState(() {
      _saving.add(session.session);
      _saveErrors.remove(session.session);
    });
    try {
      final day = await _source.saveSample(
        session: session.session,
        sampleId: session.sample?.id,
        dishes: [
          for (final MapEntry(key: dishId, value: controllers) in form.entries)
            controllers.input(dishId),
        ],
      );
      if (!mounted) return;
      _keepCardInView(session.session);
      setState(() {
        _saving.remove(session.session);
        _editing.remove(session.session);
        _dropForm(session.session);
        _day = Future.value(day);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving.remove(session.session);
        _saveErrors[session.session] = _saveError;
      });
    }
  }

  /// Form dài thu gọn thì màn trôi xuống bữa sau: nhớ đầu thẻ rồi cuộn về đó để bếp thấy kết quả
  void _keepCardInView(String session) {
    final context = _cardKeys[session]?.currentContext;
    final box = context?.findRenderObject();
    if (context == null || box == null) return;
    final position = Scrollable.maybeOf(context)?.position;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (position == null || viewport == null) return;
    final top = viewport.getOffsetToReveal(box, 0).offset;
    if (position.pixels <= top) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      position.jumpTo(
        top.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
    });
  }

  void _startEdit(SampleSession session) {
    setState(() {
      _editing.add(session.session);
    });
  }

  void _cancelEdit(SampleSession session) {
    _keepCardInView(session.session);
    setState(() {
      _editing.remove(session.session);
      _saveErrors.remove(session.session);
      _dropForm(session.session);
    });
  }

  Future<void> _confirmDispose(FoodSample sample) async {
    final confirmed = await showAppBottomSheet<bool>(
      context: context,
      title:
          'Ghi hủy mẫu ${FoodSamplesStatus.pastTitle(sample).toLowerCase()}?',
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bếp ghi đã hủy mẫu này lúc bấm xác nhận. PHT duyệt hủy trên Web; ghi rồi không sửa được.',
            style: Theme.of(
              sheetContext,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.space4),
          AppButton(
            label: 'Ghi hủy mẫu',
            expand: true,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
          const SizedBox(height: AppSpacing.space2),
          AppButton(
            label: 'Để sau',
            variant: AppButtonVariant.text,
            expand: true,
            onPressed: () => Navigator.of(sheetContext).pop(false),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _disposing.add(sample.id);
      _disposeErrors.remove(sample.id);
    });
    try {
      final day = await _source.recordDisposal(sample.id);
      if (!mounted) return;
      setState(() {
        _disposing.remove(sample.id);
        _day = Future.value(day);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _disposing.remove(sample.id);
        _disposeErrors[sample.id] = _disposeError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sổ lưu mẫu')),
      body: FutureBuilder<FoodSampleDay>(
        future: _day,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: AppErrorState(
                title: 'Chưa tải được sổ lưu mẫu',
                message: loadFailureMessage(snapshot.error),
                onRetry: () => setState(() {
                  _day = _source.loadToday();
                }),
              ),
            );
          }
          final day = snapshot.data;
          if (day == null) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 3),
            );
          }
          if (day.isDayOff && day.toDispose.isEmpty) {
            return const Center(
              child: AppEmptyState(
                title: 'Hôm nay trường nghỉ',
                message: 'Không có bữa nào cần lưu mẫu.',
              ),
            );
          }
          return _content(context, day);
        },
      ),
    );
  }

  Widget _content(BuildContext context, FoodSampleDay day) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Text(sampleDayLabel(day), style: muted),
        const SizedBox(height: AppSpacing.space2),
        Text(
          'Mỗi bữa lưu mẫu các món đã nấu, giữ ít nhất 24 giờ rồi hủy. PHT duyệt cả lưu mẫu và hủy mẫu.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        for (final session in day.sessions) ...[
          const SizedBox(height: AppSpacing.space4),
          KeyedSubtree(
            key: _cardKeys.putIfAbsent(session.session, GlobalKey.new),
            child: _sessionCard(context, session, day),
          ),
        ],
        if (day.toDispose.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sectionGap),
          Semantics(
            header: true,
            child: Text('Mẫu cần hủy', style: textTheme.titleMedium),
          ),
          for (final sample in day.toDispose) ...[
            const SizedBox(height: AppSpacing.space3),
            DisposalCard(
              key: ValueKey('disposal-${sample.id}'),
              sample: sample,
              busy: _disposing.contains(sample.id),
              error: _disposeErrors[sample.id],
              onDispose: () => _confirmDispose(sample),
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.sectionGap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(AppIcons.info, size: AppSizes.iconBadge, color: muted?.color),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                'Nhãn mẫu và sổ lưu, hủy mẫu (Mẫu 4, Mẫu 5) PHT in trên Web sau khi duyệt.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sessionCard(
    BuildContext context,
    SampleSession session,
    FoodSampleDay day,
  ) {
    final key = ValueKey('sample-${session.session}');
    final sample = session.sample;
    final mealName = session.label.toLowerCase();
    if (sample != null && !_editing.contains(session.session)) {
      return SampleCardFrame(
        key: key,
        title: session.label,
        badge: FoodSamplesStatus.sample(sample.status),
        subtitle: FoodSamplesStatus.sampled(sample),
        children: [
          for (final dish in sample.dishes) ...[
            const SizedBox(height: AppSpacing.space3),
            SampleDishLine(dish: dish),
          ],
          // Như BE: sửa được khi PHT chưa duyệt và chưa ghi hủy
          if (sample.editable) ...[
            const SizedBox(height: AppSpacing.space3),
            AppButton(
              label: 'Sửa lưu mẫu $mealName',
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: () => _startEdit(session),
            ),
          ],
        ],
      );
    }
    final dishNames = session.dishes.map(FoodSamplesStatus.dishName).join(', ');
    if (sample == null && session.upcoming) {
      return SampleCardFrame(
        key: key,
        muted: true,
        title: session.label,
        badge: FoodSamplesStatus.upcoming,
        subtitle: session.dishes.isEmpty
            ? 'Thực đơn hôm nay chưa công bố.'
            : '${session.dishes.length} món theo thực đơn đã công bố',
        children: [
          if (dishNames.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              dishNames,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      );
    }
    if (sample == null && session.dishes.isEmpty) {
      return SampleCardFrame(
        key: key,
        title: session.label,
        badge: FoodSamplesStatus.notRecorded,
        subtitle: 'Chưa có món để lưu mẫu: thực đơn hôm nay chưa công bố.',
        children: const [],
      );
    }
    return _formCard(context, session, day, key);
  }

  Widget _formCard(
    BuildContext context,
    SampleSession session,
    FoodSampleDay day,
    Key key,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final sample = session.sample;
    final form = _formFor(session, day);
    final dishes = sample?.dishes ?? session.dishes;
    final saving = _saving.contains(session.session);
    return SampleCardFrame(
      key: key,
      title: session.label,
      badge: sample == null
          ? FoodSamplesStatus.notRecorded
          : FoodSamplesStatus.sample(sample.status),
      subtitle: sample == null
          ? '${dishes.length} món theo thực đơn đã công bố'
          : FoodSamplesStatus.sampled(sample),
      children: [
        for (final dish in dishes)
          if (form[dish.id] case final controllers?) ...[
            const SizedBox(height: AppSpacing.space3),
            DishNoteFields(dish: dish, controllers: controllers),
          ],
        const SizedBox(height: AppSpacing.space3),
        Text(
          sample == null
              ? 'Giờ lấy mẫu: lúc bấm lưu.'
              : 'Giờ lấy mẫu giữ ${DateLabels.time24(sample.sampledAt)}.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        if (_saveErrors[session.session] case final error?) ...[
          const SizedBox(height: AppSpacing.space2),
          Semantics(
            liveRegion: true,
            child: Text(
              error,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.dangerText,
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.space3),
        AppButton(
          label: sample == null
              ? 'Lưu mẫu ${session.label.toLowerCase()}'
              : 'Lưu thay đổi',
          icon: AppIcons.check,
          expand: true,
          isLoading: saving,
          loadingLabel: 'Đang lưu…',
          onPressed: () => _save(session),
        ),
        if (sample != null) ...[
          const SizedBox(height: AppSpacing.space2),
          AppButton(
            label: 'Hủy sửa',
            variant: AppButtonVariant.text,
            expand: true,
            onPressed: saving ? null : () => _cancelEdit(session),
          ),
        ],
      ],
    );
  }
}

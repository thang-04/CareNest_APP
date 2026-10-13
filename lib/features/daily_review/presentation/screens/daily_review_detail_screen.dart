import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/daily_review/data/fake_daily_review_source.dart';
import 'package:carenest_app/features/daily_review/domain/daily_review.dart';

/// Đánh giá hằng ngày — một bé (mockup T04.1): tiêu chí có cấu trúc + ghi chú (OBS-01).
/// Không hiển thị giáo án (OBS-08); dòng hoạt động chỉ là ngữ cảnh.
class DailyReviewDetailScreen extends StatefulWidget {
  const DailyReviewDetailScreen({
    super.key,
    required this.childId,
    required this.onSaved,
    this.classId = FakeClassRosterSource.classId,
    this.source,
  });

  final String childId;
  final VoidCallback onSaved;
  final String classId;
  final DailyReviewSource? source;

  @override
  State<DailyReviewDetailScreen> createState() =>
      _DailyReviewDetailScreenState();
}

class _DailyReviewDetailScreenState extends State<DailyReviewDetailScreen> {
  late final DailyReviewSource _source =
      widget.source ?? FakeDailyReviewSource.shared;
  ReviewDay? _day;
  KidReview? _kid;
  Map<String, String> _answers = {};
  bool _flagged = false;
  final _note = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _source.loadDay(widget.classId).then((day) {
      if (!mounted) return;
      final kid = day.kids
          .where((item) => item.childId == widget.childId)
          .firstOrNull;
      setState(() {
        _day = day;
        _kid = kid;
        _answers = {...?kid?.answers};
        _flagged = kid?.flagged ?? false;
        _note.text = kid?.note ?? '';
      });
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final day = _day!;
    final kid = _kid!;
    final missing = day.criteria.any((c) => !_answers.containsKey(c.id));
    if (missing) {
      setState(() => _error = 'Chọn đủ các tiêu chí trước khi lưu.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await _source.save(
      KidReview(
        childId: kid.childId,
        fullName: kid.fullName,
        state: KidReviewState.done,
        presenceLine: kid.presenceLine,
        answers: _answers,
        note: _note.text.trim(),
        flagged: _flagged,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;
    final kid = _kid;
    final present = day?.kids
        .where((k) => k.state != KidReviewState.absent)
        .toList();
    final position = present == null || kid == null
        ? null
        : present.indexWhere((k) => k.childId == kid.childId) + 1;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá hằng ngày'),
        actions: [
          if (position != null && position > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.space4),
              child: Center(
                child: Text(
                  'Bé $position/${present!.length}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: day == null
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 4),
            )
          : kid == null || kid.state == KidReviewState.absent
          ? const Center(
              child: AppEmptyState(
                icon: AppIcons.searchOff,
                title: 'Không đánh giá được bé này',
                message: 'Bé không có trong lớp hoặc vắng hôm nay.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                AppBanner(
                  icon: AppIcons.review,
                  title: 'Hoạt động · ${DateLabels.dayMonth(day.date)}',
                  message: day.activityLine,
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  '${kid.fullName} · ${kid.presenceLine.toLowerCase()} · ${DateLabels.dayMonth(day.date)}',
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.space3),
                for (final criterion in day.criteria) ...[
                  AppCard(
                    dense: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(criterion.title, style: textTheme.titleSmall),
                        const SizedBox(height: AppSpacing.space2),
                        Wrap(
                          spacing: AppSpacing.space2,
                          runSpacing: AppSpacing.space1,
                          children: [
                            for (final option in criterion.options)
                              AppFilterChip(
                                label: option,
                                selected: _answers[criterion.id] == option,
                                onSelected: _saving
                                    ? null
                                    : () => setState(
                                        () => _answers = {
                                          ..._answers,
                                          criterion.id: option,
                                        },
                                      ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                ],
                AppTextField(
                  label: 'Ghi chú cho phụ huynh',
                  controller: _note,
                  multiline: true,
                  enabled: !_saving,
                ),
                const SizedBox(height: AppSpacing.space3),
                // Phiếu bé ngoan OBS-10 PROPOSED: chỉ gợi ý, GV/BGH quyết định
                AppFilterChip(
                  label: 'Gắn cờ: ${day.flagLabel}',
                  icon: AppIcons.flag,
                  selected: _flagged,
                  onSelected: _saving
                      ? null
                      : () => setState(() => _flagged = !_flagged),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.space3),
                  AppBanner(kind: AppBannerKind.danger, message: _error!),
                ],
              ],
            ),
      bottomNavigationBar: kid == null || kid.state == KidReviewState.absent
          ? null
          : AppBottomDock(
              children: [
                AppButton(
                  label: 'Lưu & về danh sách',
                  loadingLabel: 'Đang lưu',
                  isLoading: _saving,
                  expand: true,
                  onPressed: _save,
                ),
              ],
            ),
    );
  }
}

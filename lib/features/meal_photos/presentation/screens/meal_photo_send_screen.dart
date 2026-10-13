import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_photo_placeholder.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/features/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/meal_photos/data/fake_meal_photo_source.dart';
import 'package:carenest_app/features/meal_photos/domain/meal_photos.dart';

/// Xem lại & gửi phụ huynh — mockup T16. Ảnh vào mục Bữa ăn của từng bé (quyết định 8).
class MealPhotoSendScreen extends StatefulWidget {
  const MealPhotoSendScreen({
    super.key,
    required this.slot,
    required this.onSent,
    this.classId = FakeClassRosterSource.classId,
    this.source,
  });

  final MealSlot slot;
  final VoidCallback onSent;
  final String classId;
  final MealPhotoSource? source;

  @override
  State<MealPhotoSendScreen> createState() => _MealPhotoSendScreenState();
}

class _MealPhotoSendScreenState extends State<MealPhotoSendScreen> {
  late final MealPhotoSource _source =
      widget.source ?? FakeMealPhotoSource.shared;
  late final Future<MealPhotoDay> _day = _source.loadDay(widget.classId);
  final _message = TextEditingController();
  PhotoAudience _audience = PhotoAudience.wholeClass;
  bool _sending = false;

  static const _captions = [
    'Suất thường',
    'Cận cảnh món chính',
    'Suất thay thế',
  ];

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    await _source.send(widget.slot, _audience, _message.text.trim());
    if (!mounted) return;
    setState(() => _sending = false);
    widget.onSent();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final count = _source.capturedCount(widget.slot);
    return FutureBuilder<MealPhotoDay>(
      future: _day,
      builder: (context, snapshot) {
        final day = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gửi ảnh ${widget.slot.label.toLowerCase()}'),
                if (day != null)
                  Text(
                    '${day.className} · $count ảnh',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          body: day == null
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.pagePadding),
                  child: AppSkeletonList(rows: 3),
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.space2),
                          Expanded(
                            child: i < count
                                ? AppPhotoPlaceholder(caption: _captions[i])
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    AppCard(
                      dense: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Món trong ảnh (tự lấy từ thực đơn)',
                            style: textTheme.titleSmall,
                          ),
                          Text(
                            day.menus[widget.slot] ?? '',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    AppTextField(
                      label: 'Lời nhắn cho phụ huynh',
                      labelSuffix: '(không bắt buộc)',
                      hint: 'Ví dụ: các bé ăn hết suất',
                      controller: _message,
                      multiline: true,
                      enabled: !_sending,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text('Gửi tới', style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.space2),
                    RadioGroup<PhotoAudience>(
                      groupValue: _audience,
                      onChanged: (value) {
                        if (value != null && !_sending) {
                          setState(() => _audience = value);
                        }
                      },
                      child: Column(
                        children: [
                          _AudienceOption(
                            value: PhotoAudience.wholeClass,
                            selected: _audience == PhotoAudience.wholeClass,
                            icon: AppIcons.classGroup,
                            title: 'Phụ huynh cả lớp ${day.className}',
                            subtitle:
                                '${day.classSize} bé · vào mục Bữa ăn của từng bé',
                          ),
                          const SizedBox(height: AppSpacing.space2),
                          _AudienceOption(
                            value: PhotoAudience.alternativeOnly,
                            selected:
                                _audience == PhotoAudience.alternativeOnly,
                            icon: AppIcons.person,
                            title: 'Ảnh suất thay thế',
                            subtitle:
                                'Chỉ gửi phụ huynh bé ${day.alternativeChild}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    const AppBanner(
                      message:
                          'Ảnh chỉ chụp khay suất ăn, không chụp mặt bé. Ảnh lưu vào nhật ký bữa ăn của lớp.',
                    ),
                  ],
                ),
          bottomNavigationBar: day == null
              ? null
              : AppBottomDock(
                  children: [
                    AppButton(
                      label: 'Gửi phụ huynh',
                      loadingLabel: 'Đang gửi',
                      isLoading: _sending,
                      expand: true,
                      onPressed: count == 0 ? null : _send,
                    ),
                    if (day.sentNotes[MealSlot.breakfast] case final sent?
                        when widget.slot != MealSlot.breakfast)
                      Text(
                        'Bữa sáng: $sent',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppStatusColors.of(
                            context,
                          ).feedbackOf(AppFeedback.success).foreground,
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _AudienceOption extends StatelessWidget {
  const _AudienceOption({
    required this.value,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final PhotoAudience value;
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: RadioListTile<PhotoAudience>(
        value: value,
        controlAffinity: ListTileControlAffinity.trailing,
        secondary: Icon(icon, color: AppColors.primary),
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(subtitle),
      ),
    );
  }
}

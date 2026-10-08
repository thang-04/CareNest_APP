import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_confirmation_dialog.dart';
import 'package:carenest_app/core/widgets/app_empty_state.dart';
import 'package:carenest_app/core/widgets/app_error_state.dart';
import 'package:carenest_app/core/widgets/app_loading.dart';
import 'package:carenest_app/core/widgets/app_password_field.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/core/widgets/app_text_field.dart';
import 'package:carenest_app/core/widgets/brand/app_wordmark.dart';

/// Danh mục thử component (chỉ debug). Dữ liệu minh họa, không dữ liệu thật.
class UiKitScreen extends StatelessWidget {
  const UiKitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bộ UI')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: const [
          _Section(title: 'Thương hiệu', child: AppWordmark(fontSize: 32)),
          _Section(title: 'Màu', child: _ColorsDemo()),
          _Section(title: 'Chữ', child: _TypographyDemo()),
          _Section(title: 'Nút', child: _ButtonsDemo()),
          _Section(title: 'Ô nhập', child: _FieldsDemo()),
          _Section(title: 'Card', child: _CardsDemo()),
          _Section(title: 'Badge', child: _BadgesDemo()),
          _Section(title: 'Tải, rỗng, lỗi', child: _StatesDemo()),
          _Section(title: 'Xác nhận và thông báo', child: _FeedbackDemo()),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.space3),
          child,
        ],
      ),
    );
  }
}

class _ColorsDemo extends StatelessWidget {
  const _ColorsDemo();

  static const _swatches = [
    ('primary', AppColors.primary),
    ('primaryPressed', AppColors.primaryPressed),
    ('primaryContainer', AppColors.primaryContainer),
    ('focusRing', AppColors.focusRing),
    ('success', AppColors.success),
    ('warning', AppColors.warning),
    ('danger', AppColors.danger),
    ('purple', AppColors.purple),
    ('teal', AppColors.teal),
    ('textPrimary', AppColors.textPrimary),
    ('textSecondary', AppColors.textSecondary),
    ('textMuted', AppColors.textMuted),
    ('border', AppColors.border),
    ('borderStrong', AppColors.borderStrong),
    ('background', AppColors.background),
    ('surface', AppColors.surface),
    ('disabled', AppColors.disabled),
    ('skeleton', AppColors.skeleton),
  ];

  @override
  Widget build(BuildContext context) {
    final caption = Theme.of(context).textTheme.labelSmall;
    return Wrap(
      spacing: AppSpacing.space3,
      runSpacing: AppSpacing.space3,
      children: [
        for (final (name, color) in _swatches)
          SizedBox(
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    border: Border.all(color: AppColors.border),
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(name, style: caption),
              ],
            ),
          ),
      ],
    );
  }
}

class _TypographyDemo extends StatelessWidget {
  const _TypographyDemo();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final styles = [
      ('headlineSmall 24/700', t.headlineSmall),
      ('titleLarge 20/600', t.titleLarge),
      ('titleMedium 16/600', t.titleMedium),
      ('bodyLarge 16/400', t.bodyLarge),
      ('bodyMedium 14/400', t.bodyMedium),
      ('labelLarge 14/600', t.labelLarge),
      ('labelSmall 12/400', t.labelSmall),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, style) in styles)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space2),
            child: Text('$name · Bé đến lớp đúng giờ', style: style),
          ),
      ],
    );
  }
}

class _ButtonsDemo extends StatelessWidget {
  const _ButtonsDemo();

  @override
  Widget build(BuildContext context) {
    void noop() {}
    return Wrap(
      spacing: AppSpacing.space3,
      runSpacing: AppSpacing.space3,
      children: [
        AppButton(label: 'Lưu thay đổi', onPressed: noop),
        AppButton(
          label: 'Gửi báo cáo',
          icon: Icons.send_outlined,
          onPressed: noop,
        ),
        AppButton(
          label: 'Xem chi tiết',
          variant: AppButtonVariant.secondary,
          onPressed: noop,
        ),
        AppButton(
          label: 'Bỏ qua',
          variant: AppButtonVariant.text,
          onPressed: noop,
        ),
        AppButton(
          label: 'Hủy phiếu',
          variant: AppButtonVariant.danger,
          onPressed: noop,
        ),
        AppButton(label: 'Đang gửi', isLoading: true, onPressed: noop),
        const AppButton(label: 'Không khả dụng', onPressed: null),
        AppButton(label: 'Đăng nhập', expand: true, onPressed: noop),
      ],
    );
  }
}

class _FieldsDemo extends StatelessWidget {
  const _FieldsDemo();

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: AppSpacing.space4);
    return const Column(
      children: [
        AppTextField(
          label: 'Họ và tên',
          hint: 'Nguyễn Văn A',
          isRequired: true,
          textInputAction: TextInputAction.next,
        ),
        gap,
        AppTextField(
          label: 'Số điện thoại',
          keyboardType: TextInputType.phone,
          helperText: 'Dùng để nhận thông báo từ nhà trường',
        ),
        gap,
        AppTextField(
          label: 'Email',
          initialValue: 'phuhuynh@',
          errorText: 'Email chưa đúng định dạng, ví dụ: ten@gmail.com',
        ),
        gap,
        AppTextField(label: 'Mã lớp', initialValue: 'MG-01', enabled: false),
        gap,
        AppPasswordField(),
        gap,
        AppTextField(label: 'Ghi chú', maxLines: 3),
      ],
    );
  }
}

class _CardsDemo extends StatelessWidget {
  const _CardsDemo();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tiêu đề card', style: t.titleMedium),
              const SizedBox(height: AppSpacing.space1),
              Text(
                'Nội dung phụ của card hiển thị ở đây.',
                style: t.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        AppCard(
          onTap: () {},
          semanticLabel: 'Mở chi tiết',
          child: Row(
            children: [
              Expanded(child: Text('Card bấm được', style: t.titleMedium)),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ],
    );
  }
}

class _BadgesDemo extends StatelessWidget {
  const _BadgesDemo();

  // Nhãn minh họa tông hiển thị, không phải trạng thái nghiệp vụ
  static const _samples = [
    (AppStatusTone.neutral, 'Trung tính', null),
    (AppStatusTone.info, 'Đang thực hiện', Icons.schedule),
    (AppStatusTone.warning, 'Chờ giáo viên xác nhận', Icons.hourglass_empty),
    (AppStatusTone.purple, 'Nhóm riêng', null),
    (AppStatusTone.danger, 'Cần xử lý', Icons.error_outline),
    (AppStatusTone.success, 'Hoàn thành', Icons.check),
    (AppStatusTone.teal, 'Ghi chú', null),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: [
        for (final (tone, label, icon) in _samples)
          AppStatusBadge(label: label, tone: tone, icon: icon),
      ],
    );
  }
}

class _StatesDemo extends StatelessWidget {
  const _StatesDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppCard(child: AppLoading(message: 'Đang tải danh sách')),
        const SizedBox(height: AppSpacing.space3),
        const AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton(width: 160, height: 20),
              SizedBox(height: AppSpacing.space2),
              AppSkeleton(),
              SizedBox(height: AppSpacing.space2),
              AppSkeleton(width: 220),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        AppCard(
          child: AppEmptyState(
            title: 'Chưa có thông báo',
            message: 'Thông báo mới từ nhà trường sẽ hiển thị tại đây.',
            icon: Icons.notifications_none,
            actionLabel: 'Làm mới',
            onAction: () {},
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        AppCard(child: AppErrorState(onRetry: () {})),
      ],
    );
  }
}

class _FeedbackDemo extends StatelessWidget {
  const _FeedbackDemo();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space3,
      runSpacing: AppSpacing.space3,
      children: [
        AppButton(
          label: 'Mở dialog xác nhận',
          variant: AppButtonVariant.secondary,
          onPressed: () async {
            final confirmed = await AppConfirmationDialog.show(
              context,
              title: 'Hủy phiếu này?',
              message: 'Phiếu đã hủy không thể khôi phục.',
              confirmLabel: 'Hủy phiếu',
              isDestructive: true,
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(confirmed ? 'Đã chọn Hủy phiếu' : 'Đã quay lại'),
              ),
            );
          },
        ),
        AppButton(
          label: 'Mở bottom sheet',
          variant: AppButtonVariant.secondary,
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            builder: (sheetContext) => Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                0,
                AppSpacing.pagePadding,
                AppSpacing.space6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Bộ lọc',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  AppButton(
                    label: 'Áp dụng',
                    expand: true,
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

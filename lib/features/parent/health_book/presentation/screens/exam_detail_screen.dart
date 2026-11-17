import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/parent/health_book/data/fake_health_book_source.dart';
import 'package:carenest_app/features/parent/health_book/domain/health_book.dart';
import 'package:carenest_app/features/parent/health_book/presentation/health_labels.dart';
import 'package:carenest_app/features/parent/health_book/presentation/widgets/health_widgets.dart';
import 'package:carenest_app/features/parent/parent_home/domain/parent_today.dart';

/// Phụ huynh · Chi tiết đợt khám: đủ thông số phiếu Phụ lục II (user 17/11) — thông tin đợt,
/// kết luận và tư vấn, tiền sử, dấu hiệu sinh tồn, dinh dưỡng, phát triển, tiêm chủng, 24 mục khám
/// lâm sàng. Bỏ thông tin hành chính của phiếu. API phụ huynh hiện chỉ trả kết luận ⇒ dữ liệu giả.
class ExamDetailScreen extends StatefulWidget {
  const ExamDetailScreen({
    super.key,
    required this.child,
    required this.examId,
    this.source = const FakeHealthBookSource(),
  });

  final ChildSummary child;
  final String examId;
  final HealthBookSource source;

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen> {
  late Future<HealthBook> _book = widget.source.load(widget.child.id);

  void _retry() {
    setState(() {
      _book = widget.source.load(widget.child.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đợt khám')),
      body: FutureBuilder<HealthBook>(
        future: _book,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: AppErrorState(
                title: 'Chưa tải được phiếu khám',
                message: 'Kiểm tra kết nối mạng rồi thử lại.',
                onRetry: _retry,
              ),
            );
          }
          final book = snapshot.data;
          if (book == null) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 5),
            );
          }
          final exam = book.exams
              .where((item) => item.id == widget.examId)
              .firstOrNull;
          if (exam == null) {
            return const Center(
              child: AppEmptyState(
                icon: AppIcons.clipboardCheck,
                title: 'Không tìm thấy đợt khám',
                message: 'Đợt khám này không có trong sổ sức khỏe của bé.',
              ),
            );
          }
          return _ExamDetail(exam: exam, child: widget.child);
        },
      ),
    );
  }
}

class _ExamDetail extends StatelessWidget {
  const _ExamDetail({required this.exam, required this.child});

  final HealthExam exam;
  final ChildSummary child;

  static Widget _rows(List<ExamItem> items) => AppDividedColumn(
    children: [
      for (final item in items)
        HealthDetailRow(
          label: item.label,
          value: item.value,
          abnormal: item.abnormal,
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);
    final clinicalCount = exam.clinical.fold(
      0,
      (sum, section) => sum + section.items.length,
    );
    final findings = [
      for (final section in exam.clinical)
        for (final item in section.items)
          if (item.abnormal) item.label,
    ];
    const gap = SizedBox(height: AppSpacing.space3);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        AppCard(
          dense: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(exam.name, style: textTheme.titleMedium),
              Text('${child.fullName} · ${child.className}', style: muted),
              const SizedBox(height: AppSpacing.space1),
              AppDividedColumn(
                children: [
                  HealthDetailRow(
                    label: 'Ngày khám',
                    value:
                        '${DateLabels.date(exam.date)} · ${HealthLabels.age(exam.ageMonths)}',
                  ),
                  HealthDetailRow(label: 'Đơn vị khám', value: exam.examiner),
                  HealthDetailRow(label: 'Bác sĩ khám', value: exam.doctorName),
                ],
              ),
            ],
          ),
        ),
        gap,
        _ConclusionCard(exam: exam),
        gap,
        HealthDetailCard(title: 'Tiền sử', children: [_rows(exam.history)]),
        gap,
        HealthDetailCard(
          title: 'Dấu hiệu sinh tồn',
          children: [
            const SizedBox(height: AppSpacing.space2),
            HealthMetricRow(
              metrics: [
                for (final vital in exam.vitals)
                  HealthMetric(
                    vital.label,
                    vital.value,
                    status: vital.status,
                    abnormal: vital.abnormal,
                  ),
              ],
            ),
          ],
        ),
        gap,
        HealthDetailCard(
          title: 'Dinh dưỡng',
          children: [_rows(exam.nutrition)],
        ),
        gap,
        HealthDetailCard(
          title: 'Phát triển tinh thần – vận động',
          children: [_rows(exam.development)],
        ),
        gap,
        HealthDetailCard(
          title: 'Tiêm chủng',
          children: [_rows(exam.immunization)],
        ),
        gap,
        HealthDetailCard(
          title: 'Khám lâm sàng',
          children: [
            Text(
              findings.isEmpty
                  ? '$clinicalCount mục khám, không có mục cần chú ý.'
                  : '$clinicalCount mục khám · ${findings.length} mục cần chú ý: ${findings.join(', ')}.',
              style: muted,
            ),
            for (final section in exam.clinical) ...[
              const SizedBox(height: AppSpacing.space3),
              Text(
                section.title,
                style: textTheme.labelLarge?.copyWith(color: AppColors.primary),
              ),
              _rows(section.items),
            ],
          ],
        ),
        gap,
        Text(
          'Đã công bố ${DateLabels.date(exam.date)}. Phiếu khám do bác sĩ thực hiện tại trường, giáo viên nhập lại; chỉ để theo dõi, không thay thế chẩn đoán y tế.',
          style: muted,
        ),
      ],
    );
  }
}

/// Kết luận của bác sĩ, hướng xử lý và lời dặn; mức theo dõi ở góc phải.
class _ConclusionCard extends StatelessWidget {
  const _ConclusionCard({required this.exam});

  final HealthExam exam;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (label, tone) = HealthLabels.followUp(exam.followUp);
    final caption = textTheme.labelMedium?.copyWith(color: AppColors.textMuted);
    final conclusion = switch (exam.issueText) {
      final issue? => '${exam.conclusion}: $issue',
      null => exam.conclusion,
    };
    return AppCard(
      dense: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              Semantics(
                header: true,
                child: Text('Kết luận và tư vấn', style: textTheme.titleMedium),
              ),
              AppStatusBadge(label: label, tone: tone),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardGap),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Kết luận của bác sĩ', style: caption),
                  Text(conclusion, style: textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.space3),
                  Text('Hướng xử lý · ${exam.action}', style: caption),
                  if (exam.advice case final advice?)
                    Text(advice, style: textTheme.bodyLarge),
                ],
              ),
            ),
          ),
          AppDividedColumn(
            children: [
              if (exam.issueKind case final kind?)
                HealthDetailRow(label: 'Loại vấn đề', value: kind),
              HealthDetailRow(
                label: 'Tình trạng dinh dưỡng',
                value: exam.nutritionStatus,
              ),
              HealthDetailRow(label: 'Bác sĩ kết luận', value: exam.doctorName),
            ],
          ),
        ],
      ),
    );
  }
}

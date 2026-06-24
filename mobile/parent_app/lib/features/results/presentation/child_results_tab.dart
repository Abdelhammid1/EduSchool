import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../shared/models/year_result.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/results_repository.dart';

class ChildResultsTab extends ConsumerWidget {
  final int childId;
  const ChildResultsTab({super.key, required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(childResultsProvider(childId));
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(childResultsProvider(childId));
        await ref.read(childResultsProvider(childId).future);
      },
      child: AsyncValueWidget(
        value: results,
        onRetry: () => ref.invalidate(childResultsProvider(childId)),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.assignment_outlined,
              title: 'لم تُعتمد نتائج بعد',
              description:
                  'ستظهر هنا النتيجة فور اعتماد إدارة المؤسسة لها.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _ResultCard(result: list[i]),
          );
        },
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final YearResult result;
  const _ResultCard({required this.result});

  StatusKind get _statusKind {
    switch (result.status) {
      case 'pass':
        return StatusKind.success;
      case 'fail':
        return StatusKind.danger;
      case 'conditional':
        return StatusKind.warn;
      default:
        return StatusKind.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMMd('ar');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${result.year} — ${result.grade}',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                StatusChip(label: result.statusAr, kind: _statusKind),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'الفصل: ${result.section} • اعتُمد في ${df.format(result.approvedAt)}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const Divider(height: 22),
            Row(
              children: [
                const Text(
                  'المعدّل العام',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  result.average.toStringAsFixed(2),
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            if (result.subjectScores.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'تفصيل المواد',
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...result.subjectScores.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text(
                        e.key,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${e.value}',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

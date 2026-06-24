import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/students_repository.dart';

class SectionStudentsTab extends ConsumerWidget {
  final int sectionId;
  const SectionStudentsTab({super.key, required this.sectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(sectionStudentsProvider(sectionId));
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(sectionStudentsProvider(sectionId));
        await ref.read(sectionStudentsProvider(sectionId).future);
      },
      child: AsyncValueWidget(
        value: students,
        onRetry: () => ref.invalidate(sectionStudentsProvider(sectionId)),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.group_outlined,
              title: 'لا يوجد طلاب في هذا الفصل',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final s = list[i];
              return Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.sky.withValues(alpha: 0.5),
                    foregroundColor: AppColors.navy,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(
                    s.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    'الرقم الدائم: ${s.permanentCode}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

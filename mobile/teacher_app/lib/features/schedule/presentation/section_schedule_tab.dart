import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/weekly_schedule_grid.dart';
import '../data/schedule_repository.dart';

class SectionScheduleTab extends ConsumerWidget {
  final int sectionId;
  const SectionScheduleTab({super.key, required this.sectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(sectionScheduleProvider(sectionId));
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(sectionScheduleProvider(sectionId));
        await ref.read(sectionScheduleProvider(sectionId).future);
      },
      child: AsyncValueWidget(
        value: slots,
        onRetry: () => ref.invalidate(sectionScheduleProvider(sectionId)),
        data: (list) => WeeklyScheduleGrid(slots: list),
      ),
    );
  }
}

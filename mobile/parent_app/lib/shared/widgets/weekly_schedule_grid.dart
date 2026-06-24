import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../models/schedule_slot.dart';

/// شبكة جدول أسبوعية — تُستخدم في تطبيقي المعلم وولي الأمر.
/// تجمع الفترات يوميًا وتسرد البنود بترتيب وقت البداية.
class WeeklyScheduleGrid extends StatelessWidget {
  final List<ScheduleSlot> slots;
  final bool showTeacher;

  const WeeklyScheduleGrid({
    super.key,
    required this.slots,
    this.showTeacher = true,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'لا توجد حصص مجدولة',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }
    final byDay = <int, List<ScheduleSlot>>{};
    for (final s in slots) {
      byDay.putIfAbsent(s.dayId, () => []).add(s);
    }
    final dayIds = byDay.keys.toList()..sort();
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: dayIds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, idx) {
        final dayId = dayIds[idx];
        final daySlots = byDay[dayId]!
          ..sort((a, b) => a.periodId.compareTo(b.periodId));
        return _DayCard(slots: daySlots, showTeacher: showTeacher);
      },
    );
  }
}

class _DayCard extends StatelessWidget {
  final List<ScheduleSlot> slots;
  final bool showTeacher;
  const _DayCard({required this.slots, required this.showTeacher});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  slots.first.dayName,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            ...slots.map((s) => _SlotRow(slot: s, showTeacher: showTeacher)),
          ],
        ),
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final ScheduleSlot slot;
  final bool showTeacher;
  const _SlotRow({required this.slot, required this.showTeacher});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.sky.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${slot.startTime} - ${slot.endTime}',
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.subjectName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    slot.periodName,
                    if (slot.sectionName != null) slot.sectionName!,
                    if (showTeacher && slot.teacherName != null) slot.teacherName!,
                  ].join(' • '),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

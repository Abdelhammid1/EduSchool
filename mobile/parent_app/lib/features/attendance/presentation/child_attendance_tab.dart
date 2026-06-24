import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../shared/models/attendance.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/attendance_repository.dart';

class ChildAttendanceTab extends ConsumerWidget {
  final int childId;
  const ChildAttendanceTab({super.key, required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final att = ref.watch(childAttendanceProvider(childId));
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(childAttendanceProvider(childId));
        await ref.read(childAttendanceProvider(childId).future);
      },
      child: AsyncValueWidget<ChildAttendance>(
        value: att,
        onRetry: () => ref.invalidate(childAttendanceProvider(childId)),
        data: (data) {
          return ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _SummaryCard(s: data.summary),
              const SizedBox(height: 16),
              if (data.records.isEmpty)
                const EmptyState(
                  icon: Icons.event_available,
                  title: 'لا توجد سجلات حضور بعد',
                )
              else
                ...data.records.map((r) => _AttendanceTile(record: r)),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final AttendanceSummary s;
  const _SummaryCard({required this.s});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'نسبة الحضور',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${s.rate.toStringAsFixed(1)}٪',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.sky.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_available,
                    color: AppColors.navy,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _stat('حضور', s.present, AppColors.success),
                ),
                Expanded(child: _stat('غياب', s.absent, AppColors.danger)),
                Expanded(child: _stat('تأخّر', s.late, AppColors.gold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final AttendanceRecord record;
  const _AttendanceTile({required this.record});

  StatusKind get _kind {
    switch (record.status) {
      case AttendanceStatus.present:
        return StatusKind.success;
      case AttendanceStatus.absent:
        return StatusKind.danger;
      case AttendanceStatus.late:
        return StatusKind.warn;
      case AttendanceStatus.unknown:
        return StatusKind.neutral;
    }
  }

  IconData get _icon {
    switch (record.status) {
      case AttendanceStatus.present:
        return Icons.check_circle_outline;
      case AttendanceStatus.absent:
        return Icons.cancel_outlined;
      case AttendanceStatus.late:
        return Icons.schedule;
      case AttendanceStatus.unknown:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMMd('ar');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        child: ListTile(
          leading: Icon(_icon, color: _color()),
          title: Text(
            df.format(record.date),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: record.notes == null
              ? null
              : Text(record.notes!,
                  style: const TextStyle(color: AppColors.muted)),
          trailing: StatusChip(label: record.status.labelAr, kind: _kind),
        ),
      ),
    );
  }

  Color _color() {
    switch (record.status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.absent:
        return AppColors.danger;
      case AttendanceStatus.late:
        return AppColors.gold;
      case AttendanceStatus.unknown:
        return AppColors.muted;
    }
  }
}

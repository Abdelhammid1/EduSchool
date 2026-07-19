import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../shared/models/attendance.dart';
import '../../../../shared/models/student_brief.dart';

class AttendanceRow extends StatelessWidget {
  final int index;
  final StudentBrief student;
  final AttendanceMark mark;
  final ValueChanged<AttendanceStatus> onStatus;
  final VoidCallback onNotes;

  const AttendanceRow({
    super.key,
    required this.index,
    required this.student,
    required this.mark,
    required this.onStatus,
    required this.onNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('att-row-${student.enrollmentId}'),
      background: _swipeBg(AppColors.success, Alignment.centerRight, Icons.check),
      secondaryBackground:
          _swipeBg(AppColors.danger, Alignment.centerLeft, Icons.close),
      confirmDismiss: (dir) async {
        onStatus(dir == DismissDirection.startToEnd
            ? AttendanceStatus.present
            : AttendanceStatus.absent);
        return false; // don't actually dismiss the row
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: const BorderSide(color: AppColors.border),
            right: BorderSide(
              color: mark.dirty ? AppColors.gold : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.sky.withValues(alpha: 0.5),
                  foregroundColor: AppColors.navy,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        student.permanentCode,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    (mark.notes ?? '').isEmpty
                        ? Icons.note_add_outlined
                        : Icons.note_alt,
                    color: (mark.notes ?? '').isEmpty
                        ? AppColors.muted
                        : AppColors.gold,
                  ),
                  onPressed: onNotes,
                  tooltip: 'ملاحظات',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _pill(AttendanceStatus.present, AppColors.success)),
                const SizedBox(width: 6),
                Expanded(child: _pill(AttendanceStatus.absent, AppColors.danger)),
                const SizedBox(width: 6),
                Expanded(child: _pill(AttendanceStatus.late, AppColors.gold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(AttendanceStatus s, Color c) {
    final selected = mark.status == s;
    return InkWell(
      onTap: () => onStatus(s),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c : c.withValues(alpha: 0.08),
          border: Border.all(color: c, width: selected ? 0 : 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          s.labelAr,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : c,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _swipeBg(Color color, Alignment align, IconData icon) => Container(
        color: color.withValues(alpha: 0.9),
        alignment: align,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(icon, color: Colors.white, size: 28),
      );
}

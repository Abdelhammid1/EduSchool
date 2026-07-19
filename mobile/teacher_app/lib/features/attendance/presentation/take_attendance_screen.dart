import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/models/attendance.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../students/data/students_repository.dart';
import '../application/attendance_controller.dart';
import 'widgets/attendance_row.dart';

class TakeAttendanceScreen extends ConsumerStatefulWidget {
  final int sectionId;
  final DateTime? initialDate;

  const TakeAttendanceScreen({
    super.key,
    required this.sectionId,
    this.initialDate,
  });

  @override
  ConsumerState<TakeAttendanceScreen> createState() =>
      _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends ConsumerState<TakeAttendanceScreen> {
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
    // strip time
    _date = DateTime(_date.year, _date.month, _date.day);
  }

  AttendanceKey get _key => AttendanceKey(widget.sectionId, _date);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _openNotesSheet(int enrollmentId, String initial) async {
    final controller = TextEditingController(text: initial);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16, right: 16, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ملاحظات', style: TextStyle(
              fontWeight: FontWeight.w800, color: AppColors.navy, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'أضف ملاحظة (اختياري)...',
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, controller.text),
                child: const Text('حفظ'),
              )),
              const SizedBox(width: 8),
              Expanded(child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              )),
            ]),
          ],
        ),
      ),
    );
    if (result != null) {
      ref.read(attendanceControllerProvider(_key).notifier)
          .setNotes(enrollmentId, result.trim().isEmpty ? null : result.trim());
    }
  }

  Future<void> _submit(AttendanceFormState s) async {
    if (s.unmarked > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('طلاب غير مُعلَّمين'),
          content: Text('يوجد ${s.unmarked} طالب لم تحدد حضورهم. حفظ رغم ذلك؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
          ],
        ),
      );
      if (ok != true) return;
    }
    try {
      final result = await ref
          .read(attendanceControllerProvider(_key).notifier)
          .submit(widget.sectionId, _date);
      if (!mounted) return;
      final absentN = result['absent_notifications'] ?? 0;
      final msg = 'تم حفظ الحضور'
          '${absentN > 0 ? ' — أُرسل $absentN إشعار غياب لأولياء الأمور' : ''}.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formAsync = ref.watch(attendanceControllerProvider(_key));
    final studentsAsync = ref.watch(sectionStudentsProvider(widget.sectionId));
    final df = DateFormat.yMMMMEEEEd('ar');

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الحضور'),
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, color: Colors.white, size: 16),
            label: Text(df.format(_date),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: AsyncValueWidget<AttendanceFormState>(
        value: formAsync,
        onRetry: () => ref.invalidate(attendanceControllerProvider(_key)),
        data: (state) {
          return studentsAsync.when(
            data: (students) {
              if (students.isEmpty) {
                return const EmptyState(
                  icon: Icons.group_outlined,
                  title: 'لا يوجد طلاب في هذا الفصل',
                );
              }
              return Column(
                children: [
                  _stickyTop(state),
                  Expanded(
                    child: ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (_, i) {
                        final s = students[i];
                        final mark = state.marks[s.enrollmentId] ??
                            const AttendanceMark();
                        return AttendanceRow(
                          index: i,
                          student: s,
                          mark: mark,
                          onStatus: (st) => ref
                              .read(attendanceControllerProvider(_key).notifier)
                              .setStatus(s.enrollmentId, st),
                          onNotes: () =>
                              _openNotesSheet(s.enrollmentId, mark.notes ?? ''),
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ElevatedButton(
                        onPressed: state.saving ? null : () => _submit(state),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: state.saving
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('حفظ الحضور',
                                style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.navy)),
            error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text('$e'))),
          );
        },
      ),
    );
  }

  Widget _stickyTop(AttendanceFormState s) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _chip('${s.count(AttendanceStatus.present)} حاضر', AppColors.success),
                _chip('${s.count(AttendanceStatus.absent)} غائب', AppColors.danger),
                _chip('${s.count(AttendanceStatus.late)} متأخّر', AppColors.gold),
                if (s.unmarked > 0)
                  _chip('${s.unmarked} لم يُعلَّم', AppColors.muted),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () =>
                ref.read(attendanceControllerProvider(_key).notifier).markAllPresent(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('تعليم الكل حاضر', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
        ),
      );
}

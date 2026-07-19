import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../students/data/students_repository.dart';
import '../application/grades_form_controller.dart';

class GradeEntryScreen extends ConsumerStatefulWidget {
  final int sectionId;
  final int termId;
  final int subjectId;
  final int componentId;
  final String componentName;
  final double maxScore;

  const GradeEntryScreen({
    super.key,
    required this.sectionId,
    required this.termId,
    required this.subjectId,
    required this.componentId,
    required this.componentName,
    required this.maxScore,
  });

  @override
  ConsumerState<GradeEntryScreen> createState() => _GradeEntryScreenState();
}

class _GradeEntryScreenState extends ConsumerState<GradeEntryScreen> {
  late GradesFormKey _key;
  final _controllers = <int, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _key = GradesFormKey(
      sectionId: widget.sectionId,
      subjectId: widget.subjectId,
      termId: widget.termId,
      componentId: widget.componentId,
    );
    // Push maxScore into controller after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gradesFormControllerProvider(_key).notifier)
          .setMaxScore(widget.maxScore);
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctl(int enrollmentId, String initial) {
    return _controllers.putIfAbsent(enrollmentId, () {
      final c = TextEditingController(text: initial);
      c.addListener(() {
        ref.read(gradesFormControllerProvider(_key).notifier)
            .setInput(enrollmentId, c.text);
      });
      return c;
    });
  }

  Future<void> _submit(GradesFormState s) async {
    // Sync controller values into state
    for (final e in _controllers.entries) {
      ref.read(gradesFormControllerProvider(_key).notifier)
          .setInput(e.key, e.value.text);
    }
    try {
      final result = await ref
          .read(gradesFormControllerProvider(_key).notifier)
          .submit(_key);
      if (!mounted) return;
      final saved = result['saved'] ?? 0;
      final rejected = result['rejected'] ?? 0;
      final msg = rejected > 0
          ? 'تم حفظ $saved درجة • رُفض $rejected'
          : 'تم حفظ $saved درجة';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: rejected > 0 ? AppColors.gold : AppColors.success,
        ),
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
    final formAsync = ref.watch(gradesFormControllerProvider(_key));
    final studentsAsync = ref.watch(sectionStudentsProvider(widget.sectionId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.componentName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Center(
              child: Text('/${_fmt(widget.maxScore)}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
      body: AsyncValueWidget<GradesFormState>(
        value: formAsync,
        onRetry: () => ref.invalidate(gradesFormControllerProvider(_key)),
        data: (state) {
          return studentsAsync.when(
            data: (students) {
              return Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'تمّ إدخال ${state.entered} / ${state.totalStudents} طالب',
                          style: const TextStyle(
                              color: AppColors.navy, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: students.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final s = students[i];
                        final raw = state.inputs[s.enrollmentId] ?? '';
                        final ctl = _ctl(s.enrollmentId, raw);
                        final invalid = state.isInvalid(s.enrollmentId);
                        final dirty = state.isDirty(s.enrollmentId);
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: dirty ? AppColors.gold : Colors.transparent,
                                width: 4,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    AppColors.sky.withValues(alpha: 0.5),
                                foregroundColor: AppColors.navy,
                                child: Text('${i + 1}', style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.fullName, style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink)),
                                    Text(s.permanentCode, style: const TextStyle(
                                        color: AppColors.muted, fontSize: 11)),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: ctl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.]')),
                                  ],
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    hintText: '/${_fmt(widget.maxScore)}',
                                    errorText: invalid ? 'خطأ' : null,
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: invalid
                                            ? AppColors.danger
                                            : AppColors.border,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                            : const Text('حفظ الدرجات',
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

  String _fmt(double v) =>
      v == v.toInt().toDouble() ? v.toInt().toString() : v.toString();
}

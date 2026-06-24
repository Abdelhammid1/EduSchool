import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/env.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/models/section_brief.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/application/auth_controller.dart';
import '../../schedule/data/schedule_repository.dart';
import '../data/sections_repository.dart';

class SectionsScreen extends ConsumerWidget {
  const SectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState is Authenticated ? authState.user : null;
    final sections = ref.watch(sectionsProvider);
    final schedule = ref.watch(teacherScheduleProvider);

    final todayDayId = _todayDayId();
    final todaysSectionIds = <int>{};
    schedule.whenData((slots) {
      for (final s in slots) {
        if (s.dayId == todayDayId && s.sectionId != null) {
          todaysSectionIds.add(s.sectionId!);
        }
      }
    });

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(sectionsProvider);
        ref.invalidate(teacherScheduleProvider);
        await ref.read(sectionsProvider.future);
      },
      child: AsyncValueWidget<List<SectionBrief>>(
        value: sections,
        onRetry: () => ref.invalidate(sectionsProvider),
        data: (list) {
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _GreetingCard(
                  fullName: user?.fullName ?? '',
                  schoolName: user?.schoolId != null
                      ? Env.institutionNameAr
                      : '',
                ),
              ),
              if (list.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.school_outlined,
                    title: 'لم تُسند إليك فصول بعد',
                    description: 'تواصل مع إدارة المؤسسة لإسناد فصل دراسي.',
                  ),
                )
              else ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
                    child: Text(
                      'فصولك',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _SectionCard(
                      section: list[i],
                      hasToday: todaysSectionIds.contains(list[i].id),
                      onTap: () => context.push('/sections/${list[i].id}'),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// تحويل اليوم الحالي إلى day_id (1=الأحد ... 7=السبت في تقويم بعض المؤسسات).
  /// نتحقّق بصرف النظر عن ترقيم المؤسسة عبر مطابقة المُسمّى لاحقًا، ولكن
  /// نُرسل تخمينًا ابتدائيًا مبنيًا على ترتيب الأسبوع الإسلامي (الأحد=1).
  int _todayDayId() {
    final wd = DateTime.now().weekday; // 1=Mon ... 7=Sun
    // Map ISO weekday → school day (Sun=1, Mon=2, ..., Sat=7)
    const map = {
      DateTime.sunday: 1,
      DateTime.monday: 2,
      DateTime.tuesday: 3,
      DateTime.wednesday: 4,
      DateTime.thursday: 5,
      DateTime.friday: 6,
      DateTime.saturday: 7,
    };
    return map[wd] ?? 1;
  }
}

class _GreetingCard extends StatelessWidget {
  final String fullName;
  final String schoolName;
  const _GreetingCard({required this.fullName, required this.schoolName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.navy, AppColors.navySoft],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مرحبًا، $fullName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            schoolName,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final SectionBrief section;
  final bool hasToday;
  final VoidCallback onTap;
  const _SectionCard({
    required this.section,
    required this.hasToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: hasToday ? AppColors.gold : AppColors.border,
            width: hasToday ? 1.6 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (hasToday)
                Container(
                  width: 4,
                  height: 36,
                  margin: const EdgeInsetsDirectional.only(end: 10),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            section.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (hasToday)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'اليوم',
                              style: TextStyle(
                                color: AppColors.goldDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (section.subjects.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: section.subjects
                            .map((s) => Chip(label: Text(s.name)))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

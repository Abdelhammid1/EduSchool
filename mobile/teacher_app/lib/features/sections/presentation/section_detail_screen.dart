import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../materials/presentation/section_materials_tab.dart';
import '../../schedule/presentation/section_schedule_tab.dart';
import '../../students/presentation/section_students_tab.dart';
import '../data/sections_repository.dart';

class SectionDetailScreen extends ConsumerWidget {
  final int sectionId;
  const SectionDetailScreen({super.key, required this.sectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(sectionsProvider);
    final sectionName = sections.maybeWhen(
      data: (list) => list
          .firstWhere(
            (s) => s.id == sectionId,
            orElse: () => list.isNotEmpty
                ? list.first
                : throw Exception('not found'),
          )
          .name,
      orElse: () => 'الفصل',
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(sectionName),
          bottom: const TabBar(
            indicatorColor: AppColors.gold,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: 'الجدول'),
              Tab(text: 'الطلاب'),
              Tab(text: 'المواد'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SectionScheduleTab(sectionId: sectionId),
            SectionStudentsTab(sectionId: sectionId),
            SectionMaterialsTab(sectionId: sectionId),
          ],
        ),
      ),
    );
  }
}

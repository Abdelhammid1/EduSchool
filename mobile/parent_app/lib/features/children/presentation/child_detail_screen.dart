import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../attendance/presentation/child_attendance_tab.dart';
import '../../invoices/presentation/child_invoices_tab.dart';
import '../../materials/presentation/child_materials_tab.dart';
import '../../notifications/presentation/child_notifications_tab.dart';
import '../../results/presentation/child_results_tab.dart';
import '../../schedule/presentation/child_schedule_tab.dart';
import '../data/children_repository.dart';

/// Tab index enum kept in sync with the tabs list below.
/// Sprint 10 audit fix — FCM deep-links target /children/:id/<tabName>
/// so the router maps a sub-path to the initialIndex here.
const _tabByName = <String, int>{
  'schedule': 0,
  'attendance': 1,
  'results': 2,
  'invoices': 3,
  'materials': 4,
  'notifications': 5,
};

int tabIndexFromName(String? name) => _tabByName[name] ?? 0;

class ChildDetailScreen extends ConsumerWidget {
  final int childId;
  final int initialTab;
  const ChildDetailScreen({
    super.key,
    required this.childId,
    this.initialTab = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(childrenProvider);
    final name = children.maybeWhen(
      data: (list) {
        final match = list.where((c) => c.id == childId).toList();
        return match.isNotEmpty ? match.first.fullName : 'الطالب';
      },
      orElse: () => 'الطالب',
    );

    return DefaultTabController(
      length: 6,
      initialIndex: initialTab.clamp(0, 5),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => context.go('/'),
            tooltip: 'تبديل الابن',
          ),
          title: Text(name),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: AppColors.gold,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'الجدول'),
              Tab(text: 'الحضور'),
              Tab(text: 'النتائج'),
              Tab(text: 'الفواتير'),
              Tab(text: 'المواد'),
              Tab(text: 'الإشعارات'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'الحساب',
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.push('/profile'),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            ChildScheduleTab(childId: childId),
            ChildAttendanceTab(childId: childId),
            ChildResultsTab(childId: childId),
            ChildInvoicesTab(childId: childId),
            ChildMaterialsTab(childId: childId),
            const ChildNotificationsTab(),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../schedule/presentation/teacher_schedule_screen.dart';
import '../../sections/presentation/sections_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _idx = 0;

  static const _titles = ['فصولي', 'الجدول الأسبوعي', 'الإشعارات', 'الحساب'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_idx])),
      body: IndexedStack(
        index: _idx,
        children: const [
          SectionsScreen(),
          TeacherScheduleScreen(),
          NotificationsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.sky.withValues(alpha: 0.5),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.class_outlined),
            selectedIcon: Icon(Icons.class_, color: AppColors.navy),
            label: 'الفصول',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_view_week_outlined),
            selectedIcon:
                Icon(Icons.calendar_view_week, color: AppColors.navy),
            label: 'الجدول',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications, color: AppColors.navy),
            label: 'الإشعارات',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.navy),
            label: 'الحساب',
          ),
        ],
      ),
    );
  }
}

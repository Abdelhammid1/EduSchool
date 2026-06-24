import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/notifications_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(teacherNotificationsProvider);
    return AsyncValueWidget(
      value: notifs,
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.notifications_none_outlined,
            title: 'لا توجد إشعارات',
            description: 'سيظهر هنا أي تنبيه يخصّك من إدارة المؤسسة.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final n = list[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(n.displayMessage),
                subtitle: Text(n.kind),
              ),
            );
          },
        );
      },
    );
  }
}

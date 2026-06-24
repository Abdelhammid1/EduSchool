import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/notifications_repository.dart';

/// نفس الإشعارات يستخدمها جميع الأبناء (لا تربيط حالي بالطفل المحدّد).
class ChildNotificationsTab extends ConsumerWidget {
  const ChildNotificationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(parentNotificationsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(parentNotificationsProvider);
        await ref.read(parentNotificationsProvider.future);
      },
      child: AsyncValueWidget(
        value: notifs,
        onRetry: () => ref.invalidate(parentNotificationsProvider),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'لا توجد إشعارات بعد',
            );
          }
          final df = DateFormat('yyyy/MM/dd HH:mm', 'ar');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final n = list[i];
              return Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.navy,
                  ),
                  title: Text(
                    n.displayMessage,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    df.format(n.createdAt),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

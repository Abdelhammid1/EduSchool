import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/env.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/models/child_brief.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/application/auth_controller.dart';
import '../data/children_repository.dart';

const _lastChildKey = 'last_picked_child_id';

class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key});

  Future<void> _rememberPick(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastChildKey, id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth is Authenticated ? auth.user : null;
    final children = ref.watch(childrenProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('أبناؤك')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(childrenProvider);
          await ref.read(childrenProvider.future);
        },
        child: AsyncValueWidget<List<ChildBrief>>(
          value: children,
          onRetry: () => ref.invalidate(childrenProvider),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.family_restroom,
                title: 'لا يوجد أبناء مسجّلون',
                description: 'تواصل مع إدارة المؤسسة للمساعدة.',
              );
            }
            // Auto-navigate when only one child.
            if (list.length == 1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _rememberPick(list.first.id);
                if (context.mounted) {
                  context.go('/children/${list.first.id}');
                }
              });
              return const Center(
                child: CircularProgressIndicator(color: AppColors.navy),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _greeting(user?.fullName ?? ''),
                const SizedBox(height: 16),
                ...list.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ChildCard(
                      child: c,
                      onTap: () async {
                        await _rememberPick(c.id);
                        if (context.mounted) {
                          context.push('/children/${c.id}');
                        }
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _greeting(String name) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.navySoft],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أهلاً، $name',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Env.institutionNameAr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final ChildBrief child;
  final VoidCallback onTap;
  const _ChildCard({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.sky.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 2.4),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.navy,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.fullName,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (child.currentSection != null) child.currentSection!,
                        if (child.currentYear != null) child.currentYear!,
                      ].join(' • '),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'الرقم: ${child.permanentCode}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

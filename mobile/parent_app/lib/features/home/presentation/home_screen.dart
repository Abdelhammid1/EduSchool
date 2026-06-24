import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/manasety_logo.dart';
import '../../auth/application/auth_controller.dart';

/// شاشة Phase 0 الفارغة — يستبدلها Phase 1 بقائمة الفصول.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final user = state is Authenticated ? state.user : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('بوابة ولي الأمر'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const ManasetyLogo(
                        variant: ManasetyLogoVariant.horizontal,
                        size: 80,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'مرحبًا، ${user?.fullName ?? 'ولي الأمر الكريم'}',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        Env.institutionNameAr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.sky.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.sky.withValues(alpha: 0.6),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.construction, color: AppColors.navy),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'الواجهة قيد التطوير — ستظهر هنا أبناؤك ومتابعة حضورهم ودرجاتهم.',
                        style: TextStyle(color: AppColors.navy),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

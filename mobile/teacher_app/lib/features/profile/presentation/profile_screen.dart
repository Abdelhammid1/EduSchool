import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/env.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/manasety_logo.dart';
import '../../auth/application/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth is Authenticated ? auth.user : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: ManasetyLogo(
              variant: ManasetyLogoVariant.emblem,
              size: 100,
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              Env.institutionNameAr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                _row(Icons.person_outline, 'الاسم الكامل',
                    user?.fullName ?? '—'),
                const Divider(height: 1),
                _row(Icons.badge_outlined, 'اسم المستخدم',
                    user?.username ?? '—'),
                const Divider(height: 1),
                _row(Icons.work_outline, 'الدور', user?.roleAr ?? '—'),
                const Divider(height: 1),
                _row(Icons.school_outlined, 'المؤسسة',
                    Env.institutionNameAr),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file, color: AppColors.navy),
                  title: const Text('رفع مادة جديدة',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('PDF أو صورة أو رابط لطلاب فصلك',
                      style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_left, color: AppColors.muted),
                  onTap: () => context.push('/materials/upload'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: AppColors.navy),
                  title: const Text('تغيير كلمة المرور',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  trailing: const Icon(Icons.chevron_left, color: AppColors.muted),
                  onTap: () => context.push('/profile/change-password'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل الخروج'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'منصتي للمعلم • الإصدار 0.2.0',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.navy, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

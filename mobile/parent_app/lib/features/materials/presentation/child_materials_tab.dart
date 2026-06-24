import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/material_card.dart';
import '../data/materials_repository.dart';

class ChildMaterialsTab extends ConsumerWidget {
  final int childId;
  const ChildMaterialsTab({super.key, required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materials = ref.watch(childMaterialsProvider(childId));
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(childMaterialsProvider(childId));
        await ref.read(childMaterialsProvider(childId).future);
      },
      child: AsyncValueWidget(
        value: materials,
        onRetry: () => ref.invalidate(childMaterialsProvider(childId)),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.collections_bookmark_outlined,
              title: 'لا توجد مواد منشورة',
              description: 'سيظهر هنا أي ملف أو رابط ينشره معلّمو الفصل.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => MaterialCard(item: list[i]),
          );
        },
      ),
    );
  }
}

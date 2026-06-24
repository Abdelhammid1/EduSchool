import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/env.dart';
import '../../core/theme/colors.dart';
import '../models/material_item.dart';
import 'status_chip.dart';

class MaterialCard extends StatelessWidget {
  final MaterialItem item;
  const MaterialCard({super.key, required this.item});

  IconData _icon() {
    switch (item.kind) {
      case MaterialKind.file:
        return Icons.picture_as_pdf_outlined;
      case MaterialKind.video:
        return Icons.play_circle_outline;
      case MaterialKind.link:
        return Icons.link;
      case MaterialKind.unknown:
        return Icons.insert_drive_file_outlined;
    }
  }

  Future<void> _open() async {
    final url = item.externalUrl?.isNotEmpty == true
        ? item.externalUrl!
        : (item.filePath != null
            ? '${Env.apiBase.replaceAll('/api', '')}${item.filePath}'
            : null);
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.sky.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_icon(), color: AppColors.navy, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.subjectName} • ${item.sectionName}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  if (item.description != null &&
                      item.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.description!,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (!item.hasOpenable)
                        const StatusChip(
                          label: 'ملف غير متاح حاليًا',
                          kind: StatusKind.neutral,
                        )
                      else
                        TextButton.icon(
                          onPressed: _open,
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('افتح'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.gold,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

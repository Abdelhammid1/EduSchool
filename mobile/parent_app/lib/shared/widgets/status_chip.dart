import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

enum StatusKind { success, warn, danger, neutral, info }

class StatusChip extends StatelessWidget {
  final String label;
  final StatusKind kind;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;

  const StatusChip({
    super.key,
    required this.label,
    this.kind = StatusKind.neutral,
    this.icon,
    this.padding,
    this.fontSize,
  });

  ({Color bg, Color fg, Color border}) _palette() {
    switch (kind) {
      case StatusKind.success:
        return (
          bg: AppColors.success.withValues(alpha: 0.12),
          fg: AppColors.success,
          border: AppColors.success.withValues(alpha: 0.4),
        );
      case StatusKind.warn:
        return (
          bg: AppColors.gold.withValues(alpha: 0.18),
          fg: AppColors.goldDark,
          border: AppColors.gold.withValues(alpha: 0.5),
        );
      case StatusKind.danger:
        return (
          bg: AppColors.danger.withValues(alpha: 0.12),
          fg: AppColors.danger,
          border: AppColors.danger.withValues(alpha: 0.4),
        );
      case StatusKind.info:
        return (
          bg: AppColors.sky.withValues(alpha: 0.4),
          fg: AppColors.navy,
          border: AppColors.sky.withValues(alpha: 0.8),
        );
      case StatusKind.neutral:
        return (
          bg: AppColors.border,
          fg: AppColors.muted,
          border: AppColors.border,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette();
    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: p.fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: p.fg,
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

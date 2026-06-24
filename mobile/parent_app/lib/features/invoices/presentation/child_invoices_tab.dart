import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../shared/models/invoice_summary.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/invoices_repository.dart';

class ChildInvoicesTab extends ConsumerWidget {
  final int childId;
  const ChildInvoicesTab({super.key, required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(childInvoicesProvider(childId));
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(childInvoicesProvider(childId));
        await ref.read(childInvoicesProvider(childId).future);
      },
      child: AsyncValueWidget(
        value: invoices,
        onRetry: () => ref.invalidate(childInvoicesProvider(childId)),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'لا توجد فواتير',
            );
          }
          // Sort by status priority then date
          const order = {'overdue': 0, 'partial': 1, 'pending': 2, 'paid': 3};
          final sorted = [...list]..sort((a, b) {
              final pa = order[a.status] ?? 99;
              final pb = order[b.status] ?? 99;
              if (pa != pb) return pa.compareTo(pb);
              return b.issueDate.compareTo(a.issueDate);
            });
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _InvoiceCard(invoice: sorted[i]),
          );
        },
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceSummary invoice;
  const _InvoiceCard({required this.invoice});

  StatusKind get _kind {
    switch (invoice.status) {
      case 'paid':
        return StatusKind.success;
      case 'overdue':
        return StatusKind.danger;
      case 'partial':
        return StatusKind.warn;
      case 'pending':
        return StatusKind.info;
      default:
        return StatusKind.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMMd('ar');
    final money = NumberFormat.currency(
      locale: 'ar',
      symbol: 'ج.س',
      decimalDigits: 0,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    invoice.number,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                StatusChip(label: invoice.statusAr, kind: _kind),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'إصدار: ${df.format(invoice.issueDate)} • استحقاق: ${df.format(invoice.dueDate)}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const Divider(height: 22),
            Row(
              children: [
                Expanded(
                  child: _stat('الإجمالي', money.format(invoice.totalAmount),
                      AppColors.ink),
                ),
                Expanded(
                  child: _stat('المدفوع', money.format(invoice.paidAmount),
                      AppColors.success),
                ),
                Expanded(
                  child: _stat('المتبقّي', money.format(invoice.remaining),
                      invoice.remaining > 0
                          ? AppColors.danger
                          : AppColors.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

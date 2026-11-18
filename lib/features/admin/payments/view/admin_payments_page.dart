import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:assessment_project_fb_international_frontend/core/utils/formatters.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/payments/controller/admin_payment_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/payments/controller/payment_filter_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/view/admin_widgets.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/model/payment_models.dart';

class AdminPaymentsPage extends ConsumerWidget {
  const AdminPaymentsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(paymentFilterProvider);
    final provider = adminPaymentsProvider((
      owner: ref.watch(adminOwnerProvider),
      status: filter.query,
    ));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: DropdownButtonFormField<String>(
            initialValue: filter.status,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Payment status'),
            items: [
              const DropdownMenuItem(value: '', child: Text('All statuses')),
              for (final s in PaymentStatus.values)
                DropdownMenuItem(value: s.apiValue, child: Text(s.label)),
            ],
            onChanged: ref.read(paymentFilterProvider.notifier).select,
          ),
        ),
        TextButton.icon(
          onPressed: () => ref.invalidate(provider),
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh payments'),
        ),
        Expanded(
          child: AdminAsync(
            value: ref.watch(provider),
            onRetry: () => ref.invalidate(provider),
            builder: (items) => AdminPageBody(
              children: [
                if (items.isEmpty) const AdminEmpty(),
                for (final item in items)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.customerName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(item.customerEmail),
                          Text(item.serviceName),
                          Text(
                            '${item.attempt.status.label} • ${Formatters.price(item.attempt.amount, item.attempt.currency)}',
                          ),
                          Text('Applied: ${item.attempt.applied}'),
                          SelectableText(item.merchantTransactionId),
                          TextButton(
                            onPressed: () => context.go(
                              '/admin/payments/${Uri.encodeComponent(item.attempt.paymentId)}',
                            ),
                            child: const Text('Payment details'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AdminPaymentDetails extends ConsumerWidget {
  const AdminPaymentDetails({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = adminPaymentProvider((
      owner: ref.watch(adminOwnerProvider),
      id: id,
    ));
    return AdminAsync(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      builder: (item) => AdminPageBody(
        children: [
          Text(
            item.serviceName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text('Customer: ${item.customerName} • ${item.customerEmail}'),
          SelectableText('Payment: ${item.attempt.paymentId}'),
          SelectableText('Appointment: ${item.attempt.appointmentId}'),
          Text('Status: ${item.attempt.status.label}'),
          Text('Applied: ${item.attempt.applied}'),
          Text(
            'Amount: ${Formatters.price(item.attempt.amount, item.attempt.currency)}',
          ),
          SelectableText('Merchant reference: ${item.merchantTransactionId}'),
          SelectableText(
            'Validation reference: ${item.validationId ?? 'Unavailable'}',
          ),
          SelectableText(
            'Bank reference: ${item.bankTransactionId ?? 'Unavailable'}',
          ),
          Text('Reason: ${item.attempt.reasonCode ?? 'None'}'),
          Text('Created: ${item.attempt.createdAt.toIso8601String()}'),
          Text('Updated: ${item.attempt.updatedAt.toIso8601String()}'),
          Text(
            'Verified: ${item.attempt.paidAt?.toIso8601String() ?? 'Not verified'}',
          ),
          Text(
            'Last reconciliation: ${item.lastReconciledAt?.toIso8601String() ?? 'Never'}',
          ),
          for (final incident in item.incidents)
            SelectableText(
              'Gateway incident: ${incident.reasonCode}\nValidation: ${incident.validationId ?? 'Unavailable'}\nBank: ${incident.bankTransactionId ?? 'Unavailable'}',
            ),
          if (item.attempt.status == PaymentStatus.reviewRequired)
            const Text(
              'Manual merchant investigation is required. This application cannot approve payments or issue refunds.',
            ),
          FilledButton(
            onPressed: ref.watch(adminPaymentMutationProvider)
                ? null
                : () async {
                    final result = await ref
                        .read(adminPaymentMutationProvider.notifier)
                        .reconcile(id);
                    if (context.mounted) {
                      adminNotice(
                        context,
                        result,
                        success: 'Payment status refreshed.',
                      );
                    }
                  },
            child: const Text('Reconcile payment'),
          ),
          OutlinedButton(
            onPressed: () => ref.invalidate(provider),
            child: const Text('Refresh details'),
          ),
        ],
      ),
    );
  }
}

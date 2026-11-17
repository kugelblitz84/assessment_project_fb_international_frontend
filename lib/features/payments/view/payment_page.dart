import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_error_handler.dart';
import '../../../core/session/application/session_identity_provider.dart';
import '../../../core/widgets/app_resume_listener.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/navigation/page_scaffold.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/utils/formatters.dart';
import '../controller/payment_controller.dart';
import '../model/payment_models.dart';
import '../service/payment_service.dart';
import '../../shared/model/payment_summary.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key, required this.appointmentId});
  final String appointmentId;
  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  final form = GlobalKey<FormState>();
  final contact = {
    for (final name in ['phone', 'address', 'city', 'postcode'])
      name: TextEditingController(),
  };
  String? launchError;
  @override
  void dispose() {
    for (final controller in contact.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> open(PaymentAttempt attempt, PaymentConfig config) async {
    try {
      if (attempt.status != PaymentStatus.pending ||
          attempt.checkoutUrl == null) {
        return;
      }
      final uri = trustedCheckoutUri(attempt.checkoutUrl!, config);
      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      )) {
        throw const FormatException('Unable to launch.');
      }
      if (mounted) setState(() => launchError = null);
    } catch (_) {
      if (mounted) {
        setState(
          () => launchError =
              'Checkout could not be opened safely. You can resume checkout or refresh its status.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final identity = ref.watch(sessionIdentityProvider);
    final provider = paymentControllerProvider((
      identity: identity,
      appointmentId: widget.appointmentId,
    ));
    final controller = ref.read(provider.notifier);
    final config = ref.watch(paymentConfigProvider);
    return AppResumeListener(
      onResume: () => controller.refresh(),
      child: AppPageScaffold(
        title: 'Payment',
        body: SingleChildScrollView(
          child: PageContainer(
            maxWidth: 760,
            child: ref
                .watch(provider)
                .when(
                  loading: () => const LoadingState(
                    label: 'Loading verified payment status…',
                  ),
                  error: (_, _) =>
                      ErrorState(onRetry: () => ref.invalidate(provider)),
                  data: (data) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        data.appointment.serviceName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text('Booking: ${data.appointment.status.name}'),
                      Text('Payment: ${data.appointment.paymentStatus.label}'),
                      Text(
                        Formatters.price(
                          data.appointment.price,
                          data.appointment.currency,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (data.uncertain)
                        const InlineNotice(
                          message:
                              'The payment outcome is uncertain. Refresh the existing payment before attempting another charge.',
                          error: true,
                        ),
                      if (data.error != null)
                        InlineNotice(
                          message: ApiErrorHandler.messageFor(data.error),
                          error: true,
                        ),
                      if (launchError != null)
                        InlineNotice(message: launchError!, error: true),
                      config.when(
                        loading: () => const LoadingState(
                          label: 'Checking payment options…',
                        ),
                        error: (_, _) => ErrorState(
                          onRetry: () => ref.invalidate(paymentConfigProvider),
                        ),
                        data: (capabilities) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (capabilities.sandbox &&
                                capabilities.onlinePaymentEnabled)
                              const Text(
                                'Sandbox checkout • test payments only',
                              ),
                            if (capabilities.payAtWorkshopEnabled &&
                                !data.hasUnresolved)
                              OutlinedButton(
                                onPressed: () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Your booking remains saved. Pay at the workshop; no online payment is created.',
                                        ),
                                      ),
                                    ),
                                child: const Text('Pay at Workshop'),
                              ),
                            if (!capabilities.onlinePaymentEnabled)
                              const Text(
                                'Online payment is currently unavailable. Your booking remains valid.',
                              ),
                            if (capabilities.onlinePaymentEnabled &&
                                data.appointment.canPayOnline &&
                                !data.hasUnresolved &&
                                !data.uncertain)
                              Form(
                                key: form,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text('Checkout contact information'),
                                    for (final entry in contact.entries)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: TextFormField(
                                          controller: entry.value,
                                          enabled: !data.busy,
                                          decoration: InputDecoration(
                                            labelText: switch (entry.key) {
                                              'phone' => 'Phone',
                                              'address' => 'Address',
                                              'city' => 'City',
                                              _ => 'Postcode',
                                            },
                                          ),
                                          keyboardType: entry.key == 'phone'
                                              ? TextInputType.phone
                                              : TextInputType.text,
                                          maxLength: entry.key == 'phone'
                                              ? 20
                                              : entry.key == 'postcode'
                                              ? 30
                                              : 50,
                                          validator: (value) =>
                                              CheckoutContact.validate(
                                                entry.key,
                                                value,
                                              ),
                                        ),
                                      ),
                                    FilledButton(
                                      onPressed: data.busy
                                          ? null
                                          : () async {
                                              if (!form.currentState!
                                                  .validate()) {
                                                return;
                                              }
                                              final attempt = await controller
                                                  .initiate(
                                                    CheckoutContact(
                                                      phone: contact['phone']!
                                                          .text,
                                                      address:
                                                          contact['address']!
                                                              .text,
                                                      city:
                                                          contact['city']!.text,
                                                      postcode:
                                                          contact['postcode']!
                                                              .text,
                                                    ),
                                                  );
                                              if (!mounted ||
                                                  identity !=
                                                      ref.read(
                                                        sessionIdentityProvider,
                                                      )) {
                                                return;
                                              }
                                              if (attempt != null) {
                                                await open(
                                                  attempt,
                                                  capabilities,
                                                );
                                              }
                                            },
                                      child: Text(
                                        data.busy
                                            ? 'Processing…'
                                            : 'Pay Online',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            for (final attempt in data.attempts)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Payment ${attempt.status.label} • ${Formatters.price(attempt.amount, attempt.currency)}',
                                      ),
                                      SelectableText(attempt.paymentId),
                                      Text(
                                        'Created: ${attempt.createdAt.toIso8601String()}',
                                      ),
                                      Text(
                                        'Updated: ${attempt.updatedAt.toIso8601String()}',
                                      ),
                                      Text(
                                        'Applied to booking: ${attempt.applied ? 'Yes' : 'No'}',
                                      ),
                                      if (attempt.paidAt != null)
                                        Text(
                                          'Verified: ${attempt.paidAt!.toIso8601String()}',
                                        ),
                                      if (attempt.status ==
                                              PaymentStatus.paid &&
                                          attempt.applied)
                                        const Text(
                                          'Payment verified by the backend. Appointment confirmation is separate.',
                                        ),
                                      if (attempt.status ==
                                          PaymentStatus.reviewRequired)
                                        const Text(
                                          'Contact workshop support for manual review. Do not make another payment. Paid or unresolved bookings cannot be cancelled online.',
                                        ),
                                      if (attempt.status ==
                                              PaymentStatus.initiating ||
                                          attempt.status ==
                                              PaymentStatus.pending)
                                        const Text(
                                          'Payment processing. Return here after checkout and refresh payment status.',
                                        ),
                                      if (attempt.status ==
                                              PaymentStatus.pending &&
                                          attempt.checkoutUrl != null &&
                                          capabilities.onlinePaymentEnabled &&
                                          data.appointment.paymentStatus ==
                                              PaymentSummary.pending)
                                        OutlinedButton(
                                          onPressed: data.busy
                                              ? null
                                              : () =>
                                                    open(attempt, capabilities),
                                          child: const Text('Resume Checkout'),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: data.busy
                            ? null
                            : () => controller.refresh(),
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          data.busy ? 'Refreshing…' : 'Refresh Payment Status',
                        ),
                      ),
                      const Text(
                        'Allow at least five seconds between verification requests. Only verified backend responses establish payment success.',
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/presentation/adaptive_app_shell.dart';
import '../../../core/responsive/adaptive_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/price_action_bar.dart';
import '../../../core/widgets/service_image.dart';
import '../../../routes/app_routes.dart';
import '../../shared/controller/catalog_controller.dart';
import '../../shared/view/service_price_summary.dart';
import '../../shared/controller/service_details_controller.dart';

class ServiceDetailsPage extends ConsumerWidget {
  const ServiceDetailsPage({super.key, required this.serviceId});
  final String serviceId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(serviceDetailsProvider(serviceId));
    final catalog = ref.watch(catalogControllerProvider).asData?.value;
    final service = details.asData?.value;
    final desktop = AppBreakpoints.isDesktop(MediaQuery.sizeOf(context).width);
    void book() => context.pushNamed(
      AppRoutes.booking,
      pathParameters: {'serviceId': serviceId},
    );
    final button = AppButton(
      label: 'Book appointment',
      icon: Icons.calendar_month_outlined,
      onPressed: service?.available == true ? book : null,
    );
    return AdaptiveAppShell(
      title: 'Service details',
      bottomBar: !desktop && service != null
          ? PriceActionBar(
              price: Formatters.price(service.price, service.currency),
              action: button,
            )
          : null,
      body: SingleChildScrollView(
        child: PageContainer(
          child: details.when(
            loading: () => const LoadingState(label: 'Loading service…'),
            error: (_, _) => ErrorState(
              onRetry: () => ref.invalidate(catalogControllerProvider),
            ),
            data: (service) {
              if (service == null) {
                return ErrorState(
                  code: catalog?.errorCode ?? 'NOT_FOUND',
                  onRetry: () =>
                      ref.read(catalogControllerProvider.notifier).refresh(),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (desktop)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.goNamed(AppRoutes.home),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to services'),
                      ),
                    ),
                  AdaptiveColumns(
                    main: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: ServiceImage(
                            url: service.imageUrl,
                            label: service.name,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          service.categoryName.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          service.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 20,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              Formatters.price(service.price, service.currency),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              Formatters.duration(service.durationMinutes),
                              style: const TextStyle(
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'About this service',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          service.description,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (service.inclusions.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          Text(
                            'What’s included',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          for (final inclusion in service.inclusions)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: AppColors.success,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(inclusion)),
                                ],
                              ),
                            ),
                        ],
                        if (!service.available) ...[
                          const SizedBox(height: 20),
                          const InlineNotice(
                            message:
                                'This service is currently unavailable for booking.',
                          ),
                        ],
                      ],
                    ),
                    aside: ServicePriceSummary(
                      service: service,
                      action: desktop ? button : null,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

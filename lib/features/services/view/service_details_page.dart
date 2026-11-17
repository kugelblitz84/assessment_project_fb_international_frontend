import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/navigation/page_scaffold.dart';
import '../../../core/widgets/responsive/adaptive_layout.dart';
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
    final catalogController = ref.watch(catalogControllerProvider.notifier);
    final catalogError = ref.watch(
      catalogControllerProvider.select(
        (catalog) => catalog.asData?.value.errorCode,
      ),
    );
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
    return AppPageScaffold(
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
                  code: catalogError ?? 'NOT_FOUND',
                  onRetry: catalogController.refresh,
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
                          borderRadius: BorderRadius.circular(
                            AppSize.radius(20),
                          ),
                          child: ServiceImage(
                            url: service.imageUrl,
                            label: service.name,
                          ),
                        ),
                        SizedBox(height: AppSize.vertical(24)),
                        Text(
                          service.categoryName.toUpperCase(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: AppSize.font(12),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: AppSize.vertical(8)),
                        Text(
                          service.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        SizedBox(height: AppSize.vertical(16)),
                        Wrap(
                          spacing: 20,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              Formatters.price(service.price, service.currency),
                              style: TextStyle(
                                fontSize: AppSize.font(24),
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
                        SizedBox(height: AppSize.vertical(24)),
                        Text(
                          'About this service',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: AppSize.vertical(12)),
                        Text(
                          service.description,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (service.inclusions.isNotEmpty) ...[
                          SizedBox(height: AppSize.vertical(28)),
                          Text(
                            'What’s included',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: AppSize.vertical(12)),
                          for (final inclusion in service.inclusions)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSize.vertical(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: AppColors.success,
                                    size: AppSize.icon(22),
                                  ),
                                  SizedBox(width: AppSize.horizontal(12)),
                                  Expanded(child: Text(inclusion)),
                                ],
                              ),
                            ),
                        ],
                        if (!service.available) ...[
                          SizedBox(height: AppSize.vertical(20)),
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

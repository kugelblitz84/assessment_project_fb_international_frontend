import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/app/api_error_messages.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/async_state_view.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/section_header.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/controller/catalog_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/view/widgets/service_card.dart';
import 'package:assessment_project_fb_international_frontend/features/home/controller/home_controller.dart';

class ServiceCatalogSection extends ConsumerWidget {
  const ServiceCatalogSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogControllerProvider);
    final catalogController = ref.watch(catalogControllerProvider.notifier);
    final homeController = ref.watch(homeControllerProvider.notifier);
    final visible = ref.watch(filteredServicesProvider);
    final filtered = ref.watch(
      homeControllerProvider.select((state) => state.filtered),
    );
    Widget box(Widget child) => SliverToBoxAdapter(child: child);
    return catalog.when(
      loading: () =>
          box(const LoadingState(label: 'Finding services for your car...')),
      error: (_, _) => box(
        ErrorState(onRetry: () => ref.invalidate(catalogControllerProvider)),
      ),
      data: (data) {
        if (data.errorCode != null && data.services.isEmpty) {
          return box(
            ErrorState(
              code: data.errorCode,
              onRetry: catalogController.refresh,
            ),
          );
        }
        return SliverMainAxisGroup(
          slivers: [
            box(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (data.refreshing)
                    Padding(
                      padding: EdgeInsets.only(bottom: AppSize.vertical(16)),
                      child: LinearProgressIndicator(),
                    ),
                  if (data.errorCode != null) ...[
                    InlineNotice(
                      message:
                          '${AppErrorMessages.messageFor(data.errorCode)} Showing previously loaded services.',
                      error: true,
                    ),
                    SizedBox(height: AppSize.vertical(16)),
                  ],
                  SectionHeader(
                    title: filtered
                        ? 'Search results'
                        : 'Care for every journey',
                    subtitle:
                        '${visible.length} ${visible.length == 1 ? 'service' : 'services'} to explore',
                    action: filtered
                        ? TextButton(
                            onPressed: homeController.clear,
                            child: const Text('Clear filters'),
                          )
                        : IconButton(
                            tooltip: 'Refresh services',
                            onPressed: data.refreshing
                                ? null
                                : catalogController.refresh,
                            icon: const Icon(Icons.refresh),
                          ),
                  ),
                ],
              ),
            ),
            if (visible.isEmpty)
              box(
                StateMessage(
                  title: 'No services found',
                  message: 'Try another search or choose a different category.',
                  icon: Icons.search_off,
                  action: OutlinedButton(
                    onPressed: homeController.clear,
                    child: const Text('Clear filters'),
                  ),
                ),
              )
            else
              SliverServiceGrid(services: visible),
          ],
        );
      },
    );
  }
}

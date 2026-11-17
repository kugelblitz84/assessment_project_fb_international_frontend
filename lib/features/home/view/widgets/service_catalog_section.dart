import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../../../core/widgets/async_state_view.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../shared/controller/catalog_controller.dart';
import '../../../shared/view/service_card.dart';
import '../../controller/home_controller.dart';

class ServiceCatalogSection extends ConsumerWidget {
  const ServiceCatalogSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogControllerProvider);
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
              onRetry: ref.read(catalogControllerProvider.notifier).refresh,
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
                          '${ApiErrorHandler.messageFor(data.errorCode)} Showing previously loaded services.',
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
                            onPressed: ref
                                .read(homeControllerProvider.notifier)
                                .clear,
                            child: const Text('Clear filters'),
                          )
                        : IconButton(
                            tooltip: 'Refresh services',
                            onPressed: data.refreshing
                                ? null
                                : ref
                                      .read(catalogControllerProvider.notifier)
                                      .refresh,
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
                    onPressed: ref.read(homeControllerProvider.notifier).clear,
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

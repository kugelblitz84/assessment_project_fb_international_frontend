import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:assessment_project_fb_international_frontend/core/theme/app_colors.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/app_surface.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/page_container.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/controller/catalog_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/home/controller/home_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/home/view/widgets/category_filter_section.dart';
import 'package:assessment_project_fb_international_frontend/features/home/view/widgets/explore_hero.dart';
import 'package:assessment_project_fb_international_frontend/features/home/view/widgets/featured_services_section.dart';
import 'package:assessment_project_fb_international_frontend/features/home/view/widgets/home_header.dart';
import 'package:assessment_project_fb_international_frontend/features/home/view/widgets/service_catalog_section.dart';
import 'package:assessment_project_fb_international_frontend/features/home/view/widgets/service_filter_sheet.dart';
import 'package:assessment_project_fb_international_frontend/features/home/view/widgets/service_search_bar.dart';
import 'package:assessment_project_fb_international_frontend/routes/app_routes.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({
    super.key,
    this.categoryId,
    this.resetFilters = false,
    this.browseIntent,
  });
  final String? categoryId;
  final bool resetFilters;
  final String? browseIntent;
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final TextEditingController _search;
  final _searchFocus = FocusNode();
  final _catalogueKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: ref.read(homeControllerProvider).query,
    );
    _applyRouteFilters();
  }

  void _applyRouteFilters() {
    if (!widget.resetFilters && widget.categoryId == null) return;
    // Riverpod mutations wait until the route's widgets have finished mounting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(homeControllerProvider.notifier).browse(widget.categoryId);
      }
    });
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId ||
        oldWidget.resetFilters != widget.resetFilters ||
        oldWidget.browseIntent != widget.browseIntent) {
      _applyRouteFilters();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _exploreServices() {
    Scrollable.ensureVisible(
      _catalogueKey.currentContext!,
      duration: const Duration(milliseconds: 300),
      alignment: .05,
    );
    _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final catalogController = ref.watch(catalogControllerProvider.notifier);
    ref.listen(homeControllerProvider.select((state) => state.query), (
      previous,
      query,
    ) {
      if (_search.text != query) {
        _search.value = TextEditingValue(
          text: query,
          selection: TextSelection.collapsed(offset: query.length),
        );
      }
    });
    return RefreshIndicator(
      onRefresh: catalogController.refresh,
      child: PageSliverScrollView(
        key: const PageStorageKey('home-scroll'),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const HomeHeader(),
                SizedBox(height: AppSize.vertical(24)),
                ExploreHero(onExplore: _exploreServices),
                SizedBox(height: AppSize.vertical(32)),
                ServiceSearchBar(
                  key: _catalogueKey,
                  controller: _search,
                  focusNode: _searchFocus,
                  onFilters: () => ServiceFilterSheet.show(context),
                ),
                SizedBox(height: AppSize.vertical(16)),
                const CategoryFilterSection(),
                SizedBox(height: AppSize.vertical(28)),
              ],
            ),
          ),
          const FeaturedServicesSection(),
          const ServiceCatalogSection(),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSize.vertical(32)),
              child: AppSurface(
                child: Padding(
                  padding: AppSize.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.auto_awesome_outlined,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: AppSize.vertical(12)),
                      Text(
                        'Not sure where to start?',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: AppSize.vertical(8)),
                      const Text(
                        'Ask AutoCare about services and find care that fits your car.',
                        style: TextStyle(color: AppColors.secondary),
                      ),
                      SizedBox(height: AppSize.vertical(12)),
                      TextButton.icon(
                        onPressed: () => context.goNamed(AppRoutes.assistant),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Ask the AI assistant'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

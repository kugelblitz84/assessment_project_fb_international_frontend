import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/page_container.dart';
import '../../../routes/app_routes.dart';
import '../../shared/controller/catalog_controller.dart';
import '../controller/home_controller.dart';
import 'widgets/category_filter_section.dart';
import 'widgets/explore_hero.dart';
import 'widgets/home_header.dart';
import 'widgets/service_search_bar.dart';
import 'widgets/service_catalog_section.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, this.categoryId, this.resetFilters = false});
  final String? categoryId;
  final bool resetFilters;
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
        oldWidget.resetFilters != widget.resetFilters) {
      _applyRouteFilters();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _showFilters() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: AppSize.cardPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filter services',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: AppSize.vertical(20)),
              const CategoryFilterSection(),
              SizedBox(height: AppSize.vertical(24)),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Show services'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
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
      onRefresh: ref.read(catalogControllerProvider.notifier).refresh,
      child: PageSliverScrollView(
        key: const PageStorageKey('home-scroll'),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const HomeHeader(),
                SizedBox(height: AppSize.vertical(24)),
                ExploreHero(
                  onExplore: () {
                    Scrollable.ensureVisible(
                      _catalogueKey.currentContext!,
                      duration: const Duration(milliseconds: 300),
                      alignment: .05,
                    );
                    _searchFocus.requestFocus();
                  },
                ),
                SizedBox(height: AppSize.vertical(32)),
                ServiceSearchBar(
                  key: _catalogueKey,
                  controller: _search,
                  focusNode: _searchFocus,
                  onFilters: _showFilters,
                ),
                SizedBox(height: AppSize.vertical(16)),
                const CategoryFilterSection(),
                SizedBox(height: AppSize.vertical(28)),
              ],
            ),
          ),
          const ServiceCatalogSection(),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSize.vertical(32)),
              child: Card(
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

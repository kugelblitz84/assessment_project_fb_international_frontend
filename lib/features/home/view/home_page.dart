import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/presentation/adaptive_app_shell.dart';
import '../../../core/network/api_error_handler.dart';
import '../../../core/session/application/current_user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/section_header.dart';
import '../../../routes/app_routes.dart';
import '../../shared/controller/catalog_controller.dart';
import '../../shared/view/service_card.dart';
import '../controller/home_controller.dart';

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
    if (widget.resetFilters || widget.categoryId != null) {
      Future.microtask(() {
        if (mounted) {
          ref.read(homeControllerProvider.notifier).browse(widget.categoryId);
        }
      });
    }
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

  Widget _categories(WidgetRef ref) {
    final services =
        ref.watch(catalogControllerProvider).asData?.value.services ?? const [];
    final categories = {for (final s in services) s.categoryId: s.categoryName};
    final filter = ref.watch(homeControllerProvider);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('All services'),
          selected: filter.categoryId == null,
          onSelected: (_) =>
              ref.read(homeControllerProvider.notifier).category(null),
        ),
        for (final category in categories.entries)
          ChoiceChip(
            label: Text(category.value),
            selected: filter.categoryId == category.key,
            onSelected: (_) => ref
                .read(homeControllerProvider.notifier)
                .category(category.key),
          ),
      ],
    );
  }

  void _showFilters() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Consumer(
            builder: (context, ref, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Filter services',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                _categories(ref),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Show services'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final catalog = ref.watch(catalogControllerProvider);
    final filter = ref.watch(homeControllerProvider);
    ref.listen(homeControllerProvider, (previous, next) {
      if (_search.text != next.query) {
        _search.value = TextEditingValue(
          text: next.query,
          selection: TextSelection.collapsed(offset: next.query.length),
        );
      }
    });
    return AdaptiveAppShell(
      primary: true,
      body: RefreshIndicator(
        onRefresh: () => ref.read(catalogControllerProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: PageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  user == null ? 'Welcome' : 'Welcome, ${user.name}',
                  style: const TextStyle(color: AppColors.secondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'A little care. A better drive.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                _ExploreHero(
                  onExplore: () {
                    Scrollable.ensureVisible(
                      _catalogueKey.currentContext!,
                      duration: const Duration(milliseconds: 300),
                      alignment: .05,
                    );
                    _searchFocus.requestFocus();
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  key: _catalogueKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        focusNode: _searchFocus,
                        onChanged: ref
                            .read(homeControllerProvider.notifier)
                            .search,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          labelText: 'Search services',
                          hintText: 'Try oil change or car wash',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: filter.query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () => ref
                                      .read(homeControllerProvider.notifier)
                                      .search(''),
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 60,
                      child: IconButton.outlined(
                        tooltip: 'Filter services',
                        onPressed: _showFilters,
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _categories(ref),
                const SizedBox(height: 28),
                catalog.when(
                  loading: () => const LoadingState(
                    label: 'Finding services for your car…',
                  ),
                  error: (_, _) => ErrorState(
                    onRetry: () => ref.invalidate(catalogControllerProvider),
                  ),
                  data: (data) {
                    if (data.errorCode != null && data.services.isEmpty) {
                      return ErrorState(
                        code: data.errorCode,
                        onRetry: () => ref
                            .read(catalogControllerProvider.notifier)
                            .refresh(),
                      );
                    }
                    final visible = ref.watch(filteredServicesProvider);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (data.refreshing)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: LinearProgressIndicator(),
                          ),
                        if (data.errorCode != null) ...[
                          InlineNotice(
                            message:
                                '${ApiErrorHandler.messageFor(data.errorCode)} Showing previously loaded services.',
                            error: true,
                          ),
                          const SizedBox(height: 16),
                        ],
                        SectionHeader(
                          title: filter.filtered
                              ? 'Search results'
                              : 'Care for every journey',
                          subtitle:
                              '${visible.length} ${visible.length == 1 ? 'service' : 'services'} to explore',
                          action: filter.filtered
                              ? TextButton(
                                  onPressed: () => ref
                                      .read(homeControllerProvider.notifier)
                                      .clear(),
                                  child: const Text('Clear filters'),
                                )
                              : IconButton(
                                  tooltip: 'Refresh services',
                                  onPressed: data.refreshing
                                      ? null
                                      : () => ref
                                            .read(
                                              catalogControllerProvider
                                                  .notifier,
                                            )
                                            .refresh(),
                                  icon: const Icon(Icons.refresh),
                                ),
                        ),
                        if (visible.isEmpty)
                          StateMessage(
                            title: 'No services found',
                            message:
                                'Try another search or choose a different category.',
                            icon: Icons.search_off,
                            action: OutlinedButton(
                              onPressed: () => ref
                                  .read(homeControllerProvider.notifier)
                                  .clear(),
                              child: const Text('Clear filters'),
                            ),
                          )
                        else
                          ServiceGrid(services: visible),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.auto_awesome_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Not sure where to start?',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ask AutoCare about services and find care that fits your car.',
                          style: TextStyle(color: AppColors.secondary),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => context.goNamed(AppRoutes.assistant),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Ask the AI assistant'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreHero extends StatelessWidget {
  const _ExploreHero({required this.onExplore});
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(20),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 750;
        final text = Padding(
          padding: EdgeInsets.all(wide ? 36 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CAR CARE, MADE SIMPLE',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFF3BDAA),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Expert care.\nReady when you are.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: wide ? 38 : 28,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'From a fresh finish to everyday maintenance. Find your service and choose a time that works.',
                style: TextStyle(color: Color(0xFFD5DFEB), height: 1.6),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onExplore,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Explore services'),
              ),
            ],
          ),
        );
        final art = ExcludeSemantics(
          child: SizedBox(
            height: wide ? 300 : 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .12),
                      width: 30,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: -.12,
                  child: Icon(
                    Icons.directions_car_filled_rounded,
                    size: wide ? 240 : 150,
                    color: const Color(0xFFE4EAF1),
                  ),
                ),
                Positioned(
                  bottom: wide ? 30 : 5,
                  child: Container(
                    width: 200,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        return wide
            ? Row(
                children: [
                  Expanded(flex: 3, child: text),
                  Expanded(flex: 2, child: art),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [text, art],
              );
      },
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/core/design/design.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/widgets/souk_widgets.dart' show DirectionalIcon;
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/features/products/presentation/discover_strings.dart';
import 'package:dealsouk/features/products/presentation/product_widgets.dart';
import 'package:dealsouk/features/products/presentation/products_providers.dart';
import 'package:dealsouk/features/products/presentation/request_sheet.dart';
import 'package:dealsouk/features/saved/presentation/saved_providers.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

class _CatalogCategory {
  final String Function(AppLocalizations) title;
  final String filterCategory;

  const _CatalogCategory(this.title, this.filterCategory);
}

final _catalogCategories = [
  _CatalogCategory((l) => l.searchCatFresh, 'Fresh'),
  _CatalogCategory((l) => l.searchCatFruits, 'Fruits'),
  _CatalogCategory((l) => l.searchCatSnacks, 'Snacks'),
  _CatalogCategory((l) => l.searchCatGrocery, 'Dairy & Sweet'),
  _CatalogCategory((l) => l.searchCatOils, 'Bakery'),
];

enum _Sort { lowest, nearest, freshest }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;
  _Sort _sort = _Sort.lowest;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(filterProvider).searchQuery,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Product> _visible(List<Product> products, FilterState f) {
    final q = f.searchQuery.trim().toLowerCase();
    final cat = f.selectedCategory.toLowerCase();
    final list = filterByFreshness(
      products.where((p) {
        final matchesCategory = cat == 'all' || p.category.toLowerCase() == cat;
        final matchesSearch =
            q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q);
        return matchesCategory && matchesSearch;
      }).toList(),
      f.freshnessFilter,
    );
    switch (_sort) {
      case _Sort.lowest:
        list.sort((a, b) => a.lowestPrice.compareTo(b.lowestPrice));
      case _Sort.nearest:
        final d = {
          for (final p in list) p.id: storeDistanceKm(ref, p.lowestPriceStore),
        };
        list.sort((a, b) => d[a.id]!.compareTo(d[b.id]!));
      case _Sort.freshest:
        list.sort(
          (a, b) => (a.hoursAgo ?? kNoFreshnessHours).compareTo(
            b.hoursAgo ?? kNoFreshnessHours,
          ),
        );
    }
    return list;
  }

  void _setQuery(String q) =>
      ref.read(filterProvider.notifier).setSearchQuery(q);

  void _askShoppers(String query) {
    final cost = ref.read(adminSettingsProvider).requestCostTokens;
    showItemRequestSheet(context, ref, query, cost);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = DiscoverStrings.of(context);
    final products = ref.watch(productsProvider);
    final load = ref.watch(productsLoadProvider);
    final f = ref.watch(filterProvider);
    final savedCount = ref.watch(savedProductsProvider).length;
    final results = _visible(products, f);

    // Keep the field in step when the query is set elsewhere (barcode scan).
    if (_controller.text != f.searchQuery) {
      _controller.value = TextEditingValue(
        text: f.searchQuery,
        selection: TextSelection.collapsed(offset: f.searchQuery.length),
      );
    }

    final body = _buildBody(context, l, s, f, results, products, load);

    if (context.isExpanded) {
      return Scaffold(backgroundColor: AppTheme.background, body: body);
    }
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const DirectionalIcon(Icons.arrow_back_ios_new_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.go('/'),
        ),
        title: Text(l.searchDailyFoods),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                DsIconButton(
                  icon: Icons.bookmark_border_rounded,
                  semanticLabel: l.searchMyList,
                  color: AppTheme.forestDeep,
                  onPressed: () => context.go('/saved'),
                ),
                if (savedCount > 0)
                  PositionedDirectional(
                    end: -2,
                    top: -2,
                    child: DsCountBadge(savedCount),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _searchField(AppLocalizations l, FilterState f) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            textField: true,
            label: l.searchHint,
            child: TextField(
              controller: _controller,
              onChanged: _setQuery,
              textInputAction: TextInputAction.search,
              style: AppFonts.body(fontSize: 17, color: AppTheme.ink),
              decoration: InputDecoration(
                hintText: l.searchHint,
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search_rounded, size: 24),
                suffixIcon: f.searchQuery.isNotEmpty
                    ? IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).deleteButtonTooltip,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          _setQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppTheme.line,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppTheme.forestDeep,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        DsIconButton(
          icon: Icons.qr_code_scanner_rounded,
          semanticLabel: l.searchScanBarcode,
          filled: true,
          size: 56,
          onPressed: () => context.push('/scan-barcode'),
        ),
      ],
    );
  }

  Widget _categoryChips(AppLocalizations l, DiscoverStrings s, FilterState f) {
    final selected = f.selectedCategory.toLowerCase();
    return DsChipRow(
      chips: [
        DsChip(
          label: s.all,
          selected: selected == 'all',
          onTap: () => ref.read(filterProvider.notifier).setCategory('All'),
        ),
        for (final c in _catalogCategories)
          DsChip(
            label: c.title(l),
            selected: selected == c.filterCategory.toLowerCase(),
            onTap: () =>
                ref.read(filterProvider.notifier).setCategory(c.filterCategory),
          ),
      ],
    );
  }

  Widget _statusState(
    AppLocalizations l,
    FilterState f,
    List<Product> all,
    ProductsLoadState load,
  ) {
    if (all.isEmpty && load == ProductsLoadState.error) {
      return DsEmptyState(
        icon: Icons.cloud_off_rounded,
        tone: DsEmptyTone.error,
        title: l.homeLoadError,
        message: l.homeLoadErrorHint,
        primaryLabel: l.retry,
        onPrimary: () => ref
            .read(productsProvider.notifier)
            .fetch(
              query: f.searchQuery,
              category: f.selectedCategory == 'All' ? null : f.selectedCategory,
            ),
      );
    }
    if (all.isEmpty && load == ProductsLoadState.loading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          DsListRowSkeleton(),
          SizedBox(height: 12),
          DsListRowSkeleton(),
          SizedBox(height: 12),
          DsListRowSkeleton(),
        ],
      );
    }
    final hasQuery = f.searchQuery.trim().isNotEmpty;
    return DsEmptyState(
      icon: Icons.search_off_rounded,
      title: hasQuery
          ? l.searchEmptyQueryTitle(f.searchQuery)
          : l.searchEmptyCategoryTitle,
      message: hasQuery
          ? l.searchEmptyQuerySubtitle
          : l.searchEmptyCategorySubtitle,
      primaryLabel: hasQuery ? l.searchAskShoppersToCheck : null,
      onPrimary: hasQuery ? () => _askShoppers(f.searchQuery.trim()) : null,
    );
  }

  Widget _askBanner(AppLocalizations l, DiscoverStrings s, FilterState f) {
    return DsBanner(
      s.cantFind,
      icon: Icons.info_outline_rounded,
      action: DsButton(
        label: l.searchAskShoppersToCheck,
        compact: true,
        expanded: false,
        onPressed: () => _askShoppers(f.searchQuery.trim()),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l,
    DiscoverStrings s,
    FilterState f,
    List<Product> results,
    List<Product> all,
    ProductsLoadState load,
  ) {
    if (context.isExpanded) {
      return _desktop(context, l, s, f, results, all, load);
    }

    final wide = context.isMedium;
    final empty = results.isEmpty;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: _searchField(l, f),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _categoryChips(l, s, f),
        ),
        if (!empty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l.homeSearchResultsCount(results.length),
                style: AppFonts.body(fontSize: 14, color: AppTheme.textLight),
              ),
            ),
          ),
        Expanded(
          child: empty
              ? _statusState(l, f, all, load)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    if (wide)
                      AdaptiveGrid(
                        minTileWidth: 250,
                        mainAxisExtent: 330,
                        children: [
                          for (final p in results) ProductTileCard(product: p),
                        ],
                      )
                    else
                      for (final p in results)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ProductRowCard(
                            product: p,
                            showListButton: true,
                          ),
                        ),
                    const SizedBox(height: 4),
                    _askBanner(l, s, f),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _desktop(
    BuildContext context,
    AppLocalizations l,
    DiscoverStrings s,
    FilterState f,
    List<Product> results,
    List<Product> all,
    ProductsLoadState load,
  ) {
    final selected = f.selectedCategory.toLowerCase();
    final title = selected == 'all'
        ? s.all
        : _catalogCategories
              .firstWhere(
                (c) => c.filterCategory.toLowerCase() == selected,
                orElse: () => _catalogCategories.first,
              )
              .title(l);
    return SingleChildScrollView(
      child: PageContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DsCard(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                            child: Text(
                              s.category,
                              style: AppFonts.display(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink,
                              ),
                            ),
                          ),
                          _CategoryOption(
                            label: s.all,
                            selected: selected == 'all',
                            onTap: () => ref
                                .read(filterProvider.notifier)
                                .setCategory('All'),
                          ),
                          for (final c in _catalogCategories)
                            _CategoryOption(
                              label: c.title(l),
                              selected:
                                  selected == c.filterCategory.toLowerCase(),
                              onTap: () => ref
                                  .read(filterProvider.notifier)
                                  .setCategory(c.filterCategory),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    DsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.freshness,
                            style: AppFonts.display(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final fl in freshnessFilters)
                                DsChip(
                                  label: freshnessFilterLabel(l, fl),
                                  selected: f.freshnessFilter == fl,
                                  onTap: () => ref
                                      .read(filterProvider.notifier)
                                      .setFreshnessFilter(fl),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _searchField(l, f),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  title,
                                  style: AppFonts.display(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.ink,
                                  ),
                                ),
                              ),
                              Text(
                                l.homeSearchResultsCount(results.length),
                                style: AppFonts.body(
                                  fontSize: 15,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 380,
                          child: DsSegmented(
                            labels: [
                              s.sortLowest,
                              s.sortNearest,
                              s.sortFreshest,
                            ],
                            selected: _sort.index,
                            onChanged: (i) =>
                                setState(() => _sort = _Sort.values[i]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (results.isEmpty)
                      SizedBox(
                        height: 360,
                        child: _statusState(l, f, all, load),
                      )
                    else
                      AdaptiveGrid(
                        minTileWidth: 250,
                        mainAxisExtent: 340,
                        maxColumns: 3,
                        children: [
                          for (final p in results) ProductTileCard(product: p),
                        ],
                      ),
                    const SizedBox(height: 20),
                    _askBanner(l, s, f),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: selected ? AppTheme.forestDeep : AppTheme.textLight,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: AppFonts.body(
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

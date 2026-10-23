import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/core/design/design.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/widgets/souk_widgets.dart';
import 'package:dealsouk/features/products/presentation/product_widgets.dart';
import 'package:dealsouk/features/products/presentation/products_providers.dart';
import 'package:dealsouk/features/saved/presentation/saved_providers.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

/// G3 / US-10: a lightweight saved-items list, distinct from the list of items
/// being price-checked. Shows the products the shopper bookmarked (heart on the
/// product detail screen).
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final products = ref.watch(productsProvider);
    final savedIds = ref.watch(savedProductsProvider);
    final saved = products.where((p) => savedIds.contains(p.id)).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const DirectionalIcon(Icons.arrow_back_ios_new_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(
          l.savedTitle,
          style: AppFonts.display(
            color: AppTheme.ink,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: saved.isEmpty
          ? DsEmptyState(
              icon: Icons.bookmark_border_rounded,
              title: l.savedEmptyTitle,
              message: l.savedEmptyHint,
              primaryLabel: l.homeBrowseItems,
              onPrimary: () => context.go('/search'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              child: PageContainer(
                child: context.isCompact
                    ? Column(
                        children: [
                          for (final p in saved)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ProductRowCard(product: p),
                            ),
                        ],
                      )
                    : AdaptiveGrid(
                        mainAxisExtent: 300,
                        children: [
                          for (final p in saved) ProductTileCard(product: p),
                        ],
                      ),
              ),
            ),
    );
  }
}

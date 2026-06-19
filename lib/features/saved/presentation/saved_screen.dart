import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dealsouk/features/products/presentation/products_providers.dart';
import 'package:dealsouk/features/saved/presentation/saved_providers.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/widgets/responsive_container.dart';
import 'package:dealsouk/core/widgets/souk_widgets.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

/// G3 / US-10: a lightweight saved-items list, distinct from the cart. Shows
/// the products the shopper bookmarked (heart on the product detail screen).
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final products = ref.watch(productsProvider);
    final savedIds = ref.watch(savedProductsProvider);
    final saved = products.where((p) => savedIds.contains(p.id)).toList();

    return ResponsiveContainer(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const DirectionalIcon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black,
            ),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
          title: Text(
            l.savedTitle,
            style: GoogleFonts.fredoka(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: saved.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border_rounded,
                        size: 60,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l.savedEmptyTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l.savedEmptyHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () => context.go('/search'),
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: Text(l.homeBrowseItems),
                      ),
                    ],
                  ),
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: saved.length,
                itemBuilder: (context, index) =>
                    ProductGridCard(product: saved[index]),
              ),
      ),
    );
  }
}

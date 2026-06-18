import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/features/cart/presentation/cart_providers.dart';
import 'package:dealsouk/core/theme/theme.dart';

/// An [Icon] that mirrors horizontally when the ambient text direction is RTL
/// (Arabic). Use for directional glyphs — back arrows and disclosure chevrons —
/// that must point the other way in a right-to-left layout.
class DirectionalIcon extends StatelessWidget {
  const DirectionalIcon(this.icon, {super.key, this.color, this.size});

  final IconData icon;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(this.icon, color: color, size: size);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return isRtl ? Transform.flip(flipX: true, child: icon) : icon;
  }
}

/// Clips a container so its bottom edge becomes one smooth downward arc —
/// the curve under the reference design's dark green headers.
class ArcBottomClipper extends CustomClipper<Path> {
  final double depth;

  const ArcBottomClipper({this.depth = 28});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - depth);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + depth,
      size.width,
      size.height - depth,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(ArcBottomClipper oldClipper) => oldClipper.depth != depth;
}

/// Clips a container so one horizontal edge becomes a row of scallops
/// (the awning trim from the reference design).
class ScallopClipper extends CustomClipper<Path> {
  final double scallopRadius;
  final bool
  bulgeDown; // true: bottom edge scalloped; false: top edge scalloped

  const ScallopClipper.down({this.scallopRadius = 9}) : bulgeDown = true;
  const ScallopClipper.up({this.scallopRadius = 9}) : bulgeDown = false;

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final n = (w / (scallopRadius * 2.6)).round().clamp(6, 40);
    final sw = w / n;

    if (bulgeDown) {
      // Solid top, scalloped bottom edge
      path.moveTo(0, 0);
      path.lineTo(0, h - scallopRadius);
      for (int i = 0; i < n; i++) {
        final x0 = i * sw;
        // quadratic through control point below the edge => apex touches h
        path.quadraticBezierTo(
          x0 + sw / 2,
          h + scallopRadius,
          x0 + sw,
          h - scallopRadius,
        );
      }
      path.lineTo(w, 0);
    } else {
      // Scalloped top edge, solid bottom
      path.moveTo(0, h);
      path.lineTo(0, scallopRadius);
      for (int i = 0; i < n; i++) {
        final x0 = i * sw;
        path.quadraticBezierTo(
          x0 + sw / 2,
          -scallopRadius,
          x0 + sw,
          scallopRadius,
        );
      }
      path.lineTo(w, h);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(ScallopClipper oldClipper) =>
      oldClipper.scallopRadius != scallopRadius ||
      oldClipper.bulgeDown != bulgeDown;
}

/// PRD price format, e.g. AED 14.75.
class SoukPrice extends StatelessWidget {
  final double price;
  final double size;
  final Color color;
  final bool showCurrency;
  final String currency;

  const SoukPrice(
    this.price, {
    super.key,
    this.size = 15,
    this.color = AppTheme.forestDeep,
    this.showCurrency = true,
    this.currency = 'AED',
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      showCurrency
          ? '$currency ${price.toStringAsFixed(2)}'
          : price.toStringAsFixed(2),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color,
      ),
    );
  }
}

Color categoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'meats':
    case 'meat':
    case 'meat & seafood':
      return const Color(0xFF0C3B2E);
    case 'vegetable':
      return const Color(0xFF1B5E20);
    case 'fruits':
      return const Color(0xFFE65100);
    case 'breads':
      return const Color(0xFF5D4037);
    case 'snacks':
      return const Color(0xFFD81B60);
    case 'bakery':
      return const Color(0xFF8D6E63);
    case 'dairy & sweet':
      return const Color(0xFF1E88E5);
    case 'chicken':
      return const Color(0xFFD84315);
    default:
      return AppTheme.forestDeep;
  }
}

IconData categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'meats':
    case 'meat':
    case 'meat & seafood':
      return Icons.kebab_dining_outlined;
    case 'vegetable':
      return Icons.spa_outlined;
    case 'fruits':
      return Icons.apple_outlined;
    case 'breads':
      return Icons.bakery_dining_outlined;
    case 'snacks':
      return Icons.fastfood_outlined;
    case 'bakery':
      return Icons.breakfast_dining_outlined;
    case 'dairy & sweet':
      return Icons.egg_alt_outlined;
    case 'chicken':
      return Icons.restaurant_rounded;
    default:
      return Icons.local_grocery_store_outlined;
  }
}

/// 3-column product card from the reference design: image, centered name,
/// pack size, superscript price, and a bottom save button.
class ProductGridCard extends ConsumerWidget {
  final Product product;

  const ProductGridCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final isSaved = cartItems.any((item) => item.product.id == product.id);

    // Split name like "Beetroot (Local shop)" into main and subtitle
    final parts = product.name.split('(');
    final coreName = parts[0].trim();

    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with light rounded background
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F9F4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SoukProductVisual(
                      product: product,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Product Name
            Text(
              coreName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),

            // Brand
            Text(
              product.brand,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            // Bottom Section: Price + Add Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SoukPrice(
                        product.lowestPrice,
                        size: 13.0,
                        color: AppTheme.forestDeep,
                      ),
                      Text(
                        product.packSize,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.0,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    if (isSaved) {
                      ref
                          .read(cartProvider.notifier)
                          .removeFromCart(product.id);
                    } else {
                      ref.read(cartProvider.notifier).addToCart(product);
                    }
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isSaved ? AppTheme.cream : AppTheme.forestDeep,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: isSaved ? AppTheme.forestDeep : Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SoukProductVisual extends StatelessWidget {
  final Product product;
  final BoxFit fit;
  final double borderRadius;

  const SoukProductVisual({
    super.key,
    required this.product,
    this.fit = BoxFit.contain,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(product.category);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F3EA),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: product.imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: product.imageUrl,
                fit: fit,
                // P4: cap decode size to the card slot + disk cache (NFR-01).
                memCacheWidth: 320,
                placeholder: (context, url) =>
                    _FallbackProductIcon(product: product, color: color),
                errorWidget: (context, url, error) =>
                    _FallbackProductIcon(product: product, color: color),
              )
            : _FallbackProductIcon(product: product, color: color),
      ),
    );
  }
}

class _FallbackProductIcon extends StatelessWidget {
  final Product product;
  final Color color;

  const _FallbackProductIcon({required this.product, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
        ),
        Icon(
          categoryIcon(product.category),
          color: color.withValues(alpha: 0.78),
          size: 34,
        ),
      ],
    );
  }
}

/// A premium reusable glassmorphic container that renders a blurred frosted-glass surface.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color color;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 15.0,
    this.color = const Color(0x12FFFFFF), // Semi-transparent glass base
    this.border,
    this.boxShadow,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(borderRadius),
              border:
                  border ??
                  Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1.5,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

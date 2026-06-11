import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../state/state.dart';
import '../theme/theme.dart';

/// Clips a container so its bottom edge becomes one smooth downward arc —
/// the curve under the reference design's dark green headers.
class ArcBottomClipper extends CustomClipper<Path> {
  final double depth;

  const ArcBottomClipper({this.depth = 28});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - depth);
    path.quadraticBezierTo(size.width / 2, size.height + depth, size.width, size.height - depth);
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
  final bool bulgeDown; // true: bottom edge scalloped; false: top edge scalloped

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
        path.quadraticBezierTo(x0 + sw / 2, h + scallopRadius, x0 + sw, h - scallopRadius);
      }
      path.lineTo(w, 0);
    } else {
      // Scalloped top edge, solid bottom
      path.moveTo(0, h);
      path.lineTo(0, scallopRadius);
      for (int i = 0; i < n; i++) {
        final x0 = i * sw;
        path.quadraticBezierTo(x0 + sw / 2, -scallopRadius, x0 + sw, scallopRadius);
      }
      path.lineTo(w, h);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(ScallopClipper oldClipper) =>
      oldClipper.scallopRadius != scallopRadius || oldClipper.bulgeDown != bulgeDown;
}

/// Price with superscript decimals, e.g. 17.^29 $ — reference design style.
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
    this.currency = '\$',
  });

  @override
  Widget build(BuildContext context) {
    final whole = price.floor().toString();
    final cents = ((price * 100).round() % 100).toString().padLeft(2, '0');
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$whole.',
            style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: color),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: Text(
              showCurrency ? '$cents$currency' : cents,
              style: TextStyle(fontSize: size * 0.65, fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

Color categoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'dairy & eggs': return const Color(0xFF1E88E5);
    case 'pantry': return const Color(0xFFFF8F00);
    case 'meat & seafood': return const Color(0xFFE53935);
    case 'beverages': return const Color(0xFF8E24AA);
    case 'household': return const Color(0xFF00ACC1);
    default: return AppTheme.forestDeep;
  }
}

IconData categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'dairy & eggs': return Icons.egg_alt_outlined;
    case 'pantry': return Icons.breakfast_dining_outlined;
    case 'meat & seafood': return Icons.kebab_dining_outlined;
    case 'beverages': return Icons.local_drink_outlined;
    case 'household': return Icons.clean_hands_outlined;
    default: return Icons.shopping_basket_outlined;
  }
}

/// 3-column product card from the reference design: image, centered name,
/// pack size, superscript price, and a bottom "+" that morphs into a lime
/// quantity stepper once the item is in the cart.
class ProductGridCard extends ConsumerWidget {
  final Product product;

  const ProductGridCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final inCartQty = cartItems
        .where((item) => item.product.id == product.id)
        .fold<int>(0, (sum, item) => sum + item.quantity);

    final theme = Theme.of(context);

    // Split name like "Beetroot (Local shop)" into main and subtitle
    final parts = product.name.split('(');
    final coreName = parts[0].trim();
    final subName = parts.length > 1 ? '(${parts[1]}' : '';

    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: Column(
          children: [
            // Image
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox.expand(
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: const Color(0xFFF6F4EE),
                              child: Icon(
                                categoryIcon(product.category),
                                color: categoryColor(product.category).withOpacity(0.5),
                                size: 32,
                              ),
                            ),
                          )
                        : ColoredBox(
                            color: const Color(0xFFF6F4EE),
                            child: Icon(
                              categoryIcon(product.category),
                              color: categoryColor(product.category).withOpacity(0.5),
                              size: 32,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Name (centered split typography like reference)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    coreName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.forestDeep,
                      height: 1.1,
                    ),
                  ),
                  if (subName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                        height: 1.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Pack size
            Text(
              product.packSize,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),

            // Price tag
            SoukPrice(product.lowestPrice, size: 15, color: AppTheme.textDark),
            const SizedBox(height: 8),

            // Bottom control: soft "+" pill, or lime stepper when in cart
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 32,
                decoration: BoxDecoration(
                  color: inCartQty == 0 ? const Color(0xFFEDF1E4) : AppTheme.limeAccent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: inCartQty == 0
                    ? InkWell(
                        onTap: () => ref.read(cartProvider.notifier).addToCart(product),
                        borderRadius: BorderRadius.circular(16),
                        child: const Center(
                          child: Icon(Icons.add, size: 20, color: AppTheme.forestDeep),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: () => ref
                                .read(cartProvider.notifier)
                                .updateQuantity(product.id, inCartQty - 1),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.remove, size: 14, color: AppTheme.forestDeep),
                            ),
                          ),
                          Text(
                            '$inCartQty',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.forestDeep,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => ref.read(cartProvider.notifier).addToCart(product),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.add, size: 14, color: AppTheme.forestDeep),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

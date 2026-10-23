import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

// Logos are public assets — always served from the real backend even in debug.
// This matters on real iOS/Android devices where localhost:3000 is unreachable.
const _kLogoBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://dealsouk.onrender.com',
);

/// Resolves a chain name to its bundled asset slug (e.g. 'carrefour'), or null
/// for unknown chains. The slug maps to `assets/logos/<slug>.png` and to the
/// backend proxy route `/logos/<slug>`. Single source of truth — the store map
/// and the home Featured Stores cards both resolve logos through here.
String? storeChainSlug(String name) {
  final n = name.toLowerCase();
  if (n.contains('carrefour')) return 'carrefour';
  if (n.contains('lulu')) return 'lulu';
  if (n.contains('spinneys')) return 'spinneys';
  if (n.contains('waitrose')) return 'waitrose';
  if (n.contains('union')) return 'union_coop';
  if (n.contains('choithrams')) return 'choithrams';
  if (n.contains('geant')) return 'geant';
  if (n.contains('nesto')) return 'nesto';
  if (n.contains('al maya')) return 'al_maya';
  if (n.contains('grandiose')) return 'grandiose';
  if (n.contains('al madina') || n.contains('madina')) return 'al_madina';
  return null;
}

/// Network fallback for a chain logo when no bundled asset is present.
/// Served through our own backend (`/logos/:slug`) so it carries CORS + cache
/// headers and renders on Flutter Web too. Returns null for unknown chains.
String? storeChainLogoUrl(String name) {
  final slug = storeChainSlug(name);
  if (slug == null) return null;
  return '$_kLogoBaseUrl/logos/$slug';
}

/// Circular (or rounded-square) avatar showing a chain's real logo, with a
/// brand-colored letter initial as the fallback while loading or on error.
///
/// Logo resolution order:
///   1. Bundled asset `assets/logos/<slug>.png` (instant, offline, no flicker)
///   2. Backend proxy `/logos/<slug>` (if the asset isn't present)
///   3. Polished brand-colored initial (always renders)
class StoreLogoAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final double size;

  /// Inner padding around the logo image.
  final double padding;

  /// Corner radius. Defaults to size/2 (full circle). Pass a fixed value for
  /// rounded-square cards.
  final double? borderRadius;

  /// Border ring around the avatar. Defaults to a subtle tint of [color].
  final Color? borderColor;

  const StoreLogoAvatar({
    super.key,
    required this.name,
    required this.color,
    required this.size,
    this.padding = 6,
    this.borderRadius,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final slug = storeChainSlug(name);
    final radius = borderRadius ?? size / 2;
    final bgColor = slug != null ? Colors.white : color;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? color.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: _buildContent(slug, radius),
    );
  }

  Widget _buildContent(String? slug, double radius) {
    if (slug == null) return _fallback(radius);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius - 1.5),
      child: Image.asset(
        'assets/logos/$slug.png',
        fit: BoxFit.contain,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return Container(
              color: Colors.white,
              padding: EdgeInsets.all(padding),
              child: child,
            );
          }
          return _fallback(radius);
        },
        errorBuilder: (ctx, assetErr, assetStack) => _networkOrFallback(radius),
      ),
    );
  }

  Widget _networkOrFallback(double radius) {
    final url = storeChainLogoUrl(name);
    if (url == null) return _fallback(radius);
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      // P4: disk-cached store logos with a slot-sized decode (NFR-01).
      memCacheWidth: (radius * 6).round(),
      imageBuilder: (context, imageProvider) => Container(
        color: Colors.white,
        padding: EdgeInsets.all(padding),
        child: Image(image: imageProvider, fit: BoxFit.contain),
      ),
      placeholder: (context, u) => _fallback(radius),
      errorWidget: (ctx, u, error) => _fallback(radius),
    );
  }

  Widget _fallback(double radius) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius - 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

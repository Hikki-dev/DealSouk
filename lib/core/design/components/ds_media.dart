import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/core/design/components/ds_button.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/widgets/store_logo_avatar.dart';

/// Bundled Dubai photographs. Credits are shown in the app under
/// Privacy & Terms and listed in `docs/DESIGN_SYSTEM.md`.
class DsPhotos {
  DsPhotos._();

  static const marina = 'assets/images/welcome_marina.jpg';
  static const shelf = 'assets/images/offer_shelf.jpg';
  static const creek = 'assets/images/offer_creek.jpg';
  static const market = 'assets/images/offer_market.jpg';
  static const burj = 'assets/images/offer_burj.jpg';
  static const dunes = 'assets/images/offer_dunes.jpg';
}

/// A photograph with a dark teal fade so overlaid text keeps 4.5:1 contrast.
///
/// [fadeFromStart] fades from the reading edge (left in English, right in
/// Arabic), for banners with text on one side. Otherwise it fades from the
/// bottom, for text over the lower part of the photo.
class DsPhotoBanner extends StatelessWidget {
  const DsPhotoBanner({
    super.key,
    required this.asset,
    this.child,
    this.height,
    this.radius = 20,
    this.fadeFromStart = false,
    this.alignment = Alignment.center,
    this.padding = const EdgeInsets.all(18),
    this.childAlignment = AlignmentDirectional.bottomStart,
    this.decodeWidth = 900,
  });

  final String asset;
  final Widget? child;
  final double? height;
  final double radius;
  final bool fadeFromStart;
  final Alignment alignment;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry childAlignment;
  final int decodeWidth;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              asset,
              fit: BoxFit.cover,
              alignment: alignment,
              cacheWidth: decodeWidth,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: AppTheme.forestDeep),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: fadeFromStart
                      ? AlignmentDirectional.centerStart
                      : Alignment.topCenter,
                  end: fadeFromStart
                      ? AlignmentDirectional.centerEnd
                      : Alignment.bottomCenter,
                  colors: fadeFromStart
                      ? const [
                          Color(0xE6063A3D),
                          Color(0x99063A3D),
                          Color(0x1A063A3D),
                        ]
                      : const [
                          Color(0x1A063A3D),
                          Color(0x33063A3D),
                          Color(0xCC063A3D),
                        ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
            if (child != null)
              Padding(
                padding: padding,
                child: Align(alignment: childAlignment, child: child),
              ),
          ],
        ),
      ),
    );
  }
}

/// A product picture on a white tile.
///
/// Network images are cached and decoded at the slot size. A URL starting
/// with `asset:` loads a bundled image instead, used for the sample data in
/// demo mode and in screenshot tests.
class DsProductThumb extends StatelessWidget {
  const DsProductThumb({
    super.key,
    required this.imageUrl,
    this.size,
    this.radius = 14,
    this.fit = BoxFit.contain,
    this.fallbackIcon = Icons.local_grocery_store_outlined,
    this.padding = 4,
    this.semanticLabel,
  });

  final String imageUrl;

  /// Square size. Null fills the parent.
  final double? size;
  final double radius;
  final BoxFit fit;
  final IconData fallbackIcon;
  final double padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Icon(
        fallbackIcon,
        color: AppTheme.forestDeep.withValues(alpha: 0.7),
        size: 30,
      ),
    );
    final Widget image;
    if (imageUrl.startsWith('asset:')) {
      image = Image.asset(
        imageUrl.substring(6),
        fit: fit,
        cacheWidth: 360,
        errorBuilder: (_, _, _) => fallback,
      );
    } else if (imageUrl.isNotEmpty) {
      image = CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        memCacheWidth: 360,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, _) => const DsImagePlaceholder(),
        errorWidget: (_, _, _) => fallback,
      );
    } else {
      image = fallback;
    }
    return Semantics(
      image: true,
      label: semanticLabel,
      excludeSemantics: semanticLabel == null,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppTheme.line),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 3),
          child: image,
        ),
      ),
    );
  }
}

class DsImagePlaceholder extends StatelessWidget {
  const DsImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const ColoredBox(color: AppTheme.sand2);
}

/// A store logo in a white circle with a hairline ring.
class DsStoreLogo extends StatelessWidget {
  const DsStoreLogo(this.chain, {super.key, this.size = 44});

  final String chain;
  final double size;

  @override
  Widget build(BuildContext context) => StoreLogoAvatar(
    name: chain,
    color: AppTheme.forestDeep,
    size: size,
    padding: size * 0.12,
    borderColor: AppTheme.line,
  );
}

/// Round initial avatar for people (leaderboard, profile).
class DsAvatar extends StatelessWidget {
  const DsAvatar(
    this.name, {
    super.key,
    this.size = 44,
    this.photoUrl,
    this.tint,
  });

  final String name;
  final double size;
  final String? photoUrl;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().characters.first.toUpperCase();
    return Semantics(
      label: name,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tint ?? AppTheme.limeAccent,
          shape: BoxShape.circle,
          image: photoUrl != null && photoUrl!.isNotEmpty
              ? DecorationImage(
                  image: CachedNetworkImageProvider(photoUrl!, maxWidth: 160),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? null
            : Text(
                initial,
                style: AppFonts.display(
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
      ),
    );
  }
}

/// A centred illustration-free empty or error state: icon or photo, a title,
/// a sentence of help and up to two actions.
class DsEmptyState extends StatelessWidget {
  const DsEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.photoAsset,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.tone = DsEmptyTone.neutral,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final String? photoAsset;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final DsEmptyTone tone;

  @override
  Widget build(BuildContext context) {
    final iconColor = tone == DsEmptyTone.error
        ? AppTheme.redAccent
        : AppTheme.forestDeep;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (photoAsset != null)
                SizedBox(
                  width: 220,
                  height: 140,
                  child: DsPhotoBanner(
                    asset: photoAsset!,
                    height: 140,
                    childAlignment: Alignment.center,
                    child: icon == null
                        ? null
                        : Icon(icon, color: Colors.white, size: 44),
                  ),
                )
              else if (icon != null)
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 44, color: iconColor),
                ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppFonts.display(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppFonts.body(
                    fontSize: 16,
                    color: AppTheme.textLight,
                    height: 1.4,
                  ),
                ),
              ],
              if (primaryLabel != null) ...[
                const SizedBox(height: 20),
                DsButton(label: primaryLabel!, onPressed: onPrimary),
              ],
              if (secondaryLabel != null) ...[
                const SizedBox(height: 10),
                DsButton(
                  label: secondaryLabel!,
                  onPressed: onSecondary,
                  style: DsButtonStyle.secondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum DsEmptyTone { neutral, error }

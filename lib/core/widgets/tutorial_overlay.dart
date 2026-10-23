import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dealsouk/core/design/design.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({super.key});

  /// Bump this ONLY when a major new feature is added that warrants re-showing
  /// the tutorial to everyone. Users who've already seen version N won't be
  /// shown it again until this exceeds N — so it never nags after skip/done.
  static const int kTutorialVersion = 1;
  static const String _prefsKey = 'tutorial_seen_version';

  /// True if the user hasn't yet seen the current tutorial version.
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_prefsKey) ?? 0) < kTutorialVersion;
  }

  /// Records that the user has seen the current version (called on skip/done),
  /// so it won't appear again until [kTutorialVersion] is bumped.
  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, kTutorialVersion);
  }

  /// Shows the tutorial and marks it seen once dismissed (skip OR done).
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => const TutorialOverlay(),
    );
    await markSeen();
  }

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<_TutorialSlide> _buildSlides(AppLocalizations l) => [
    _TutorialSlide(
      title: l.tutorialCompareTitle,
      description: l.tutorialCompareDescription,
      photo: DsPhotos.shelf,
      icon: Icons.compare_arrows_rounded,
    ),
    _TutorialSlide(
      title: l.tutorialMapTitle,
      description: l.tutorialMapDescription,
      photo: DsPhotos.creek,
      icon: Icons.map_rounded,
    ),
    _TutorialSlide(
      title: l.tutorialAskTitle,
      description: l.tutorialAskDescription,
      photo: DsPhotos.market,
      icon: Icons.help_outline_rounded,
    ),
    _TutorialSlide(
      title: l.tutorialEarnTitle,
      description: l.tutorialEarnDescription,
      photo: DsPhotos.dunes,
      icon: Icons.card_giftcard_rounded,
    ),
    _TutorialSlide(
      title: l.tutorialCompeteTitle,
      description: l.tutorialCompeteDescription,
      photo: DsPhotos.burj,
      icon: Icons.emoji_events_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next(int count) {
    if (_currentPage < count - 1) {
      _pageController.nextPage(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _back() {
    _pageController.previousPage(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final slides = _buildSlides(l);
    final last = _currentPage == slides.length - 1;
    final wide = context.isMedium || context.isExpanded;

    final content = Column(
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: DsButton(
              label: l.tutorialSkip,
              style: DsButtonStyle.ghost,
              expanded: false,
              compact: true,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) =>
                _SlideView(slide: slides[i], index: i, total: slides.length),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: DsStepBar(total: slides.length, current: _currentPage),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Row(
            children: [
              if (_currentPage > 0) ...[
                Expanded(
                  child: DsButton(
                    label: l.tutorialBack,
                    style: DsButtonStyle.secondary,
                    onPressed: _back,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: DsButton(
                  label: last ? l.tutorialGetStarted : l.tutorialNext,
                  onPressed: () => _next(slides.length),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!wide) {
      return Dialog.fullscreen(
        backgroundColor: AppTheme.background,
        child: SafeArea(child: content),
      );
    }
    return Dialog(
      backgroundColor: AppTheme.background,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
        child: content,
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({
    required this.slide,
    required this.index,
    required this.total,
  });

  final _TutorialSlide slide;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, box) {
        // Short photo when the text is large or the screen is short, so the
        // copy always has room.
        final photoHeight = (box.maxHeight * 0.4).clamp(120.0, 340.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DsPhotoBanner(
                asset: slide.photo,
                height: photoHeight,
                radius: 20,
                childAlignment: AlignmentDirectional.bottomStart,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(slide.icon, color: AppTheme.forestDeep, size: 30),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l.tutorialStep(index + 1, total),
                style: AppFonts.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 6),
              Semantics(
                header: true,
                child: Text(
                  slide.title,
                  style: AppFonts.display(
                    fontSize: 26,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                slide.description,
                style: AppFonts.body(
                  fontSize: 17,
                  height: 1.45,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TutorialSlide {
  final String title;
  final String description;
  final String photo;
  final IconData icon;

  const _TutorialSlide({
    required this.title,
    required this.description,
    required this.photo,
    required this.icon,
  });
}

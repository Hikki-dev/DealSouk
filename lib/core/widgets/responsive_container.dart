import 'package:flutter/material.dart';
import 'package:dealsouk/core/theme/theme.dart';

/// A page scaffold for single-column screens (forms, sign-in, pushed detail
/// screens).
///
/// On phones the content fills the screen. On wider windows it is centred in
/// a column of at most [maxWidth] on the sand background, with no phone-shaped
/// frame. Screens that have a real multi-column desktop design lay themselves
/// out with `PageContainer` and `context.isExpanded` instead.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBody;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 640,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBody = false,
    // Kept so existing call sites compile; the phone frame is gone.
    @Deprecated('The phone-shaped frame was removed.')
    bool forcePhoneFrameOnWeb = true,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final body = width <= maxWidth
        ? child
        : Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          );
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      extendBody: extendBody,
      body: body,
    );
  }
}

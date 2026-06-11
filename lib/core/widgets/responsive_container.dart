import 'package:flutter/material.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final bool forcePhoneFrameOnWeb;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 640,
    this.forcePhoneFrameOnWeb = true,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;

    if (width <= maxWidth) {
      return Scaffold(
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        body: child,
      );
    }

    // Web/Desktop view: wrap in a centered "mock device" shell for premium preview
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Light grey outer desktop background
      body: Center(
        child: Container(
          width: maxWidth,
          margin: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Scaffold(
              appBar: appBar,
              floatingActionButton: floatingActionButton,
              bottomNavigationBar: bottomNavigationBar,
              body: child,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'core/router/router.dart';
import 'core/theme/theme.dart';

class DealSoukApp extends StatelessWidget {
  const DealSoukApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DealSouk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scrollBehavior: const DealSoukScrollBehavior(),
      routerConfig: appRouter,
    );
  }
}

class DealSoukScrollBehavior extends MaterialScrollBehavior {
  const DealSoukScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'core/router/router.dart';
import 'core/state/state.dart';
import 'core/theme/theme.dart';
import 'core/services/fcm_service.dart';

class DealSoukApp extends ConsumerStatefulWidget {
  const DealSoukApp({super.key});

  @override
  ConsumerState<DealSoukApp> createState() => _DealSoukAppState();
}

class _DealSoukAppState extends ConsumerState<DealSoukApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Initialize FCM after the first frame so context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fcmService.initialize(
        onForegroundMessage: (msg) {
          final ctx = _navigatorKey.currentContext;
          if (ctx != null) showFcmBanner(ctx, msg);
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'DealSouk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scrollBehavior: const DealSoukScrollBehavior(),
      routerConfig: ref.watch(routerProvider),
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
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

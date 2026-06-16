import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/l10n/app_localizations.dart';
import 'package:dealsouk/app/router.dart';
import 'package:dealsouk/core/localization/locale_provider.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/network/fcm_service.dart';
import 'package:dealsouk/core/network/system_status_service.dart';
import 'package:dealsouk/features/requests/presentation/requests_providers.dart';
import 'package:dealsouk/features/tokens/presentation/tokens_providers.dart';

class DealSoukApp extends ConsumerStatefulWidget {
  const DealSoukApp({super.key});

  @override
  ConsumerState<DealSoukApp> createState() => _DealSoukAppState();
}

class _DealSoukAppState extends ConsumerState<DealSoukApp> {
  @override
  void initState() {
    super.initState();
    // Initialize FCM after the first frame so context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fcmService.initialize(
        onForegroundMessage: (msg) {
          _refreshForPushEvent(msg.data['type']);
          final ctx = rootNavigatorKey.currentContext;
          if (ctx != null) showFcmBanner(ctx, msg);
        },
      );
    });
  }

  void _refreshForPushEvent(String? type) {
    switch (type) {
      case 'request_fulfilled':
        ref.read(priceRequestsProvider.notifier).fetchBoard();
        ref.read(myRequestsProvider.notifier).fetchMyRequests();
        ref.read(userTransactionsProvider.notifier).fetch();
        break;
      case 'submission_approved':
        ref.read(userTransactionsProvider.notifier).fetch();
        ref.read(badgesProvider.notifier).checkAndUnlock('submission_approved');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final systemStatus = ref.watch(systemStatusProvider);

    return MaterialApp.router(
      title: 'DealSouk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scrollBehavior: const DealSoukScrollBehavior(),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        final status = systemStatus.asData?.value;
        if (status?.maintenance != true) return child ?? const SizedBox();
        return Column(
          children: [
            Material(
              color: AppTheme.amberAccent,
              child: SafeArea(
                bottom: false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    status!.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF3E2F00),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: child ?? const SizedBox()),
          ],
        );
      },
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
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

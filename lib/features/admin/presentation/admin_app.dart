import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/features/auth/presentation/auth_providers.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/features/admin/presentation/admin_screen.dart';
import 'package:dealsouk/features/auth/presentation/unauthorized_screen.dart';
import 'package:dealsouk/features/auth/presentation/welcome_screen.dart';
import 'package:dealsouk/l10n/app_localizations.dart';
import 'package:dealsouk/core/localization/locale_provider.dart';

/// Standalone admin web app — launched via:
///   flutter build web --dart-define=ADMIN_MODE=true
///
/// Routes straight to AdminScreen after Firebase auth.
/// Deploy to a separate Vercel project (e.g. dealsouk-admin.vercel.app).
class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'DealSouk Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: switch (auth.status) {
        AuthStatus.unknown => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        AuthStatus.authenticated when auth.isAdmin => const AdminScreen(),
        AuthStatus.authenticated => const UnauthorizedScreen(),
        _ => const WelcomeScreen(),
      },
    );
  }
}

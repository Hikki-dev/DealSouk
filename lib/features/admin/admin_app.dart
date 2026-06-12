import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/auth_provider.dart';
import '../../core/theme/theme.dart';
import 'admin_screen.dart';
import '../auth/welcome_screen.dart';

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

    return MaterialApp(
      title: 'DealSouk Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: switch (auth.status) {
        AuthStatus.unknown => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        AuthStatus.authenticated when auth.isAdmin => const AdminScreen(),
        AuthStatus.authenticated => const Scaffold(
            body: Center(
              child: Text(
                'Access denied — admin account required.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        _ => const WelcomeScreen(),
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/core/design/design.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/features/auth/presentation/auth_providers.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

class UnauthorizedScreen extends ConsumerWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: DsEmptyState(
          icon: Icons.lock_outline_rounded,
          title: l.unauthorizedTitle,
          message: l.unauthorizedBody,
          primaryLabel: l.unauthorizedAction,
          onPrimary: () async {
            // Sign out so the user can re-authenticate with the correct
            // admin account. go('/welcome') works for both admin and shopper
            // builds, unlike '/' which is inside the shell and unreachable
            // from the standalone /unauthorized route.
            await ref.read(authProvider.notifier).signOut();
            if (context.mounted) context.go('/welcome');
          },
        ),
      ),
    );
  }
}

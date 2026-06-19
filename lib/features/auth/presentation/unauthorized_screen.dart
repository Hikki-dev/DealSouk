import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/features/auth/presentation/auth_providers.dart';

class UnauthorizedScreen extends ConsumerWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: AppTheme.forestDeep,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unauthorized',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'This area is only available to admin users.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  // Sign out so the user can re-authenticate with the correct
                  // admin account. go('/welcome') is safe for both admin-mode
                  // and shopper builds — unlike '/' which lives inside the
                  // ShellRoute and is unreachable from the standalone /unauthorized route.
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) context.go('/welcome');
                },
                child: const Text('Sign in with a different account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

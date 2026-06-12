import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/core/theme/theme.dart';

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                onPressed: () {
                  final router = GoRouter.maybeOf(context);
                  if (router != null) {
                    router.go('/');
                    return;
                  }
                  Navigator.of(context).maybePop();
                },
                child: const Text('Back to DealSouk'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

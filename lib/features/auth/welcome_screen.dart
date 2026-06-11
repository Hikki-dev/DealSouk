import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/responsive_container.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Widget _valuePillar(IconData icon, String label, ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.65),
            height: 1.3,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveContainer(
      child: Stack(
        children: [
          // Background Gradient decoration
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.05),
                  theme.colorScheme.primary.withOpacity(0.15),
                  theme.colorScheme.primary.withOpacity(0.02),
                ],
              ),
            ),
          ),
          
          // Background design elements (Dubai skyline abstract pattern)
          Positioned(
            bottom: -50,
            left: -50,
            right: -50,
            child: Opacity(
              opacity: 0.08,
              child: Image.network(
                'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?q=80&w=1000&auto=format&fit=crop',
                height: 350,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(height: 350),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  
                  // App Icon & Brand Logo
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // App Name
                  Text(
                    'DealSouk',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      letterSpacing: -0.5,
                      fontSize: 40,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Tagline
                  Text(
                    'Save money on groceries in Dubai',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Three value pillars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _valuePillar(Icons.compare_arrows_rounded, 'Compare\nPrices', theme),
                      const SizedBox(width: 20),
                      _valuePillar(Icons.bolt, 'Earn\nTokens', theme),
                      const SizedBox(width: 20),
                      _valuePillar(Icons.savings_outlined, 'Save\nMoney', theme),
                    ],
                  ),

                  const Spacer(flex: 2),

                  // Demo Banner
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, color: theme.colorScheme.secondary, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Demo Mode: Click any login option to enter the fully interactive prototype.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Login/Authentication buttons
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                    ),
                    child: const Text('Continue as Demo User'),
                  ),
                  const SizedBox(height: 12),
                  
                  OutlinedButton.icon(
                    onPressed: () => context.go('/'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 28, color: Colors.red),
                    label: const Text('Sign in with Google'),
                  ),
                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: () => context.go('/'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                    icon: const Icon(Icons.phone_iphone_rounded, size: 20, color: Colors.blue),
                    label: const Text('Sign in with Phone'),
                  ),
                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: () => context.go('/'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                    icon: const Icon(Icons.apple, size: 22, color: Colors.black87),
                    label: const Text('Sign in with Apple'),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Footer terms/info
                  Text(
                    'By signing in, you agree to crowd-source grocery data in Dubai.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

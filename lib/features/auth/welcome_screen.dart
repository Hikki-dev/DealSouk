import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/souk_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: Container(
        color: AppTheme.forestDeep,
        child: Stack(
          children: [
            // Faint Dubai skyline at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: 0.10,
                child: Image.network(
                  'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?q=80&w=1000&auto=format&fit=crop',
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(height: 300),
                ),
              ),
            ),

            // Cream scallop trim at the very bottom — brand signature
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipPath(
                clipper: const ScallopClipper.up(scallopRadius: 8),
                child: Container(height: 18, color: AppTheme.cream),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),

                    // Logo mark
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.limeAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.limeAccent.withOpacity(0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
                          size: 44,
                          color: AppTheme.forestDeep,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'DealSouk',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        fontSize: 40,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Save money on groceries in Dubai',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Three value pillars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ValuePillar(icon: Icons.compare_arrows_rounded, label: 'Compare\nPrices'),
                        SizedBox(width: 20),
                        _ValuePillar(icon: Icons.bolt, label: 'Earn\nTokens'),
                        SizedBox(width: 20),
                        _ValuePillar(icon: Icons.savings_outlined, label: 'Save\nMoney'),
                      ],
                    ),

                    const Spacer(flex: 2),

                    // Demo banner
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.limeAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.limeAccent.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.limeAccent, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Demo Mode: Click any login option to enter the fully interactive prototype.',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.limeAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Primary CTA — lime pill
                    GestureDetector(
                      onTap: () => context.go('/'),
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppTheme.limeAccent,
                          borderRadius: BorderRadius.circular(27),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.limeAccent.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Continue as Demo User',
                            style: TextStyle(
                              color: AppTheme.forestDeep,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _SignInButton(
                      icon: Icons.g_mobiledata_rounded,
                      iconSize: 28,
                      label: 'Sign in with Google',
                      onTap: () => context.go('/'),
                    ),
                    const SizedBox(height: 10),
                    _SignInButton(
                      icon: Icons.phone_iphone_rounded,
                      label: 'Sign in with Phone',
                      onTap: () => context.go('/'),
                    ),
                    const SizedBox(height: 10),
                    _SignInButton(
                      icon: Icons.apple,
                      iconSize: 22,
                      label: 'Sign in with Apple',
                      onTap: () => context.go('/'),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'By signing in, you agree to crowd-source grocery data in Dubai.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValuePillar extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ValuePillar({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Icon(icon, color: AppTheme.limeAccent, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.75),
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _SignInButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final String label;
  final VoidCallback onTap;

  const _SignInButton({
    required this.icon,
    this.iconSize = 20,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

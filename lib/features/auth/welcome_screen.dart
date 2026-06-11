import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/souk_widgets.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isAdminMode = false;

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A2616), // Extra deep forest green
              Color(0xFF0F3820), // Deep premium green
              Color(0xFF144D2B), // Rich dark green
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: WelcomeGridPatternPainter(),
              ),
            ),
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
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(height: 300),
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
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            _isAdminMode ? Icons.gavel_rounded : Icons.insights_rounded,
                            key: ValueKey<bool>(_isAdminMode),
                            size: 44,
                            color: AppTheme.forestDeep,
                          ),
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

                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _isAdminMode
                            ? 'Review crowd-sourced grocery prices'
                            : 'Save money on groceries in Dubai',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Segmented Mode Toggle (User vs Admin Selector)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isAdminMode = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_isAdminMode ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    'Customer Mode',
                                    style: TextStyle(
                                      color: !_isAdminMode ? AppTheme.forestDeep : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isAdminMode = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isAdminMode ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    'Admin Moderator',
                                    style: TextStyle(
                                      color: _isAdminMode ? AppTheme.forestDeep : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Three value pillars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _isAdminMode
                          ? [
                              const _ValuePillar(
                                icon: Icons.rate_review_rounded,
                                label: 'Audit\nQueue',
                              ),
                              const SizedBox(width: 20),
                              const _ValuePillar(
                                icon: Icons.security_rounded,
                                label: 'Fraud\nFilter',
                              ),
                              const SizedBox(width: 20),
                              const _ValuePillar(
                                icon: Icons.token_rounded,
                                label: 'Issue\nTokens',
                              ),
                            ]
                          : [
                              const _ValuePillar(
                                icon: Icons.compare_arrows_rounded,
                                label: 'Compare\nPrices',
                              ),
                              const SizedBox(width: 20),
                              const _ValuePillar(
                                icon: Icons.bolt,
                                label: 'Earn\nTokens',
                              ),
                              const SizedBox(width: 20),
                              const _ValuePillar(
                                icon: Icons.savings_outlined,
                                label: 'Save\nMoney',
                              ),
                            ],
                    ),

                    const Spacer(flex: 2),

                    // Value banner
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                _isAdminMode
                                    ? 'Moderator Panel: Verify receipts and shelf prices.'
                                    : 'Live Dubai prices. Earn tokens.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Primary CTA — high contrast white pill
                    GestureDetector(
                      onTap: () => context.go(_isAdminMode ? '/admin' : '/'),
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(27),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _isAdminMode ? 'Enter Admin Dashboard' : 'Enter DealSouk Demo',
                            style: const TextStyle(
                              color: AppTheme.forestDeep,
                              fontSize: 16.5,
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
                      label: _isAdminMode ? 'Sign in as Admin with Google' : 'Sign in with Google',
                      onTap: () => context.go(_isAdminMode ? '/admin' : '/'),
                    ),
                    const SizedBox(height: 10),
                    _SignInButton(
                      icon: _isAdminMode ? Icons.key_rounded : Icons.phone_iphone_rounded,
                      label: _isAdminMode ? 'Sign in with Keycard ID' : 'Sign in with Phone',
                      onTap: () => context.go(_isAdminMode ? '/admin' : '/'),
                    ),
                    const SizedBox(height: 10),
                    _SignInButton(
                      icon: Icons.apple,
                      iconSize: 22,
                      label: _isAdminMode ? 'Sign in as Admin with Apple' : 'Sign in with Apple',
                      onTap: () => context.go(_isAdminMode ? '/admin' : '/'),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      _isAdminMode
                          ? 'Moderator console permissions apply.'
                          : 'Crowd-sourced grocery data for Dubai.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
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
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.85),
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
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1.3,
          ),
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

class WelcomeGridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double gridSize = 32.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

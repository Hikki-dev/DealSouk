import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/auth_provider.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/souk_widgets.dart';
import '../../core/widgets/tutorial_overlay.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isAdminMode = false;
  bool _loading = false;

  // Phone OTP state
  bool _showPhoneInput = false;
  bool _showOtpInput = false;
  String _verificationId = '';
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogle() async {
    setState(() => _loading = true);
    await ref.read(authProvider.notifier).signInWithGoogle();
    if (mounted) setState(() => _loading = false);
    _showError();
  }

  Future<void> _handleApple() async {
    setState(() => _loading = true);
    await ref.read(authProvider.notifier).signInWithApple();
    if (mounted) setState(() => _loading = false);
    _showError();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    setState(() => _loading = true);
    final id = await ref.read(authProvider.notifier).sendOtp(phone);
    if (mounted) {
      setState(() {
        _loading = false;
        if (id != null) {
          _verificationId = id;
          _showOtpInput = true;
        }
      });
      _showError();
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    await ref.read(authProvider.notifier).verifyOtp(_verificationId, code);
    if (mounted) setState(() => _loading = false);
  }

  void _showError() {
    final error = ref.read(authProvider).error;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5D2E12), Color(0xFF9A5524), Color(0xFFE99A4A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: WelcomeGridPatternPainter()),
            ),
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),

                      // Logo
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
                              _isAdminMode
                                  ? Icons.gavel_rounded
                                  : Icons.insights_rounded,
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
                              : 'Find nearby grocery prices in Dubai',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Mode toggle
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
                            _modeTab(
                              'Customer Mode',
                              !_isAdminMode,
                              () => setState(() {
                                _isAdminMode = false;
                                _showPhoneInput = false;
                                _showOtpInput = false;
                              }),
                            ),
                            _modeTab(
                              'Admin Moderator',
                              _isAdminMode,
                              () => setState(() {
                                _isAdminMode = true;
                                _showPhoneInput = false;
                                _showOtpInput = false;
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Value pillars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _isAdminMode
                            ? const [
                                _ValuePillar(
                                  icon: Icons.rate_review_rounded,
                                  label: 'Audit\nQueue',
                                ),
                                SizedBox(width: 20),
                                _ValuePillar(
                                  icon: Icons.security_rounded,
                                  label: 'Fraud\nFilter',
                                ),
                                SizedBox(width: 20),
                                _ValuePillar(
                                  icon: Icons.token_rounded,
                                  label: 'Issue\nTokens',
                                ),
                              ]
                            : const [
                                _ValuePillar(
                                  icon: Icons.compare_arrows_rounded,
                                  label: 'Compare\nPrices',
                                ),
                                SizedBox(width: 20),
                                _ValuePillar(
                                  icon: Icons.place_rounded,
                                  label: 'Nearby\nStores',
                                ),
                                SizedBox(width: 20),
                                _ValuePillar(
                                  icon: Icons.help_outline_rounded,
                                  label: 'Ask\nPrices',
                                ),
                              ],
                      ),

                      const SizedBox(height: 32),

                      // Info banner
                      GestureDetector(
                        onTap: () {
                          if (!_isAdminMode) TutorialOverlay.show(context);
                        },
                        child: Container(
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
                                child: Text(
                                  _isAdminMode
                                      ? 'Moderator Panel: Verify receipts and shelf prices.'
                                      : 'No ordering here. Just check prices before you go.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Phone input (shown when user taps Sign in with Phone)
                      if (_showPhoneInput && !_showOtpInput) ...[
                        _PhoneInputField(
                          controller: _phoneController,
                          onSend: _sendOtp,
                          loading: _loading,
                          onCancel: () =>
                              setState(() => _showPhoneInput = false),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // OTP input
                      if (_showOtpInput) ...[
                        _OtpInputField(
                          controller: _otpController,
                          phone: _phoneController.text.trim(),
                          onVerify: _verifyOtp,
                          loading: _loading,
                          onResend: _sendOtp,
                          onCancel: () => setState(() {
                            _showOtpInput = false;
                            _showPhoneInput = false;
                            _otpController.clear();
                          }),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Primary CTA
                      if (!_showPhoneInput && !_showOtpInput) ...[
                        _PrimaryCta(
                          label: _isAdminMode
                              ? 'Enter Admin Dashboard'
                              : 'Continue with Google',
                          loading: _loading,
                          onTap: _handleGoogle,
                        ),
                        const SizedBox(height: 12),

                        if (!_isAdminMode) ...[
                          _SignInButton(
                            icon: Icons.phone_iphone_rounded,
                            label: 'Sign in with Phone',
                            onTap: () => setState(() => _showPhoneInput = true),
                          ),
                          const SizedBox(height: 10),
                          _SignInButton(
                            icon: Icons.apple,
                            iconSize: 22,
                            label: 'Sign in with Apple',
                            onTap: _handleApple,
                          ),
                          const SizedBox(height: 10),
                          _SignInButton(
                            icon: Icons.visibility_outlined,
                            label: 'Browse as Guest',
                            onTap: () => ref
                                .read(authProvider.notifier)
                                .continueAsGuest(),
                          ),
                        ] else ...[
                          _SignInButton(
                            icon: Icons.phone_iphone_rounded,
                            label: 'Sign in with Phone',
                            onTap: () => setState(() => _showPhoneInput = true),
                          ),
                          const SizedBox(height: 10),
                          _SignInButton(
                            icon: Icons.apple,
                            iconSize: 22,
                            label: 'Sign in with Apple',
                            onTap: _handleApple,
                          ),
                        ],
                      ],

                      const SizedBox(height: 20),
                      Text(
                        _isAdminMode
                            ? 'Moderator console permissions apply.'
                            : 'Crowd-sourced grocery prices for Dubai.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),

            // Loading overlay
            if (_loading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _modeTab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? AppTheme.forestDeep : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Phone input ──────────────────────────────────────────────────────────────

class _PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final bool loading;

  const _PhoneInputField({
    required this.controller,
    required this.onSend,
    required this.onCancel,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: '+971 50 000 0000',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            prefixIcon: const Icon(Icons.phone, color: Colors.white54),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onCancel,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _PrimaryCta(
                label: 'Send Code',
                loading: loading,
                onTap: onSend,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── OTP input ────────────────────────────────────────────────────────────────

class _OtpInputField extends StatelessWidget {
  final TextEditingController controller;
  final String phone;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onCancel;
  final bool loading;

  const _OtpInputField({
    required this.controller,
    required this.phone,
    required this.onVerify,
    required this.onResend,
    required this.onCancel,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter the 6-digit code sent to $phone',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '------',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              letterSpacing: 8,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onCancel,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _PrimaryCta(
                label: 'Verify',
                loading: loading,
                onTap: onVerify,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onResend,
          child: Text(
            'Resend code',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white38,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _PrimaryCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool loading;

  const _PrimaryCta({
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
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
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.forestDeep,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.forestDeep,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
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

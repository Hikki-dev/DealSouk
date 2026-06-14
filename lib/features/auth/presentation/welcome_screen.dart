import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/features/auth/presentation/auth_providers.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/widgets/responsive_container.dart';
import 'package:dealsouk/core/widgets/souk_widgets.dart';
import 'package:dealsouk/core/widgets/tutorial_overlay.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isAdminMode = const bool.fromEnvironment(
    'ADMIN_MODE',
    defaultValue: false,
  );
  bool _loading = false;

  // Dev mode & privacy
  int _logoTaps = 0;
  bool _showAdminTab = false;
  bool _agreeToPrivacy = false;

  // Phone OTP state
  bool _showPhoneInput = false;
  bool _showOtpInput = false;
  String _verificationId = '';
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  CountryInfo _selectedCountry = _supportedCountries.first;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogle() async {
    final l = AppLocalizations.of(context)!;
    if (!_isAdminMode && !_agreeToPrivacy) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.welcomePrivacyConsentRequired)));
      return;
    }
    setState(() => _loading = true);
    await ref.read(authProvider.notifier).signInWithGoogle();
    if (mounted) setState(() => _loading = false);
    _showError();
  }

  Future<void> _handleApple() async {
    final l = AppLocalizations.of(context)!;
    if (!_isAdminMode && !_agreeToPrivacy) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.welcomePrivacyConsentRequired)));
      return;
    }
    setState(() => _loading = true);
    await ref.read(authProvider.notifier).signInWithApple();
    if (mounted) setState(() => _loading = false);
    _showError();
  }

  Future<void> _sendOtp() async {
    String cleanPhone = _phoneController.text.trim();
    while (cleanPhone.startsWith('0')) {
      cleanPhone = cleanPhone.substring(1);
    }
    if (cleanPhone.isEmpty) return;

    if (cleanPhone.length < _selectedCountry.minLength ||
        cleanPhone.length > _selectedCountry.maxLength) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.welcomeInvalidPhoneNumber(
              _selectedCountry.minLength,
              _selectedCountry.name,
            ),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final finalPhoneNumber = _selectedCountry.code + cleanPhone;

    setState(() => _loading = true);
    final id = await ref.read(authProvider.notifier).sendOtp(finalPhoneNumber);
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

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final l = AppLocalizations.of(context)!;
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.welcomeSelectCountry,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _supportedCountries.length,
                    itemBuilder: (context, index) {
                      final country = _supportedCountries[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Text(
                          country.flag,
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(
                          country.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        trailing: Text(
                          country.code,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedCountry = country;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    final success = await ref
        .read(authProvider.notifier)
        .verifyOtp(_verificationId, code);
    if (mounted) {
      setState(() => _loading = false);
      if (!success) {
        _showError();
      }
    }
  }

  void _showError() {
    final error = ref.read(authProvider).error;
    if (error != null && mounted) {
      final isAr = AppLocalizations.of(context)!.localeName == 'ar';

      String displayError = error;
      if (error == 'Invalid code. Please try again.') {
        displayError = isAr
            ? 'الرمز الذي أدخلته غير صحيح. يرجى المحاولة مرة أخرى.'
            : 'The OTP code you entered is incorrect. Please check and try again.';
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFC62828)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'خطأ في التحقق' : 'Verification Error',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayError,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
                        child: GestureDetector(
                          onTap: () {
                            if (const bool.fromEnvironment(
                              'ADMIN_MODE',
                              defaultValue: false,
                            )) {
                              return;
                            }
                            setState(() {
                              _logoTaps++;
                              if (_logoTaps >= 5) {
                                _showAdminTab = !_showAdminTab;
                                _logoTaps = 0;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _showAdminTab
                                          ? l.welcomeModeratorToggleEnabled
                                          : l.welcomeModeratorToggleDisabled,
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            });
                          },
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
                              ? l.welcomeTaglineAdmin
                              : l.welcomeTaglineCustomer,
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
                      if (_showAdminTab) ...[
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
                                l.welcomeCustomerModeTab,
                                !_isAdminMode,
                                () => setState(() {
                                  _isAdminMode = false;
                                  _showPhoneInput = false;
                                  _showOtpInput = false;
                                }),
                              ),
                              _modeTab(
                                l.welcomeAdminModeratorTab,
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
                      ],

                      // Value pillars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _isAdminMode
                            ? [
                                _ValuePillar(
                                  icon: Icons.rate_review_rounded,
                                  label: l.welcomePillarAuditQueue,
                                ),
                                const SizedBox(width: 20),
                                _ValuePillar(
                                  icon: Icons.security_rounded,
                                  label: l.welcomePillarFraudFilter,
                                ),
                                const SizedBox(width: 20),
                                _ValuePillar(
                                  icon: Icons.token_rounded,
                                  label: l.welcomePillarIssueTokens,
                                ),
                              ]
                            : [
                                _ValuePillar(
                                  icon: Icons.compare_arrows_rounded,
                                  label: l.welcomePillarComparePrices,
                                ),
                                const SizedBox(width: 20),
                                _ValuePillar(
                                  icon: Icons.place_rounded,
                                  label: l.welcomePillarFindNearby,
                                ),
                                const SizedBox(width: 20),
                                _ValuePillar(
                                  icon: Icons.help_outline_rounded,
                                  label: l.welcomePillarRequestPrice,
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
                                      ? l.welcomeInfoBannerAdmin
                                      : l.welcomeInfoBannerCustomer,
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
                          selectedCountry: _selectedCountry,
                          onCountryTap: _showCountryPicker,
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

                      // Privacy consent checkbox
                      if (!_isAdminMode &&
                          !_showPhoneInput &&
                          !_showOtpInput) ...[
                        Row(
                          children: [
                            Checkbox(
                              value: _agreeToPrivacy,
                              onChanged: (val) => setState(() {
                                _agreeToPrivacy = val ?? false;
                              }),
                              activeColor: Colors.white,
                              checkColor: AppTheme.forestDeep,
                              side: const BorderSide(
                                color: Colors.white70,
                                width: 1.5,
                              ),
                            ),
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    l.welcomePrivacyConsentPrefix,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.push('/privacy'),
                                    child: Text(
                                      l.welcomePrivacyPolicyLink,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w900,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    l.welcomePrivacyConsentSuffix,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Primary CTA
                      if (!_showPhoneInput && !_showOtpInput) ...[
                        _PrimaryCta(
                          label: l.welcomeContinueWithGoogle,
                          loading: _loading,
                          onTap: _handleGoogle,
                        ),
                        const SizedBox(height: 12),

                        if (!_isAdminMode) ...[
                          _SignInButton(
                            icon: Icons.phone_iphone_rounded,
                            label: l.welcomeSignInWithPhone,
                            onTap: () {
                              if (!_agreeToPrivacy) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l.welcomePrivacyConsentRequired,
                                    ),
                                  ),
                                );
                                return;
                              }
                              setState(() => _showPhoneInput = true);
                            },
                          ),
                          const SizedBox(height: 10),
                          _SignInButton(
                            icon: Icons.apple,
                            iconSize: 22,
                            label: l.welcomeSignInWithApple,
                            onTap: _handleApple,
                          ),
                          const SizedBox(height: 10),
                          _SignInButton(
                            icon: Icons.visibility_outlined,
                            label: l.welcomeBrowseAsGuest,
                            onTap: () {
                              if (!_agreeToPrivacy) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l.welcomePrivacyConsentRequired,
                                    ),
                                  ),
                                );
                                return;
                              }
                              ref.read(authProvider.notifier).continueAsGuest();
                            },
                          ),
                        ] else ...[
                          _SignInButton(
                            icon: Icons.phone_iphone_rounded,
                            label: l.welcomeSignInWithPhone,
                            onTap: () => setState(() => _showPhoneInput = true),
                          ),
                          const SizedBox(height: 10),
                          _SignInButton(
                            icon: Icons.apple,
                            iconSize: 22,
                            label: l.welcomeSignInWithApple,
                            onTap: _handleApple,
                          ),
                        ],
                      ],

                      const SizedBox(height: 20),
                      Text(
                        _isAdminMode
                            ? l.welcomeFooterAdmin
                            : l.welcomeFooterCustomer,
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
  final CountryInfo selectedCountry;
  final VoidCallback onCountryTap;

  const _PhoneInputField({
    required this.controller,
    required this.onSend,
    required this.onCancel,
    required this.loading,
    required this.selectedCountry,
    required this.onCountryTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onCountryTap,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedCountry.flag,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      selectedCountry.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(selectedCountry.maxLength),
                ],
                autofocus: true,
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: selectedCountry.formatHint,
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppTheme.forestDeep,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
                  child: Center(
                    child: Text(
                      l.welcomeCancel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _PrimaryCta(
                label: l.welcomeSendCode,
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
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.welcomeOtpPrompt(phone),
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
            color: AppTheme.textDark,
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            counterText: '',
            hintText: '------',
            hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 8),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppTheme.forestDeep,
                width: 1.5,
              ),
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
                  child: Center(
                    child: Text(
                      l.welcomeCancel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _PrimaryCta(
                label: l.welcomeVerify,
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
            l.welcomeResendCode,
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
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                      height: 20,
                      width: 20,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(width: 20, height: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.forestDeep,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
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

class CountryInfo {
  final String name;
  final String flag;
  final String code;
  final int minLength;
  final int maxLength;
  final String formatHint;

  const CountryInfo({
    required this.name,
    required this.flag,
    required this.code,
    required this.minLength,
    required this.maxLength,
    required this.formatHint,
  });
}

const List<CountryInfo> _supportedCountries = [
  CountryInfo(
    name: 'United Arab Emirates',
    flag: '🇦🇪',
    code: '+971',
    minLength: 9,
    maxLength: 9,
    formatHint: '50 123 4567',
  ),
  CountryInfo(
    name: 'Saudi Arabia',
    flag: '🇸🇦',
    code: '+966',
    minLength: 9,
    maxLength: 9,
    formatHint: '50 123 4567',
  ),
  CountryInfo(
    name: 'Oman',
    flag: '🇴🇲',
    code: '+968',
    minLength: 8,
    maxLength: 8,
    formatHint: '9123 4567',
  ),
  CountryInfo(
    name: 'Kuwait',
    flag: '🇰🇼',
    code: '+965',
    minLength: 8,
    maxLength: 8,
    formatHint: '5123 4567',
  ),
  CountryInfo(
    name: 'Bahrain',
    flag: '🇧🇭',
    code: '+973',
    minLength: 8,
    maxLength: 8,
    formatHint: '3123 4567',
  ),
  CountryInfo(
    name: 'India',
    flag: '🇮🇳',
    code: '+91',
    minLength: 10,
    maxLength: 10,
    formatHint: '98765 43210',
  ),
  CountryInfo(
    name: 'United Kingdom',
    flag: '🇬🇧',
    code: '+44',
    minLength: 10,
    maxLength: 10,
    formatHint: '7123 456789',
  ),
  CountryInfo(
    name: 'United States',
    flag: '🇺🇸',
    code: '+1',
    minLength: 10,
    maxLength: 10,
    formatHint: '201 555 0123',
  ),
];

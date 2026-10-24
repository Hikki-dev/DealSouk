import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/features/auth/presentation/auth_providers.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/design/design.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

const bool _adminBuild = bool.fromEnvironment(
  'ADMIN_MODE',
  defaultValue: false,
);

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final bool _isAdminMode = _adminBuild;
  bool _loading = false;

  // Dev mode & privacy
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
                    color: AppTheme.ink,
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
                            color: AppTheme.ink,
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
    if (error == null || !mounted) return;
    final isAr = AppLocalizations.of(context)!.localeName == 'ar';
    var message = error;
    if (error == 'Invalid code. Please try again.') {
      message = isAr
          ? 'الرمز الذي أدخلته غير صحيح. يرجى المحاولة مرة أخرى.'
          : 'The code you entered is incorrect. Please check and try again.';
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.badText,
          content: Text(
            message,
            style: AppFonts.body(fontSize: 15, color: Colors.white),
          ),
        ),
      );
  }

  void _needConsent() {
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.welcomePrivacyConsentRequired)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final benefits = _isAdminMode
        ? [
            (Icons.rate_review_rounded, l.welcomePillarAuditQueue),
            (Icons.security_rounded, l.welcomePillarFraudFilter),
            (Icons.token_rounded, l.welcomePillarIssueTokens),
          ]
        : [
            (Icons.compare_arrows_rounded, l.welcomePillarComparePrices),
            (Icons.place_rounded, l.welcomePillarFindNearby),
            (Icons.help_outline_rounded, l.welcomePillarRequestPrice),
          ];
    final tagline = _isAdminMode
        ? l.welcomeTaglineAdmin
        : l.welcomeTaglineCustomer;

    final body = context.isExpanded
        ? Row(
            children: [
              Expanded(
                flex: 11,
                child: _HeroPanel(
                  tagline: tagline,
                  benefits: benefits,
                  isAdmin: _isAdminMode,
                ),
              ),
              Expanded(
                flex: 9,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _buildForm(l),
                    ),
                  ),
                ),
              ),
            ],
          )
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 280,
                  child: _HeroPanel(
                    tagline: tagline,
                    benefits: const [],
                    isAdmin: _isAdminMode,
                    compact: true,
                  ),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                      child: _buildForm(l),
                    ),
                  ),
                ),
              ],
            ),
          );

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Positioned.fill(child: body),
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
    );
  }

  Widget _buildForm(AppLocalizations l) {
    final inPhoneFlow = _showPhoneInput || _showOtpInput;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            _isAdminMode ? l.welcomeAdminModeratorTab : 'DealSouk',
            style: AppFonts.display(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isAdminMode ? l.welcomeInfoBannerAdmin : l.welcomeInfoBannerCustomer,
          style: AppFonts.body(
            fontSize: 16,
            height: 1.4,
            color: AppTheme.textLight,
          ),
        ),
        const SizedBox(height: 20),
        if (_showPhoneInput && !_showOtpInput)
          _PhoneInputField(
            controller: _phoneController,
            onSend: _sendOtp,
            loading: _loading,
            onCancel: () => setState(() => _showPhoneInput = false),
            selectedCountry: _selectedCountry,
            onCountryTap: _showCountryPicker,
          ),
        if (_showOtpInput)
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
        if (!inPhoneFlow) ...[
          if (!_isAdminMode) ...[
            _ConsentRow(
              value: _agreeToPrivacy,
              onChanged: (v) => setState(() => _agreeToPrivacy = v),
              onPolicy: () => context.push('/privacy'),
            ),
            const SizedBox(height: 16),
          ],
          DsButton(
            label: l.welcomeContinueWithGoogle,
            style: DsButtonStyle.google,
            leading: Image.asset(
              'assets/images/google_g.png',
              width: 22,
              height: 22,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            ),
            loading: _loading,
            onPressed: _handleGoogle,
          ),
          const SizedBox(height: 12),
          DsButton(
            label: l.welcomeSignInWithApple,
            style: DsButtonStyle.apple,
            icon: Icons.apple,
            onPressed: _handleApple,
          ),
          const SizedBox(height: 12),
          DsButton(
            label: l.welcomeSignInWithPhone,
            style: DsButtonStyle.secondary,
            icon: Icons.phone_iphone_rounded,
            onPressed: () {
              if (!_isAdminMode && !_agreeToPrivacy) return _needConsent();
              setState(() => _showPhoneInput = true);
            },
          ),
          if (!_isAdminMode) ...[
            const SizedBox(height: 4),
            DsButton(
              label: l.welcomeBrowseAsGuest,
              style: DsButtonStyle.ghost,
              onPressed: () {
                if (!_agreeToPrivacy) return _needConsent();
                ref.read(authProvider.notifier).continueAsGuest();
              },
            ),
          ],
        ],
        const SizedBox(height: 20),
        Text(
          _isAdminMode ? l.welcomeFooterAdmin : l.welcomeFooterCustomer,
          textAlign: TextAlign.center,
          style: AppFonts.body(fontSize: 13, color: AppTheme.textLight),
        ),
      ],
    );
  }
}

// ── Hero (photo + benefits) ─────────────────────────────────────────────────

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.tagline,
    required this.benefits,
    required this.isAdmin,
    this.compact = false,
  });

  final String tagline;
  final List<(IconData, String)> benefits;
  final bool isAdmin;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DsPhotoBanner(
      asset: DsPhotos.marina,
      radius: 0,
      decodeWidth: compact ? 1000 : 1600,
      alignment: Alignment.topCenter,
      padding: EdgeInsets.all(compact ? 24 : 56),
      childAlignment: AlignmentDirectional.bottomStart,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DsBrandMark(size: 44, onDark: true),
                const SizedBox(width: 12),
                Text(
                  'DealSouk',
                  style: AppFonts.display(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Text(
                tagline,
                style: AppFonts.display(
                  fontSize: compact ? 22 : 38,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            if (benefits.isNotEmpty) ...[
              const SizedBox(height: 28),
              for (final b in benefits)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(b.$1, color: AppTheme.forestDeep),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        b.$2.replaceAll('\n', ' '),
                        style: AppFonts.body(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.value,
    required this.onChanged,
    required this.onPolicy,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onPolicy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final base = AppFonts.body(fontSize: 14, height: 1.4, color: AppTheme.ink);
    return Semantics(
      checked: value,
      container: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: AppTheme.forestDeep,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 13),
              child: Text.rich(
                TextSpan(
                  style: base,
                  children: [
                    TextSpan(text: l.welcomePrivacyConsentPrefix),
                    TextSpan(
                      text: l.welcomePrivacyPolicyLink,
                      recognizer: TapGestureRecognizer()..onTap = onPolicy,
                      style: base.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.forestDeep,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(text: l.welcomePrivacyConsentSuffix),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Phone input ──────────────────────────────────────────────────────────────

InputDecoration _fieldDecoration(String hint) => InputDecoration(
  filled: true,
  fillColor: Colors.white,
  hintText: hint,
  hintStyle: AppFonts.body(color: AppTheme.textLight, fontSize: 16),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppTheme.line, width: 1.5),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppTheme.forestDeep, width: 2),
  ),
);

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
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppTheme.line, width: 1.5),
                ),
                child: InkWell(
                  onTap: onCountryTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 15,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedCountry.flag,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          selectedCountry.code,
                          style: AppFonts.body(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.ink,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(selectedCountry.maxLength),
                  ],
                  autofocus: true,
                  style: AppFonts.body(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                  decoration: _fieldDecoration(selectedCountry.formatHint),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DsButton(label: l.welcomeSendCode, loading: loading, onPressed: onSend),
        const SizedBox(height: 4),
        DsButton(
          label: l.welcomeCancel,
          style: DsButtonStyle.ghost,
          onPressed: onCancel,
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
          style: AppFonts.body(fontSize: 16, color: AppTheme.ink, height: 1.4),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 6,
          autofocus: true,
          autofillHints: const [AutofillHints.oneTimeCode],
          textAlign: TextAlign.center,
          style: AppFonts.display(
            fontSize: 28,
            letterSpacing: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
          decoration: _fieldDecoration('------').copyWith(counterText: ''),
        ),
        const SizedBox(height: 16),
        DsButton(label: l.welcomeVerify, loading: loading, onPressed: onVerify),
        const SizedBox(height: 4),
        DsButton(
          label: l.welcomeResendCode,
          style: DsButtonStyle.ghost,
          onPressed: onResend,
        ),
        DsButton(
          label: l.welcomeCancel,
          style: DsButtonStyle.ghost,
          onPressed: onCancel,
        ),
      ],
    );
  }
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

import 'package:flutter/material.dart';
import 'package:dealsouk/core/theme/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Privacy & Terms'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: const [
          _PolicySection(
            title: 'Plain English Summary',
            items: [
              'DealSouk helps shoppers compare grocery prices using community-submitted prices.',
              'We ask for only the information needed to run the app: your account, home area, language, submissions, requests, tokens, and moderation history.',
              'We use your device location only to show nearby supermarket prices. Precise GPS is not stored permanently.',
              'Tokens are rewards inside DealSouk. They are not cash, cannot be transferred, and cannot be sold.',
              'Photos are used to verify price labels or receipts. Do not upload photos with personal information.',
              'You can request account deletion from Profile settings.',
            ],
          ),
          _PolicySection(
            title: 'What We Collect',
            items: [
              'Account details: Firebase account ID, display name, phone number if you use phone login, and preferred language.',
              'Shopping area: neighbourhood or area, not a permanent precise GPS record.',
              'Price data: products, stores, prices, timestamps, optional shelf label or receipt photos, and moderation flags.',
              'Rewards data: token balance, token history, voucher requests, badges, streaks, and leaderboard totals.',
              'Device messaging token: used only for DealSouk notifications such as request fulfilment or reward updates.',
            ],
          ),
          _PolicySection(
            title: 'How We Use Data',
            items: [
              'To show fresh prices near you.',
              'To calculate savings, requests, tokens, and rewards.',
              'To detect wrong, stale, duplicate, or suspicious submissions.',
              'To operate admin moderation and voucher approval.',
              'To improve reliability, security, and Arabic/English usability.',
            ],
          ),
          _PolicySection(
            title: 'Your Choices',
            items: [
              'You may browse as a guest with limited features.',
              'You can change your display name, home area, and language.',
              'You can deny location access and still use non-location features.',
              'You can request account deletion. We anonymise account data needed for fraud prevention and financial/reward audit records.',
            ],
          ),
          _PolicySection(
            title: 'Arabic Summary',
            items: [
              'نستخدم موقعك فقط لعرض أسعار المتاجر القريبة، ولا نخزن موقع GPS الدقيق بشكل دائم.',
              'الرموز مكافآت داخل التطبيق وليست نقوداً ولا يمكن بيعها أو تحويلها.',
              'صور الأسعار أو الإيصالات تستخدم للتحقق فقط. لا ترفع صوراً تحتوي على معلومات شخصية.',
              'يمكنك طلب حذف الحساب من الإعدادات.',
            ],
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '- ',
                    style: TextStyle(
                      color: AppTheme.forestDeep,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

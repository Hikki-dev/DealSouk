import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/state/state.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/tutorial_overlay.dart';



class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(userTokensProvider);
    final submissions = ref.watch(adminSubmissionsProvider);
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.forestDeep,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 14,
              16,
              18,
            ),
            child: const Text(
              'Profile & Settings',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE8EEE4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE8EEE4), width: 1.5),
                            image: DecorationImage(
                              image: NetworkImage(profile.avatarUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: const TextStyle(
                                  color: AppTheme.textDark,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${profile.location} • $tokens tokens',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ShortcutCard(
                          icon: Icons.add_a_photo_outlined,
                          title: 'Submit price',
                          subtitle: 'Earn tokens',
                          onTap: () => context.push('/submit-price'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ShortcutCard(
                          icon: Icons.admin_panel_settings_outlined,
                          title: 'Admin review',
                          subtitle: '${submissions.length} pending',
                          onTap: () => context.push('/admin'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Demo readiness',
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _RequirementChip('iOS 16+', Icons.phone_iphone_rounded),
                      _RequirementChip('Android 13+', Icons.android_rounded),
                      _RequirementChip(
                        'Camera ready',
                        Icons.camera_alt_outlined,
                      ),
                      _RequirementChip('GPS demo', Icons.location_on_outlined),
                      _RequirementChip('English now', Icons.language_rounded),
                      _RequirementChip(
                        'Arabic ready',
                        Icons.format_textdirection_r_to_l_rounded,
                      ),
                      _RequirementChip('Tablet safe', Icons.tablet_mac_rounded),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SettingsRow(
                    icon: Icons.verified_user_outlined,
                    title: 'Verification preference',
                    subtitle:
                        'Manual admin review for receipts and shelf labels',
                  ),
                  _SettingsRow(
                    icon: Icons.wifi_tethering_outlined,
                    title: 'Connectivity mode',
                    subtitle: '4G/LTE live prices with cached demo fallback',
                  ),
                  _SettingsRow(
                    icon: Icons.notifications_active_outlined,
                    title: 'Price drop alerts',
                    subtitle: 'Demo-only preview, no real push notifications',
                  ),
                  GestureDetector(
                    onTap: () => _showMyRequestsSheet(context, ref),
                    child: const _SettingsRow(
                      icon: Icons.assignment_outlined,
                      title: 'My Price Requests',
                      subtitle: 'Track your open and completed price check bounties',
                    ),
                  ),
                  GestureDetector(
                    onTap: () => TutorialOverlay.show(context),
                    child: const _SettingsRow(
                      icon: Icons.help_outline_rounded,
                      title: 'View App Tutorial',
                      subtitle: 'Re-run the 3-screen DealSouk intro guide',
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => context.go('/welcome'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Log Out of Demo',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
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

  void _showMyRequestsSheet(BuildContext context, WidgetRef ref) {
    final requests = ref.read(priceRequestsProvider);
    final myRequests = requests.where((r) => r.requesterName == 'Hessa Al Maktoum').toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'My Price Requests',
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.forestDeep,
                ),
              ),
              const SizedBox(height: 12),
              if (myRequests.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'You haven\'t posted any price requests yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 13.5),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: myRequests.length,
                    itemBuilder: (context, index) {
                      final req = myRequests[index];
                      final isFulfilled = req.status == 'fulfilled';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: isFulfilled ? Colors.green.shade50 : Colors.amber.shade50,
                          child: Icon(
                            isFulfilled ? Icons.check_circle_rounded : Icons.pending_rounded,
                            color: isFulfilled ? Colors.green : Colors.amber.shade800,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          req.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${req.storeName} • ${req.timestampLabel}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${req.tokensBounty} T',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}


class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EEE4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppTheme.limeAccent,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.forestDeep, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.forestDeep,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequirementChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _RequirementChip(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.limeAccent.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.limeAccent.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.forestDeep, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.forestDeep,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEE4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.forestDeep, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

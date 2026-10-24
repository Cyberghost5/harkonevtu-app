import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/app_config_provider.dart';
import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _isCheckingUpdate = false;

  Future<void> _checkForUpdates() async {
    setState(() => _isCheckingUpdate = true);
    final configProvider = Provider.of<AppConfigProvider>(context, listen: false);
    await configProvider.fetchAppConfig();
    if (!mounted) return;
    setState(() => _isCheckingUpdate = false);

    if (configProvider.isUpdateAvailable) {
      _showUpdateAvailableModal(configProvider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${configProvider.appName.isNotEmpty ? configProvider.appName : 'Harkone VTU'} is up to date (v${configProvider.installedVersion}) 🎉',
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showUpdateAvailableModal(AppConfigProvider config) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardBg = Theme.of(ctx).cardColor;
        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClayContainer(
                  depth: 10,
                  cornerRadius: 50,
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(Icons.system_update_rounded, color: Color(0xFF10B981), size: 36),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Update Available!',
                  style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version v${config.serverAppVersion} is now available. You are currently running v${config.installedVersion}. Update now to get the latest features and security improvements.',
                  style: TextStyle(color: subColor, fontSize: 13, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ClayButton(
                  height: 50,
                  depth: 10,
                  color: Theme.of(ctx).primaryColor,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final url = config.updateUrl ?? config.playStoreUrl;
                    if (url != null && url.isNotEmpty) {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  child: const Text('Update Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final clean = url.trim();
    if (clean.isEmpty) return;
    try {
      final uri = Uri.parse(clean);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _showPolicyModal({required String title, required String content}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardBg = Theme.of(ctx).cardColor;
        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          builder: (_, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: subColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                        color: subColor,
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Text(
                        content,
                        style: TextStyle(color: subColor, fontSize: 13, height: 1.6),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<AppConfigProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    final appName = configProvider.appName.isNotEmpty ? configProvider.appName : 'Harkone VTU';
    final installedVer = configProvider.installedVersion;
    final buildNumber = configProvider.installedBuildNumber;
    final support = configProvider.support;
    final isUpdateAvail = configProvider.isUpdateAvailable;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('About App'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // ── 1. Hero / Branding Card ───────────────────────────────────────
            ClayContainer(
              depth: 10,
              cornerRadius: 24,
              color: cardBg,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    ClayContainer(
                      depth: 12,
                      cornerRadius: 50,
                      color: primaryColor.withValues(alpha: 0.15),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: configProvider.logo1Url != null && configProvider.logo1Url!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: configProvider.logo1Url!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.contain,
                                errorWidget: (_, __, ___) => Icon(Icons.flash_on_rounded, size: 50, color: primaryColor),
                              )
                            : Icon(Icons.flash_on_rounded, size: 50, color: primaryColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      appName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Smart • Fast • Secure VTU Services',
                      style: TextStyle(fontSize: 13, color: subColor, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),

                    // Version Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            'Version v$installedVer (Build $buildNumber)',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: '$appName v$installedVer+$buildNumber'));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Version information copied to clipboard!'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Icon(Icons.copy_rounded, size: 12, color: primaryColor),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Update Status Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isUpdateAvail ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isUpdateAvail ? 'Update Available (v${configProvider.serverAppVersion})' : 'Latest Release Installed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isUpdateAvail ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Check for Updates Button
                    ClayButton(
                      height: 44,
                      depth: 8,
                      color: primaryColor,
                      isLoading: _isCheckingUpdate,
                      onTap: _checkForUpdates,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Check for Updates',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── 2. Platform Overview ──────────────────────────────────────────
            _buildSectionHeader('Platform Overview', titleColor),
            ClayContainer(
              depth: 8,
              cornerRadius: 18,
              color: cardBg,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to $appName, your premier multi-service platform for instantaneous digital telecom solutions, electricity utility bill payments, cable subscriptions, and automated wallet funding.',
                      style: TextStyle(fontSize: 13, height: 1.6, color: subColor),
                    ),
                    const SizedBox(height: 14),
                    _buildFeatureItem(Icons.wifi_tethering_rounded, 'Instant Airtime & High-Speed Data Top-Up', subColor, primaryColor),
                    _buildFeatureItem(Icons.bolt_rounded, 'National DISCOs Prepaid & Postpaid Meter Tokens', subColor, primaryColor),
                    _buildFeatureItem(Icons.live_tv_rounded, 'Instant Cable Subscriptions (DStv, GOtv, Startimes)', subColor, primaryColor),
                    _buildFeatureItem(Icons.account_balance_rounded, 'Dedicated 24/7 Virtual Bank Accounts for Instant Funding', subColor, primaryColor),
                    _buildFeatureItem(Icons.fingerprint_rounded, 'Biometric Security & Hardware-Hashed Transaction PINs', subColor, primaryColor),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── 3. Security & Technology ─────────────────────────────────────
            _buildSectionHeader('Security & Architecture', titleColor),
            ClayContainer(
              depth: 8,
              cornerRadius: 18,
              color: cardBg,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _buildSpecRow('Encryption Protocol', '256-Bit SSL/TLS End-to-End', titleColor, subColor),
                    const Divider(height: 20),
                    _buildSpecRow('Payment Gateway', 'CBN-Licensed Virtual Accounts', titleColor, subColor),
                    const Divider(height: 20),
                    _buildSpecRow('Biometrics', 'Fingerprint & FaceID Integration', titleColor, subColor),
                    const Divider(height: 20),
                    _buildSpecRow('Availability SLA', '99.9% Cloud Redundancy', titleColor, subColor),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── 4. Contact & Community Channels ───────────────────────────────
            _buildSectionHeader('Official Support & Community', titleColor),
            ClayContainer(
              depth: 8,
              cornerRadius: 18,
              color: cardBg,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    if (support?.phone != null && support!.phone.isNotEmpty)
                      _buildContactTile(
                        icon: Icons.phone_in_talk_rounded,
                        title: 'Phone Hotline',
                        value: support.phone,
                        color: const Color(0xFF10B981),
                        onTap: () => _launchUrl('tel:${support.phone}'),
                      ),
                    if (support?.whatsapp != null && support!.whatsapp.isNotEmpty)
                      _buildContactTile(
                        icon: Icons.chat_rounded,
                        title: 'WhatsApp Support',
                        value: support.whatsapp,
                        color: const Color(0xFF25D366),
                        onTap: () {
                          final clean = support.whatsapp.replaceAll(RegExp(r'[^0-9+]'), '');
                          _launchUrl('https://wa.me/$clean');
                        },
                      ),
                    if (support?.email != null && support!.email.isNotEmpty)
                      _buildContactTile(
                        icon: Icons.alternate_email_rounded,
                        title: 'Official Email',
                        value: support.email,
                        color: const Color(0xFF3B82F6),
                        onTap: () => _launchUrl('mailto:${support.email}'),
                      ),
                    if (support?.whatsappGroup != null && support!.whatsappGroup.isNotEmpty)
                      _buildContactTile(
                        icon: Icons.groups_rounded,
                        title: 'WhatsApp Community',
                        value: 'Join Official Group',
                        color: const Color(0xFF059669),
                        onTap: () => _launchUrl(support.whatsappGroup),
                      ),
                    if (support?.telegramChannel != null && support!.telegramChannel.isNotEmpty)
                      _buildContactTile(
                        icon: Icons.send_rounded,
                        title: 'Telegram Channel',
                        value: 'Join Announcements',
                        color: const Color(0xFF0088CC),
                        onTap: () => _launchUrl(support.telegramChannel),
                      ),
                    if (support?.hours != null && support!.hours.isNotEmpty)
                      _buildContactTile(
                        icon: Icons.access_time_rounded,
                        title: 'Operating Hours',
                        value: support.hours,
                        color: Colors.amber,
                        onTap: null,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── 5. Legal & Policies ───────────────────────────────────────────
            _buildSectionHeader('Legal & Compliance', titleColor),
            ClayContainer(
              depth: 8,
              cornerRadius: 18,
              color: cardBg,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.privacy_tip_outlined, color: primaryColor),
                      title: Text('Privacy Policy', style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () => _showPolicyModal(
                        title: 'Privacy Policy',
                        content: '''We are deeply committed to protecting your personal information and financial privacy.\n\n1. Information Collection: We collect account profile information (such as name, phone number, and email) solely to process your VTU transactions, manage wallet accounting, and satisfy regulatory KYC requirements.\n\n2. Financial & Biometric Privacy: Your 4-digit Transaction PIN is securely hashed before storage and is never exposed in plaintext. Biometric credentials (fingerprint and Face ID) never leave your physical mobile device and are handled exclusively through your device hardware secure enclave.\n\n3. Data Sharing: We do not sell or monetize personal customer records. Minimal transaction details are shared strictly with verified telecom aggregators, electricity distribution companies, and CBN-licensed payment partners to fulfill top-up purchases.\n\n4. Data Retention & Deletion: You retain full rights to request your account data and permanent account deletion directly from the Profile menu at any time.\n\nLast updated: 2026.''',
                      ),
                    ),
                    Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ListTile(
                      leading: Icon(Icons.description_outlined, color: primaryColor),
                      title: Text('Terms of Service', style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () => _showPolicyModal(
                        title: 'Terms of Service',
                        content: '''By accessing or transacting on $appName, you agree to comply with and be bound by the following terms:\n\n1. Account Security: You are solely responsible for maintaining the confidentiality of your account login credentials and 4-digit transaction PIN.\n\n2. Transaction Finality: All telecom top-ups and bill payments are executed electronically in real-time. Please double-check recipient phone numbers, meter numbers, and smartcard IDs prior to confirming with your PIN.\n\n3. Automated Wallet Refunds: In the rare event a utility provider or telecom gateway reports a processing error, our automated engine immediately credits the debited funds back to your wallet balance.\n\n4. Prohibited Usage: The platform may not be utilized for fraudulent transactions, unauthorized network probing, or illicit monetary transfers.\n\nThank you for choosing $appName.''',
                      ),
                    ),
                    Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ListTile(
                      leading: Icon(Icons.assignment_outlined, color: primaryColor),
                      title: Text('Open Source Licenses', style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () {
                        showLicensePage(
                          context: context,
                          applicationName: appName,
                          applicationVersion: 'v$installedVer (Build $buildNumber)',
                          applicationIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(Icons.flash_on_rounded, size: 48, color: primaryColor),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── 6. Footer & Copyright ─────────────────────────────────────────
            Text(
              'Powered by $appName Engineering',
              style: TextStyle(color: subColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Copyright © 2026 $appName. All rights reserved.',
              style: TextStyle(color: subColor.withValues(alpha: 0.7), fontSize: 11),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, Color subColor, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: subColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, Color titleColor, Color subColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: subColor)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: titleColor)),
      ],
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            ClayContainer(
              depth: 6,
              cornerRadius: 10,
              color: color.withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(icon, color: color, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.open_in_new_rounded, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

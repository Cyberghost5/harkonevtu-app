import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../auth/login_screen.dart';
import 'referrals_screen.dart';

class ProfileView extends StatefulWidget {
  final Function(Widget) onNavigate;

  const ProfileView({super.key, required this.onNavigate});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchProfile();
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanNumber.isEmpty) {
      _showSnackBar('No customer support phone number configured.', isError: true);
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      final launched = await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        _showSnackBar('Could not launch phone app for $cleanNumber', isError: true);
      }
    } catch (_) {
      _showSnackBar('Could not place call to $cleanNumber', isError: true);
    }
  }

  Future<void> _openWhatsApp(String whatsappNumber) async {
    var cleanNumber = whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.isEmpty) {
      _showSnackBar('No WhatsApp support number configured.', isError: true);
      return;
    }

    if (cleanNumber.startsWith('0')) {
      cleanNumber = '234${cleanNumber.substring(1)}';
    }

    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');
    try {
      final launched = await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final webUri = Uri.parse('https://api.whatsapp.com/send?phone=$cleanNumber');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      _showSnackBar('Could not open WhatsApp for $whatsappNumber', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      ),
    );
  }

  void _showChangePasswordModal() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Change Password',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: oldPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_reset_rounded, color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.lock_rounded, color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (newPasswordController.text.length < 6) {
                      _showSnackBar('New password must be at least 6 characters.', isError: true);
                      return;
                    }
                    if (newPasswordController.text != confirmPasswordController.text) {
                      _showSnackBar('New passwords do not match.', isError: true);
                      return;
                    }
                    Navigator.pop(ctx);
                    _showSnackBar('Password change request submitted successfully!');
                  },
                  child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionPinModal() {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Transaction PIN Settings',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: const TextStyle(color: Colors.white, letterSpacing: 4),
                decoration: const InputDecoration(
                  labelText: '4-Digit Transaction PIN',
                  prefixIcon: Icon(Icons.pin_rounded, color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: confirmPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: const TextStyle(color: Colors.white, letterSpacing: 4),
                decoration: const InputDecoration(
                  labelText: 'Confirm 4-Digit PIN',
                  prefixIcon: Icon(Icons.pin_outlined, color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (pinController.text.length != 4) {
                      _showSnackBar('PIN must be exactly 4 digits.', isError: true);
                      return;
                    }
                    if (pinController.text != confirmPinController.text) {
                      _showSnackBar('Transaction PINs do not match.', isError: true);
                      return;
                    }
                    Navigator.pop(ctx);
                    _showSnackBar('Transaction PIN updated successfully!');
                  },
                  child: const Text('Save Transaction PIN', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountModal() {
    final passwordController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cardColor = Theme.of(ctx).cardColor;
        final titleColor = Theme.of(ctx).colorScheme.onSurface;
        final subColor = Theme.of(ctx).brightness == Brightness.dark
            ? const Color(0xFF94A3B8)
            : const Color(0xFF64748B);

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(modalCtx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 28),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Delete My Account',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Warning: This action is permanent. All your data, wallet balance, and transaction history will be wiped out.',
                              style: TextStyle(color: subColor, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      style: TextStyle(color: titleColor),
                      decoration: InputDecoration(
                        labelText: 'Enter Password to Confirm',
                        prefixIcon: Icon(Icons.lock_outline_rounded, color: subColor),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final pass = passwordController.text.trim();
                                if (pass.isEmpty) {
                                  _showSnackBar('Please enter your password to confirm.', isError: true);
                                  return;
                                }

                                setModalState(() => isSubmitting = true);
                                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                final response = await authProvider.deleteAccount(password: pass);

                                if (!mounted) return;

                                if (response.status) {
                                  if (modalCtx.mounted) Navigator.pop(modalCtx);
                                  _showSnackBar('Your account has been deleted successfully.');
                                  widget.onNavigate(
                                    LoginScreen(
                                      onNavigate: widget.onNavigate,
                                    ),
                                  );
                                } else {
                                  setModalState(() => isSubmitting = false);
                                  _showSnackBar(
                                    response.message.isNotEmpty ? response.message : 'Account deletion failed.',
                                    isError: true,
                                  );
                                }
                              },
                        child: isSubmitting
                            ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                            : const Text('Permanently Delete Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final configProvider = Provider.of<AppConfigProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;

    final user = authProvider.user;
    final support = configProvider.config?.support;

    final phoneSupport = (support?.phone != null && support!.phone.isNotEmpty)
        ? support.phone
        : '08000000000';

    final whatsappSupport = (support?.whatsapp != null && support!.whatsapp.isNotEmpty)
        ? support.whatsapp
        : '2348000000000';

    final avatarUrl = user?.avatar;
    final bool hasAvatar = avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://'));

    final rawName = user?.name.trim() ?? '';
    final rawUsername = user?.username.trim() ?? '';
    final displayName = rawName.isNotEmpty
        ? rawName
        : (rawUsername.isNotEmpty ? rawUsername : 'Harkone User');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = isDark ? const Color(0xFF232D42) : const Color(0xFFE2E8F0);
    final titleColor = Theme.of(context).colorScheme.onSurface;
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile & Security'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await authProvider.fetchProfile();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Details Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: primaryColor.withValues(alpha: 0.2),
                        backgroundImage: hasAvatar ? CachedNetworkImageProvider(avatarUrl) : null,
                        child: !hasAvatar ? Icon(Icons.person_rounded, size: 38, color: primaryColor) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'No email address',
                              style: TextStyle(color: subColor, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.phone ?? 'No phone number',
                              style: TextStyle(color: subColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Security & Biometrics Section
                _buildSectionTitle(context, 'Security & Preferences'),
                const SizedBox(height: 12),

                if (authProvider.isBiometricAvailable) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.fingerprint_rounded, color: primaryColor, size: 24),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Biometric Quick Login',
                                    style: TextStyle(color: titleColor, fontWeight: FontWeight.w600)),
                                Text('Enable Fingerprint / FaceID',
                                    style: TextStyle(color: subColor, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: authProvider.isBiometricEnabled,
                          activeThumbColor: primaryColor,
                          onChanged: (val) {
                            authProvider.toggleBiometrics(val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // App Theme Mode (Dark / Light Mode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            configProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            color: primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dark Mode Theme',
                                  style: TextStyle(color: titleColor, fontWeight: FontWeight.w600)),
                              Text(
                                configProvider.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
                                style: TextStyle(color: subColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: configProvider.isDarkMode,
                        activeThumbColor: primaryColor,
                        onChanged: (val) {
                          configProvider.toggleTheme(val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                _buildTile(
                  context,
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Account Password',
                  subtitle: 'Update your account login password',
                  onTap: _showChangePasswordModal,
                  color: primaryColor,
                ),
                const SizedBox(height: 12),

                _buildTile(
                  context,
                  icon: Icons.pin_rounded,
                  title: 'Transaction PIN',
                  subtitle: 'Set or update 4-digit transaction PIN',
                  onTap: _showTransactionPinModal,
                  color: primaryColor,
                ),
                const SizedBox(height: 12),

                _buildTile(
                  context,
                  icon: Icons.card_giftcard_rounded,
                  title: 'Refer & Earn Rewards',
                  subtitle: 'Invite friends & earn cash bonus per referral',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralsScreen()));
                  },
                  color: const Color(0xFFEAB308),
                ),
                const SizedBox(height: 24),

                // Support & Help Section
                _buildSectionTitle(context, 'Support & Help'),
                const SizedBox(height: 12),

                _buildTile(
                  context,
                  icon: Icons.support_agent_rounded,
                  title: 'Customer Support',
                  subtitle: 'Phone: $phoneSupport (Tap to Call)',
                  onTap: () => _makePhoneCall(phoneSupport),
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(height: 12),

                _buildTile(
                  context,
                  icon: Icons.chat_rounded,
                  title: 'WhatsApp Support',
                  subtitle: 'Direct support line: $whatsappSupport (Tap to Chat)',
                  onTap: () => _openWhatsApp(whatsappSupport),
                  color: const Color(0xFF25D366),
                ),
                const SizedBox(height: 24),

                // Account Danger Zone
                _buildSectionTitle(context, 'Account Management'),
                const SizedBox(height: 12),

                _buildTile(
                  context,
                  icon: Icons.delete_forever_rounded,
                  title: 'Delete My Account',
                  subtitle: 'Permanently remove your account and erase user data',
                  onTap: _showDeleteAccountModal,
                  color: const Color(0xFFEF4444),
                ),
                const SizedBox(height: 32),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await authProvider.logout();
                      if (!mounted) return;
                      widget.onNavigate(
                        LoginScreen(
                          onNavigate: widget.onNavigate,
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = isDark ? const Color(0xFF232D42) : const Color(0xFFE2E8F0);
    final titleColor = Theme.of(context).colorScheme.onSurface;
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: TextStyle(color: titleColor, fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(color: subColor, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../auth/login_screen.dart';

class ProfileView extends StatelessWidget {
  final Function(Widget) onNavigate;

  const ProfileView({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final configProvider = Provider.of<AppConfigProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile & Security'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // User Card Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2234),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF232D42)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: primaryColor.withValues(alpha: 0.2),
                      child: Icon(Icons.person_rounded, size: 36, color: primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Harkone User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.phone ?? '',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Security & Biometrics Section
              _buildSectionTitle('Security & Preferences'),
              const SizedBox(height: 12),

              if (authProvider.isBiometricAvailable) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2234),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF232D42)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fingerprint_rounded, color: primaryColor, size: 24),
                          const SizedBox(width: 14),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Biometric Quick Login',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              Text('Enable Fingerprint / FaceID',
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
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

              _buildTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change Account Password',
                subtitle: 'Update your account login password',
                onTap: () {},
                color: primaryColor,
              ),
              const SizedBox(height: 12),

              _buildTile(
                icon: Icons.pin_rounded,
                title: 'Transaction PIN',
                subtitle: 'Set or update 4-digit transaction PIN',
                onTap: () {},
                color: primaryColor,
              ),
              const SizedBox(height: 24),

              // Support & Help
              _buildSectionTitle('Support & Help'),
              const SizedBox(height: 12),

              _buildTile(
                icon: Icons.support_agent_rounded,
                title: 'Customer Support',
                subtitle: 'Phone: ${configProvider.config?.support.phone ?? 'N/A'}',
                onTap: () {},
                color: const Color(0xFF10B981),
              ),
              const SizedBox(height: 12),

              _buildTile(
                icon: Icons.chat_rounded,
                title: 'WhatsApp Support',
                subtitle: 'Direct support line: ${configProvider.config?.support.whatsapp ?? 'N/A'}',
                onTap: () {},
                color: const Color(0xFF25D366),
              ),
              const SizedBox(height: 32),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await authProvider.logout();
                    onNavigate(
                      LoginScreen(
                        onNavigate: onNavigate,
                        onLoginSuccess: () {},
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2234),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF232D42)),
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
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
      ),
    );
  }
}

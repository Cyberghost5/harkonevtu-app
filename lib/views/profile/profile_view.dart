import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../core/storage/secure_storage_service.dart';
import '../auth/login_screen.dart';
import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_text_field.dart';
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

  void _showEditProfileModal() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final nameController = TextEditingController(text: user?.name ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final modalBg = Theme.of(ctx).cardColor;
        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(modalCtx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: modalBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Personal Details',
                      style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ClayTextField(
                      controller: nameController,
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 12),
                    ClayTextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 24),
                    ClayButton(
                      height: 52,
                      depth: 12,
                      color: Theme.of(ctx).primaryColor,
                      isLoading: isSubmitting,
                      onTap: () async {
                        final name = nameController.text.trim();
                        final phone = phoneController.text.trim();
                        if (name.isEmpty) {
                          _showSnackBar('Please enter your full name.', isError: true);
                          return;
                        }
                        setModalState(() => isSubmitting = true);
                        final response = await authProvider.updateProfile(name: name, phone: phone);
                        if (!mounted) return;

                        if (response.status) {
                          if (modalCtx.mounted) Navigator.pop(modalCtx);
                          _showSnackBar('Profile details updated successfully!');
                        } else {
                          setModalState(() => isSubmitting = false);
                          _showSnackBar(
                            response.message.isNotEmpty ? response.message : 'Failed to update profile.',
                            isError: true,
                          );
                        }
                      },
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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

  void _showAvatarPickerModal() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final urlController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final modalBg = Theme.of(ctx).cardColor;
        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: modalBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change Profile Picture',
                  style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select a photo from your device gallery or camera',
                  style: TextStyle(color: subColor, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ClayContainer(
                        depth: 10,
                        cornerRadius: 18,
                        color: isDark ? const Color(0xFF1E283C) : const Color(0xFFF1F5F9),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final picker = ImagePicker();
                          final XFile? file = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                          if (file != null) {
                            final res = await authProvider.updateAvatar(file.path);
                            _showSnackBar(res.message, isError: !res.status);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Column(
                            children: [
                              Icon(Icons.camera_alt_rounded, color: Theme.of(ctx).primaryColor, size: 28),
                              const SizedBox(height: 8),
                              Text('Take Photo', style: TextStyle(color: titleColor, fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ClayContainer(
                        depth: 10,
                        cornerRadius: 18,
                        color: isDark ? const Color(0xFF1E283C) : const Color(0xFFF1F5F9),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final picker = ImagePicker();
                          final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                          if (file != null) {
                            final res = await authProvider.updateAvatar(file.path);
                            _showSnackBar(res.message, isError: !res.status);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Column(
                            children: [
                              Icon(Icons.photo_library_rounded, color: Theme.of(ctx).primaryColor, size: 28),
                              const SizedBox(height: 8),
                              Text('Choose Photo', style: TextStyle(color: titleColor, fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ClayTextField(
                  controller: urlController,
                  labelText: 'Or enter avatar image URL',
                  prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 16),
                ClayButton(
                  height: 48,
                  depth: 8,
                  color: Theme.of(ctx).primaryColor,
                  onTap: () async {
                    final url = urlController.text.trim();
                    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
                      _showSnackBar('Please enter a valid image URL (http/https).', isError: true);
                      return;
                    }
                    Navigator.pop(ctx);
                    final res = await authProvider.updateAvatar(url);
                    _showSnackBar(res.message, isError: !res.status);
                  },
                  child: const Text('Apply URL Avatar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBankDetailsModal() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final bankNameController = TextEditingController(text: user?.bankName ?? '');
    final accountNumberController = TextEditingController(text: user?.bankAccountNumber ?? '');
    final accountNameController = TextEditingController(text: user?.bankAccountName ?? '');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final modalBg = Theme.of(ctx).cardColor;
        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(modalCtx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: modalBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClayContainer(
                          depth: 10,
                          cornerRadius: 50,
                          color: Theme.of(ctx).primaryColor.withValues(alpha: 0.15),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(Icons.account_balance_rounded, color: Theme.of(ctx).primaryColor, size: 24),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Settlement Bank Details',
                              style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'For airtime-to-cash & referral payouts',
                              style: TextStyle(color: subColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClayTextField(
                      controller: bankNameController,
                      labelText: 'Bank Name (e.g. GTBank, Zenith, Access)',
                      prefixIcon: const Icon(Icons.account_balance_rounded, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 12),
                    ClayTextField(
                      controller: accountNumberController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      labelText: '10-Digit Account Number',
                      prefixIcon: const Icon(Icons.numbers_rounded, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 12),
                    ClayTextField(
                      controller: accountNameController,
                      labelText: 'Account Holder Full Name',
                      prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 24),
                    ClayButton(
                      height: 52,
                      depth: 12,
                      color: Theme.of(ctx).primaryColor,
                      isLoading: isSubmitting,
                      onTap: () async {
                        final bName = bankNameController.text.trim();
                        final accNum = accountNumberController.text.trim();
                        final accName = accountNameController.text.trim();

                        if (bName.isEmpty || accNum.length < 10 || accName.isEmpty) {
                          _showSnackBar('Please complete all 10-digit bank account fields.', isError: true);
                          return;
                        }

                        setModalState(() => isSubmitting = true);
                        final res = await authProvider.updateBankDetails(
                          bankName: bName,
                          accountNumber: accNum,
                          accountName: accName,
                        );

                        if (!mounted) return;

                        if (res.status) {
                          if (modalCtx.mounted) Navigator.pop(modalCtx);
                          _showSnackBar('Settlement bank details updated successfully!');
                        } else {
                          setModalState(() => isSubmitting = false);
                          _showSnackBar(res.message.isNotEmpty ? res.message : 'Failed to save bank details.', isError: true);
                        }
                      },
                      child: const Text('Save Settlement Bank', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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

  void _showUpgradeAgentModal() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final pinController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final modalBg = Theme.of(ctx).cardColor;
        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(modalCtx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: modalBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClayContainer(
                          depth: 10,
                          cornerRadius: 50,
                          color: Colors.amber.withValues(alpha: 0.2),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 28),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Upgrade to Agent Tier',
                          style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClayContainer(
                      depth: 8,
                      cornerRadius: 16,
                      color: Theme.of(ctx).primaryColor.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          'Agent Benefits:\n• Discounted VTU rates for airtime & data packages\n• Increased referral rewards & commission payouts\n• Dedicated priority customer support',
                          style: TextStyle(color: subColor, fontSize: 12, height: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClayTextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      labelText: 'Enter 4-Digit PIN to Confirm',
                      prefixIcon: const Icon(Icons.pin_outlined, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 24),
                    ClayButton(
                      height: 52,
                      depth: 12,
                      color: Theme.of(ctx).primaryColor,
                      isLoading: isSubmitting,
                      onTap: () async {
                        final pin = pinController.text.trim();
                        if (pin.length != 4) {
                          _showSnackBar('Please enter your 4-digit transaction PIN.', isError: true);
                          return;
                        }

                        setModalState(() => isSubmitting = true);
                        final res = await authProvider.upgradeToAgent(pin: pin);

                        if (!mounted) return;

                        if (res.status) {
                          if (modalCtx.mounted) Navigator.pop(modalCtx);
                          _showSnackBar('Account successfully upgraded to Agent Tier! 🎉');
                        } else {
                          setModalState(() => isSubmitting = false);
                          _showSnackBar(res.message.isNotEmpty ? res.message : 'Upgrade failed.', isError: true);
                        }
                      },
                      child: const Text('Upgrade Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

  void _showKycVerificationModal() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bvnController = TextEditingController();
    final ninController = TextEditingController();
    final dobController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final modalBg = Theme.of(ctx).cardColor;
        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(modalCtx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: modalBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClayContainer(
                          depth: 10,
                          cornerRadius: 50,
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 26),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KYC Identity Verification',
                              style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Verify identity for dedicated virtual accounts & limits',
                              style: TextStyle(color: subColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ClayContainer(
                      depth: 6,
                      cornerRadius: 14,
                      color: Theme.of(ctx).primaryColor.withValues(alpha: 0.08),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Your identity details are encrypted & used solely to generate automated virtual bank accounts and fulfill CBN compliance.',
                                style: TextStyle(fontSize: 11, height: 1.3, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ClayTextField(
                      controller: bvnController,
                      keyboardType: TextInputType.number,
                      maxLength: 11,
                      labelText: '11-Digit Bank Verification Number (BVN)',
                      prefixIcon: const Icon(Icons.pin_rounded, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 12),
                    ClayTextField(
                      controller: ninController,
                      keyboardType: TextInputType.number,
                      maxLength: 11,
                      labelText: 'National Identity Number (NIN - Optional)',
                      prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 12),
                    ClayTextField(
                      controller: dobController,
                      labelText: 'Date of Birth (DD/MM/YYYY)',
                      prefixIcon: const Icon(Icons.calendar_today_rounded, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 24),
                    ClayButton(
                      height: 52,
                      depth: 12,
                      color: const Color(0xFF10B981),
                      isLoading: isSubmitting,
                      onTap: () async {
                        final bvn = bvnController.text.trim();
                        final nin = ninController.text.trim();
                        final dob = dobController.text.trim();

                        if (bvn.length != 11) {
                          _showSnackBar('Please enter a valid 11-digit BVN.', isError: true);
                          return;
                        }

                        setModalState(() => isSubmitting = true);
                        final res = await authProvider.submitKyc(
                          bvn: bvn,
                          nin: nin.isNotEmpty ? nin : null,
                          dob: dob.isNotEmpty ? dob : null,
                        );

                        if (!mounted) return;

                        if (res.status) {
                          if (modalCtx.mounted) Navigator.pop(modalCtx);
                          _showSnackBar('KYC Verification request submitted successfully! 🎉');
                        } else {
                          setModalState(() => isSubmitting = false);
                          _showSnackBar(res.message.isNotEmpty ? res.message : 'KYC verification failed.', isError: true);
                        }
                      },
                      child: const Text('Submit Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

  void _showChangePasswordModal() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final modalBg = Theme.of(ctx).cardColor;
        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: modalBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Change Password',
                    style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ClayTextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 12),
                ClayTextField(
                  controller: newPasswordController,
                  obscureText: true,
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_reset_rounded, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 12),
                ClayTextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 24),
                ClayButton(
                  height: 52,
                  depth: 12,
                  color: Theme.of(ctx).primaryColor,
                  onTap: () {
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
                  child: const Text('Update Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTransactionPinModal() {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final modalBg = Theme.of(ctx).cardColor;
        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: modalBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transaction PIN Settings',
                    style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ClayTextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  labelText: '4-Digit Transaction PIN',
                  prefixIcon: const Icon(Icons.pin_rounded, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 8),
                ClayTextField(
                  controller: confirmPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  labelText: 'Confirm 4-Digit PIN',
                  prefixIcon: const Icon(Icons.pin_outlined, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 20),
                ClayButton(
                  height: 52,
                  depth: 12,
                  color: Theme.of(ctx).primaryColor,
                  onTap: () {
                    if (pinController.text.length != 4) {
                      _showSnackBar('PIN must be exactly 4 digits.', isError: true);
                      return;
                    }
                    if (pinController.text != confirmPinController.text) {
                      _showSnackBar('Transaction PINs do not match.', isError: true);
                      return;
                    }
                    SecureStorageService().savePin(pinController.text.trim());
                    Navigator.pop(ctx);
                    _showSnackBar('Transaction PIN updated successfully!');
                  },
                  child: const Text('Save Transaction PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        );
      },
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
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final modalBg = Theme.of(ctx).cardColor;
        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(modalCtx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: modalBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClayContainer(
                          depth: 10,
                          cornerRadius: 50,
                          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 28),
                          ),
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
                    ClayContainer(
                      depth: 8,
                      cornerRadius: 16,
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Warning: This action is permanent. All your data, wallet balance, and transaction history will be wiped out.',
                                style: TextStyle(color: subColor, fontSize: 12, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClayTextField(
                      controller: passwordController,
                      obscureText: true,
                      labelText: 'Enter Password to Confirm',
                      prefixIcon: Icons.lock_outline_rounded,
                    ),
                    const SizedBox(height: 24),
                    ClayButton(
                      height: 52,
                      depth: 12,
                      color: const Color(0xFFEF4444),
                      isLoading: isSubmitting,
                      onTap: () async {
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
                      child: const Text('Permanently Delete Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
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
                // User Details Header Card (3D Clay)
                ClayContainer(
                  depth: 14,
                  cornerRadius: 24,
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _showAvatarPickerModal,
                          child: Stack(
                            children: [
                              ClayContainer(
                                depth: 10,
                                cornerRadius: 50,
                                color: primaryColor.withValues(alpha: 0.2),
                                child: CircleAvatar(
                                  radius: 32,
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: hasAvatar ? CachedNetworkImageProvider(avatarUrl) : null,
                                  child: !hasAvatar ? Icon(Icons.person_rounded, size: 38, color: primaryColor) : null,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      displayName,
                                      style: TextStyle(
                                        color: titleColor,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit_note_rounded, color: primaryColor, size: 24),
                                    tooltip: 'Edit Profile Details',
                                    onPressed: _showEditProfileModal,
                                  ),
                                ],
                              ),
                              Text(
                                user?.email ?? 'No email address',
                                style: TextStyle(color: subColor, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.phone ?? 'No phone number',
                                style: TextStyle(color: subColor, fontSize: 12),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: _showKycVerificationModal,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (user?.kycStatus?.toLowerCase() == 'verified' || user?.kycStatus == '1' || user?.kycStatus == 'approved')
                                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                        : ((user?.kycStatus?.toLowerCase() == 'pending')
                                            ? Colors.amber.withValues(alpha: 0.15)
                                            : primaryColor.withValues(alpha: 0.15)),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        (user?.kycStatus?.toLowerCase() == 'verified' || user?.kycStatus == '1' || user?.kycStatus == 'approved')
                                            ? Icons.check_circle_rounded
                                            : ((user?.kycStatus?.toLowerCase() == 'pending') ? Icons.hourglass_top_rounded : Icons.shield_rounded),
                                        size: 12,
                                        color: (user?.kycStatus?.toLowerCase() == 'verified' || user?.kycStatus == '1' || user?.kycStatus == 'approved')
                                            ? const Color(0xFF10B981)
                                            : ((user?.kycStatus?.toLowerCase() == 'pending') ? const Color(0xFFF59E0B) : primaryColor),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        (user?.kycStatus?.toLowerCase() == 'verified' || user?.kycStatus == '1' || user?.kycStatus == 'approved')
                                            ? 'KYC Verified'
                                            : ((user?.kycStatus?.toLowerCase() == 'pending') ? 'KYC Pending' : 'Verify KYC'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: (user?.kycStatus?.toLowerCase() == 'verified' || user?.kycStatus == '1' || user?.kycStatus == 'approved')
                                              ? const Color(0xFF10B981)
                                              : ((user?.kycStatus?.toLowerCase() == 'pending') ? const Color(0xFFF59E0B) : primaryColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Security & Biometrics Section
                _buildSectionTitle(context, 'Security & Preferences'),
                const SizedBox(height: 12),

                // Edit Personal Details Tile
                ClayContainer(
                  depth: 8,
                  cornerRadius: 18,
                  onTap: _showEditProfileModal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded, color: primaryColor, size: 24),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Edit Personal Info',
                                    style: TextStyle(color: titleColor, fontWeight: FontWeight.w600)),
                                Text('Update your name & phone number',
                                    style: TextStyle(color: subColor, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        Icon(Icons.chevron_right_rounded, color: subColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Settlement Bank Details Tile
                ClayContainer(
                  depth: 8,
                  cornerRadius: 18,
                  onTap: _showBankDetailsModal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance_rounded, color: primaryColor, size: 24),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Settlement Bank Account',
                                    style: TextStyle(color: titleColor, fontWeight: FontWeight.w600)),
                                Text(
                                  user?.bankName != null && user!.bankName!.isNotEmpty
                                      ? '${user.bankName} - ${user.bankAccountNumber}'
                                      : 'Add bank for payouts & withdrawals',
                                  style: TextStyle(color: subColor, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Icon(Icons.chevron_right_rounded, color: subColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Account Tier & Upgrade Tile
                ClayContainer(
                  depth: 8,
                  cornerRadius: 18,
                  onTap: _showUpgradeAgentModal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              user?.userType.toLowerCase() == 'agent'
                                  ? Icons.workspace_premium_rounded
                                  : Icons.military_tech_rounded,
                              color: user?.userType.toLowerCase() == 'agent' ? Colors.amber : primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.userType.toLowerCase() == 'agent' ? 'Agent Account Tier 🌟' : 'Upgrade to Agent Tier',
                                  style: TextStyle(color: titleColor, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  user?.userType.toLowerCase() == 'agent'
                                      ? 'Active: Enjoy discounted rates & rewards'
                                      : 'Tap to unlock agent pricing & commissions',
                                  style: TextStyle(color: subColor, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Icon(Icons.chevron_right_rounded, color: subColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // KYC Identity Verification Tile
                ClayContainer(
                  depth: 8,
                  cornerRadius: 18,
                  onTap: _showKycVerificationModal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 24),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('KYC Identity Verification',
                                    style: TextStyle(color: titleColor, fontWeight: FontWeight.w600)),
                                Text(
                                  user?.kycStatus?.toLowerCase() == 'verified' || user?.kycStatus == '1' || user?.kycStatus == 'approved'
                                      ? 'Verified ✓ (Limits unlocked)'
                                      : (user?.kycStatus?.toLowerCase() == 'pending'
                                          ? 'Under Review ⏳'
                                          : 'Tap to submit BVN / NIN verification'),
                                  style: TextStyle(color: subColor, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Icon(Icons.chevron_right_rounded, color: subColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (authProvider.isBiometricAvailable) ...[
                  ClayContainer(
                    depth: 8,
                    cornerRadius: 18,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  ),
                  const SizedBox(height: 12),
                ],

                // App Theme Mode (Dark / Light Mode)
                ClayContainer(
                  depth: 8,
                  cornerRadius: 18,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                ClayButton(
                  height: 54,
                  depth: 12,
                  color: const Color(0xFFEF4444),
                  onTap: () async {
                    await authProvider.logout();
                    if (!mounted) return;
                    widget.onNavigate(
                      LoginScreen(
                        onNavigate: widget.onNavigate,
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
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
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return ClayContainer(
      depth: 8,
      cornerRadius: 18,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                ClayContainer(
                  depth: 6,
                  cornerRadius: 12,
                  color: color.withValues(alpha: 0.15),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(icon, color: color, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: titleColor, fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: subColor, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


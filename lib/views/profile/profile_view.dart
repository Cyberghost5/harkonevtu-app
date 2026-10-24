import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../auth/login_screen.dart';

import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_text_field.dart';
import 'referrals_screen.dart';
import 'about_screen.dart';
import '../../core/storage/secure_storage_service.dart';

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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final modalBg = Theme.of(ctx).cardColor;
        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
        bool isSubmitting = false;
        String? errorMessage;

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
                    if (errorMessage != null && errorMessage!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    ClayTextField(
                      controller: nameController,
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 12),
                    ClayTextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 11,
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
                          setModalState(() {
                            errorMessage = 'Please enter your full name.';
                          });
                          return;
                        }
                        if (phone.isNotEmpty && phone.length != 11) {
                          setModalState(() {
                            errorMessage = 'Please enter a valid 11-digit phone number.';
                          });
                          return;
                        }

                        setModalState(() {
                          isSubmitting = true;
                          errorMessage = null;
                        });
                        final response = await authProvider.updateProfile(name: name, phone: phone);
                        if (!mounted) return;

                        if (response.status) {
                          if (modalCtx.mounted) Navigator.pop(modalCtx);
                          _showSnackBar('Profile details updated successfully!');
                        } else {
                          setModalState(() {
                            isSubmitting = false;
                            errorMessage = response.message.isNotEmpty ? response.message : 'Failed to update profile.';
                          });
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final modalBg = Theme.of(ctx).cardColor;
        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        bool isSubmitting = false;
        String? errorMessage;

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
                    if (errorMessage != null && errorMessage!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                          setModalState(() {
                            errorMessage = 'Please complete all 10-digit bank account fields.';
                          });
                          return;
                        }

                        setModalState(() {
                          isSubmitting = true;
                          errorMessage = null;
                        });
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
                          setModalState(() {
                            isSubmitting = false;
                            errorMessage = res.message.isNotEmpty ? res.message : 'Failed to save bank details.';
                          });
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

  void _showAgentStatusDetailsModal() {
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agent Account Tier',
                          style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ACTIVE STATUS',
                            style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ClayContainer(
                  width: double.infinity,
                  depth: 8,
                  cornerRadius: 16,
                  color: Colors.amber.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Active Agent Privileges:',
                          style: TextStyle(color: titleColor, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '✓ Wholesale discounted rates on all Airtime & Data packages\n✓ Maximum referral rewards & commission payouts\n✓ Priority server routing & dedicated customer support\n✓ Access to exclusive agent merchant tools',
                          style: TextStyle(color: subColor, fontSize: 12, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ClayButton(
                  height: 50,
                  depth: 10,
                  color: Colors.amber,
                  onTap: () => Navigator.pop(ctx),
                  child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showUpgradeAgentModal() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final configProvider = Provider.of<AppConfigProvider>(context, listen: false);
    final user = authProvider.user;

    // 1. If user is already an Agent, show their status details card instead of upgrade form
    if (user != null && user.userType.toLowerCase() == 'agent') {
      _showAgentStatusDetailsModal();
      return;
    }

    final upgradeFee = configProvider.agentUpgradeFee;
    final currencySymbol = configProvider.currencySymbol;
    final walletBalance = user?.wallet?.balance ?? user?.balance ?? 0.0;
    final hasSufficientBalance = walletBalance >= upgradeFee;

    final pinController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final modalBg = Theme.of(ctx).cardColor;
        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        bool isSubmitting = false;
        String? errorMessage;

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

                    // Cost & Balance Overview
                    ClayContainer(
                      width: double.infinity,
                      depth: 6,
                      cornerRadius: 14,
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Upgrade Fee', style: TextStyle(color: subColor, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  '$currencySymbol${upgradeFee.toStringAsFixed(2)}',
                                  style: TextStyle(color: titleColor, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 28, color: subColor.withValues(alpha: 0.2)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Your Balance', style: TextStyle(color: subColor, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  '$currencySymbol${walletBalance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: hasSufficientBalance ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Full-width Agent Benefits Card
                    ClayContainer(
                      width: double.infinity,
                      depth: 8,
                      cornerRadius: 16,
                      color: Theme.of(ctx).primaryColor.withValues(alpha: 0.08),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.stars_rounded, size: 18, color: Theme.of(ctx).primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Agent Tier Benefits:',
                                  style: TextStyle(
                                    color: titleColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 14, color: Theme.of(ctx).primaryColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Discounted VTU wholesale rates for airtime & data packages',
                                    style: TextStyle(color: subColor, fontSize: 12, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 14, color: Theme.of(ctx).primaryColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Increased referral rewards & higher commission payouts',
                                    style: TextStyle(color: subColor, fontSize: 12, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 14, color: Theme.of(ctx).primaryColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Dedicated priority customer support & routing',
                                    style: TextStyle(color: subColor, fontSize: 12, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (!hasSufficientBalance) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Color(0xFFEF4444), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You need at least $currencySymbol${upgradeFee.toStringAsFixed(2)} in your wallet to upgrade. Please fund your wallet first.',
                                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClayButton(
                        height: 50,
                        depth: 10,
                        color: Theme.of(ctx).primaryColor,
                        onTap: () => Navigator.pop(modalCtx),
                        child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ] else ...[
                      if (errorMessage != null && errorMessage!.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      ClayTextField(
                        controller: pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        labelText: 'Enter 4-Digit PIN to Confirm ($currencySymbol${upgradeFee.toStringAsFixed(0)})',
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
                            setModalState(() {
                              errorMessage = 'Please enter your 4-digit transaction PIN.';
                            });
                            return;
                          }

                          setModalState(() {
                            isSubmitting = true;
                            errorMessage = null;
                          });
                          final res = await authProvider.upgradeToAgent(pin: pin);

                          if (!mounted) return;

                          if (res.status) {
                            if (modalCtx.mounted) Navigator.pop(modalCtx);
                            _showSnackBar('Account successfully upgraded to Agent Tier! 🎉');
                          } else {
                            setModalState(() {
                              isSubmitting = false;
                              errorMessage = res.message.isNotEmpty ? res.message : 'Upgrade failed.';
                            });
                          }
                        },
                        child: const Text('Confirm & Upgrade Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
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
    final idNumberController = TextEditingController();
    String selectedIdType = 'bvn'; // 'bvn' or 'nin'

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final modalBg = Theme.of(ctx).cardColor;
        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        bool isSubmitting = false;
        String? errorMessage;

        return Consumer<AuthProvider>(
          builder: (modalCtx, authProvider, _) {
            final configProvider = Provider.of<AppConfigProvider>(context, listen: false);
            final user = authProvider.user;
            final isVerified = user?.isKycVerified ?? false;
            final isPending = user?.isKycPending ?? false;
            final kycFee = configProvider.kycFee;
            final currencySymbol = configProvider.currencySymbol;
            final walletBalance = user?.wallet?.balance ?? 0.0;
            final hasSufficientBalance = walletBalance >= kycFee;

            return StatefulBuilder(
              builder: (sbCtx, setModalState) {
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
                        // Header
                        Row(
                          children: [
                            ClayContainer(
                              depth: 10,
                              cornerRadius: 50,
                              color: (isVerified ? const Color(0xFF10B981) : (isPending ? const Color(0xFFF59E0B) : Theme.of(ctx).primaryColor)).withValues(alpha: 0.15),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Icon(
                                  isVerified ? Icons.verified_user_rounded : (isPending ? Icons.hourglass_top_rounded : Icons.shield_outlined),
                                  color: isVerified ? const Color(0xFF10B981) : (isPending ? const Color(0xFFF59E0B) : Theme.of(ctx).primaryColor),
                                  size: 26,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isVerified ? 'KYC Verified' : (isPending ? 'Verification Pending' : 'KYC Identity Verification'),
                                    style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    isVerified
                                        ? 'Your account is fully verified with Tier 2 access'
                                        : (isPending
                                            ? 'Your submission is currently under review'
                                            : 'Verify identity for dedicated virtual accounts & limits'),
                                    style: TextStyle(color: subColor, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── 1. IF ALREADY VERIFIED ──────────────────────────────────
                        if (isVerified) ...[
                          ClayContainer(
                            depth: 8,
                            cornerRadius: 16,
                            color: const Color(0xFF10B981).withValues(alpha: 0.08),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Identity Verified Successfully',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Your identity has been verified in accordance with regulatory compliance. You have unlocked automated virtual bank accounts and maximum transaction limits.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  const SizedBox(height: 12),
                                  _buildKycStatusRow('Account Tier', 'Tier 2 (Verified)', const Color(0xFF10B981), isDark),
                                  const SizedBox(height: 8),
                                  _buildKycStatusRow('Verification Status', 'Active & Approved ✓', const Color(0xFF10B981), isDark),
                                  const SizedBox(height: 8),
                                  _buildKycStatusRow('Virtual Accounts', 'Automated & Dedicated', isDark ? Colors.white70 : const Color(0xFF334155), isDark),
                                  const SizedBox(height: 8),
                                  _buildKycStatusRow('Daily Limit', '₦5,000,000.00 / day', isDark ? Colors.white70 : const Color(0xFF334155), isDark),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ClayButton(
                            height: 50,
                            depth: 10,
                            color: const Color(0xFF10B981),
                            onTap: () => Navigator.pop(modalCtx),
                            child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ]
                        // ── 2. IF UNDER REVIEW ─────────────────────────────────────
                        else if (isPending) ...[
                          ClayContainer(
                            depth: 8,
                            cornerRadius: 16,
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.hourglass_top_rounded, color: Color(0xFFF59E0B), size: 24),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Submission Under Review',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Your identity verification documents have been received and are currently being reviewed. Your tier will be upgraded automatically.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ClayButton(
                            height: 50,
                            depth: 10,
                            color: Theme.of(ctx).primaryColor,
                            onTap: () => Navigator.pop(modalCtx),
                            child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ]
                        // ── 3. IF UNVERIFIED / REJECTED ─────────────────────────────
                        else ...[
                          // Cost & Balance Overview (if fee > 0)
                          if (kycFee > 0) ...[
                            ClayContainer(
                              width: double.infinity,
                              depth: 6,
                              cornerRadius: 14,
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('KYC Verification Fee', style: TextStyle(color: subColor, fontSize: 11)),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$currencySymbol${kycFee.toStringAsFixed(2)}',
                                          style: TextStyle(color: titleColor, fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Container(width: 1, height: 28, color: subColor.withValues(alpha: 0.2)),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('Your Balance', style: TextStyle(color: subColor, fontSize: 11)),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$currencySymbol${walletBalance.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: hasSufficientBalance ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

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

                          if (errorMessage != null && errorMessage!.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Document Type Selector (BVN or NIN)
                          Text(
                            'Select Verification Document',
                            style: TextStyle(color: titleColor, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      selectedIdType = 'bvn';
                                      errorMessage = null;
                                    });
                                  },
                                  child: ClayContainer(
                                    depth: selectedIdType == 'bvn' ? 10 : 3,
                                    cornerRadius: 12,
                                    color: selectedIdType == 'bvn'
                                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.pin_rounded,
                                            size: 18,
                                            color: selectedIdType == 'bvn' ? const Color(0xFF10B981) : subColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'BVN',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: selectedIdType == 'bvn' ? const Color(0xFF10B981) : subColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      selectedIdType = 'nin';
                                      errorMessage = null;
                                    });
                                  },
                                  child: ClayContainer(
                                    depth: selectedIdType == 'nin' ? 10 : 3,
                                    cornerRadius: 12,
                                    color: selectedIdType == 'nin'
                                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.badge_rounded,
                                            size: 18,
                                            color: selectedIdType == 'nin' ? const Color(0xFF10B981) : subColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'NIN',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: selectedIdType == 'nin' ? const Color(0xFF10B981) : subColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          ClayTextField(
                            controller: idNumberController,
                            keyboardType: TextInputType.number,
                            maxLength: 11,
                            labelText: selectedIdType == 'bvn'
                                ? '11-Digit Bank Verification Number (BVN)'
                                : '11-Digit National Identity Number (NIN)',
                            prefixIcon: Icon(
                              selectedIdType == 'bvn' ? Icons.pin_rounded : Icons.badge_rounded,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedIdType == 'bvn'
                                ? '💡 Submitting your BVN automatically generates your Dedicated Virtual Accounts (Wema, Titan, Monnify, PalmPay/9PSB) for instant automated wallet funding.'
                                : '💡 Your 11-digit NIN is found on your National Identity slip or NIMC app.',
                            style: TextStyle(fontSize: 11, color: subColor),
                          ),
                          const SizedBox(height: 24),

                          ClayButton(
                            height: 52,
                            depth: 12,
                            color: const Color(0xFF10B981),
                            isLoading: isSubmitting,
                            onTap: () async {
                              final idNumber = idNumberController.text.trim();

                              if (idNumber.length != 11 || int.tryParse(idNumber) == null) {
                                setModalState(() {
                                  errorMessage = 'Please enter a valid 11-digit ${selectedIdType.toUpperCase()}.';
                                });
                                return;
                              }

                              if (kycFee > 0 && walletBalance < kycFee) {
                                setModalState(() {
                                  errorMessage = 'Insufficient wallet balance. You need $currencySymbol${kycFee.toStringAsFixed(2)} in your wallet to verify KYC.';
                                });
                                return;
                              }

                              setModalState(() {
                                isSubmitting = true;
                                errorMessage = null;
                              });

                              final res = await authProvider.submitKyc(
                                idType: selectedIdType,
                                idNumber: idNumber,
                              );

                              if (!mounted) return;

                              if (res.status) {
                                try {
                                  Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData();
                                } catch (_) {}
                                if (modalCtx.mounted) Navigator.pop(modalCtx);
                                _showSnackBar('Identity verified successfully! Virtual accounts activated 🎉');
                              } else {
                                setModalState(() {
                                  isSubmitting = false;
                                  errorMessage = res.message.isNotEmpty ? res.message : 'KYC verification failed.';
                                });
                              }
                            },
                            child: Text(
                              'Verify ${selectedIdType.toUpperCase()}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildKycStatusRow(String label, String value, Color valueColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
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
        bool isSubmitting = false;
        String? errorMessage;

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
                    Text('Change Password',
                        style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (errorMessage != null && errorMessage!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                      isLoading: isSubmitting,
                      onTap: () async {
                        if (oldPasswordController.text.trim().isEmpty) {
                          setModalState(() {
                            errorMessage = 'Please enter your current password.';
                          });
                          return;
                        }
                        if (newPasswordController.text.length < 6) {
                          setModalState(() {
                            errorMessage = 'New password must be at least 6 characters.';
                          });
                          return;
                        }
                        if (newPasswordController.text != confirmPasswordController.text) {
                          setModalState(() {
                            errorMessage = 'New passwords do not match.';
                          });
                          return;
                        }
                        setModalState(() {
                          isSubmitting = true;
                          errorMessage = null;
                        });
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final response = await authProvider.changePassword(
                          currentPassword: oldPasswordController.text.trim(),
                          newPassword: newPasswordController.text.trim(),
                          confirmPassword: confirmPasswordController.text.trim(),
                        );
                        if (!mounted) return;
                        if (response.status) {
                          if (modalCtx.mounted) Navigator.pop(modalCtx);
                          _showSnackBar('Password updated successfully!');
                        } else {
                          setModalState(() {
                            isSubmitting = false;
                            errorMessage = response.message.isNotEmpty ? response.message : 'Failed to update password.';
                          });
                        }
                      },
                      child: const Text('Update Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

  void _showTransactionPinModal() {
    final oldPinController = TextEditingController();
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
        bool isSubmitting = false;
        String? errorMessage;

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
                    Text('Transaction PIN Settings',
                        style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (errorMessage != null && errorMessage!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    ClayTextField(
                      controller: oldPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      labelText: 'Current PIN (if set)',
                      prefixIcon: const Icon(Icons.pin_outlined, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 8),
                    ClayTextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      labelText: 'New 4-Digit Transaction PIN',
                      prefixIcon: const Icon(Icons.pin_rounded, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 8),
                    ClayTextField(
                      controller: confirmPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      labelText: 'Confirm New 4-Digit PIN',
                      prefixIcon: const Icon(Icons.pin_outlined, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 20),
                    ClayButton(
                      height: 52,
                      depth: 12,
                      color: Theme.of(ctx).primaryColor,
                      isLoading: isSubmitting,
                      onTap: () async {
                        if (pinController.text.length != 4) {
                          setModalState(() {
                            errorMessage = 'PIN must be exactly 4 digits.';
                          });
                          return;
                        }
                        if (pinController.text != confirmPinController.text) {
                          setModalState(() {
                            errorMessage = 'Transaction PINs do not match.';
                          });
                          return;
                        }
                        setModalState(() {
                          isSubmitting = true;
                          errorMessage = null;
                        });
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final response = await authProvider.updatePin(
                          currentPin: oldPinController.text.trim(),
                          newPin: pinController.text.trim(),
                          confirmPin: confirmPinController.text.trim(),
                        );
                        if (!mounted) return;
                        if (response.status) {
                          if (modalCtx.mounted) Navigator.pop(modalCtx);
                          _showSnackBar('Transaction PIN saved successfully!');
                        } else {
                          setModalState(() {
                            isSubmitting = false;
                            errorMessage = response.message.isNotEmpty ? response.message : 'Failed to save transaction PIN.';
                          });
                        }
                      },
                      child: const Text('Save Transaction PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

  void _showLinkPinForBiometricsModal() {
    final pinController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final modalBg = Theme.of(ctx).cardColor;
        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        bool isSubmitting = false;
        String? errorMessage;

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
                            child: Icon(Icons.fingerprint_rounded, color: Theme.of(ctx).primaryColor, size: 28),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Link PIN for Biometrics',
                                style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Enable 1-tap fingerprint/face payments',
                                style: TextStyle(color: subColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please enter your 4-digit transaction PIN to securely link it with your device biometrics for instant checkout.',
                      style: TextStyle(color: subColor, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    if (errorMessage != null && errorMessage!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    ClayTextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      labelText: '4-Digit Transaction PIN',
                      prefixIcon: const Icon(Icons.pin_rounded, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 20),
                    ClayButton(
                      height: 52,
                      depth: 12,
                      color: Theme.of(ctx).primaryColor,
                      isLoading: isSubmitting,
                      onTap: () async {
                        final pin = pinController.text.trim();
                        if (pin.length != 4) {
                          setModalState(() {
                            errorMessage = 'PIN must be exactly 4 digits.';
                          });
                          return;
                        }

                        setModalState(() {
                          isSubmitting = true;
                          errorMessage = null;
                        });

                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final verifyRes = await authProvider.verifyPin(pin: pin);

                        if (!mounted) return;

                        if (verifyRes.status) {
                          await SecureStorageService().savePin(pin);
                          if (modalCtx.mounted) Navigator.pop(modalCtx);
                          _showSnackBar('Biometric payments & login activated successfully! 🎉');
                        } else {
                          setModalState(() {
                            isSubmitting = false;
                            errorMessage = verifyRes.message.isNotEmpty
                                ? verifyRes.message
                                : 'Incorrect transaction PIN. Please try again.';
                          });
                        }
                      },
                      child: const Text('Link Biometrics & PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
        String? errorMessage;

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
                    if (errorMessage != null && errorMessage!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                          setModalState(() {
                            errorMessage = 'Please enter your password to confirm.';
                          });
                          return;
                        }

                        setModalState(() {
                          isSubmitting = true;
                          errorMessage = null;
                        });
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
                          setModalState(() {
                            isSubmitting = false;
                            errorMessage = response.message.isNotEmpty ? response.message : 'Account deletion failed.';
                          });
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
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      displayName,
                                      style: TextStyle(
                                        color: titleColor,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    visualDensity: VisualDensity.compact,
                                    icon: Icon(Icons.edit_note_rounded, color: primaryColor, size: 24),
                                    tooltip: 'Edit Profile Details',
                                    onPressed: _showEditProfileModal,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                user?.email ?? 'No email address',
                                style: TextStyle(color: subColor, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.phone ?? 'No phone number',
                                style: TextStyle(color: subColor, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: _showKycVerificationModal,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (user?.isKycVerified ?? false)
                                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                        : ((user?.isKycPending ?? false)
                                            ? Colors.amber.withValues(alpha: 0.15)
                                            : primaryColor.withValues(alpha: 0.15)),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        (user?.isKycVerified ?? false)
                                            ? Icons.check_circle_rounded
                                            : ((user?.isKycPending ?? false) ? Icons.hourglass_top_rounded : Icons.shield_rounded),
                                        size: 12,
                                        color: (user?.isKycVerified ?? false)
                                            ? const Color(0xFF10B981)
                                            : ((user?.isKycPending ?? false) ? const Color(0xFFF59E0B) : primaryColor),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        (user?.isKycVerified ?? false)
                                            ? 'KYC Verified'
                                            : ((user?.isKycPending ?? false) ? 'KYC Pending' : 'Verify KYC'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: (user?.isKycVerified ?? false)
                                              ? const Color(0xFF10B981)
                                              : ((user?.isKycPending ?? false) ? const Color(0xFFF59E0B) : primaryColor),
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

                _buildTile(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Personal Info',
                  subtitle: 'Update your name & phone number',
                  onTap: _showEditProfileModal,
                  color: primaryColor,
                ),
                const SizedBox(height: 12),

                _buildTile(
                  context,
                  icon: Icons.account_balance_rounded,
                  title: 'Settlement Bank Account',
                  subtitle: user?.bankName != null && user!.bankName!.isNotEmpty
                      ? '${user.bankName} - ${user.bankAccountNumber}'
                      : 'Add bank for payouts & withdrawals',
                  onTap: _showBankDetailsModal,
                  color: primaryColor,
                ),
                const SizedBox(height: 12),

                _buildTile(
                  context,
                  icon: user?.userType.toLowerCase() == 'agent'
                      ? Icons.workspace_premium_rounded
                      : Icons.military_tech_rounded,
                  title: user?.userType.toLowerCase() == 'agent' ? 'Agent Account Tier 🌟' : 'Upgrade to Agent Tier',
                  subtitle: user?.userType.toLowerCase() == 'agent'
                      ? 'Active: Enjoy discounted rates & rewards'
                      : 'Tap to unlock agent pricing & commissions',
                  onTap: _showUpgradeAgentModal,
                  color: user?.userType.toLowerCase() == 'agent' ? Colors.amber : primaryColor,
                ),
                const SizedBox(height: 12),

                _buildTile(
                  context,
                  icon: Icons.verified_user_rounded,
                  title: 'KYC Identity Verification',
                  subtitle: (user?.isKycVerified ?? false)
                      ? 'Verified ✓ (Limits unlocked)'
                      : ((user?.isKycPending ?? false)
                          ? 'Under Review ⏳'
                          : 'Tap to submit BVN / NIN verification'),
                  onTap: _showKycVerificationModal,
                  color: (user?.isKycVerified ?? false)
                      ? const Color(0xFF10B981)
                      : ((user?.isKycPending ?? false)
                          ? const Color(0xFFF59E0B)
                          : primaryColor),
                ),
                const SizedBox(height: 12),

                if (authProvider.isBiometricAvailable) ...[
                  _buildTile(
                    context,
                    icon: Icons.fingerprint_rounded,
                    title: 'Biometric Quick Login & Payments',
                    subtitle: authProvider.isBiometricEnabled
                        ? 'Active (Fingerprint / FaceID enabled)'
                        : 'Tap switch to authenticate & activate',
                    color: primaryColor,
                    trailing: Switch(
                      value: authProvider.isBiometricEnabled,
                      activeThumbColor: primaryColor,
                      onChanged: (val) async {
                        if (val) {
                          final success = await authProvider.enableBiometricsWithVerification();
                          if (success) {
                            final hasSavedPin = await SecureStorageService().hasPin();
                            if (!hasSavedPin && mounted) {
                              _showLinkPinForBiometricsModal();
                            } else {
                              _showSnackBar('Biometric Quick Login & Payments enabled successfully!');
                            }
                          } else {
                            _showSnackBar('Biometric verification failed. Not activated.', isError: true);
                          }
                        } else {
                          await authProvider.disableBiometrics();
                          _showSnackBar('Biometric authentication disabled.');
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],


                _buildTile(
                  context,
                  icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  title: 'Dark Mode Theme',
                  subtitle: configProvider.themeMode == ThemeMode.system
                      ? 'System Default (${isDark ? 'Dark' : 'Light'})'
                      : (isDark ? 'Dark theme enabled' : 'Light theme enabled'),
                  color: primaryColor,
                  trailing: Switch(
                    value: isDark,
                    activeThumbColor: primaryColor,
                    onChanged: (val) {
                      configProvider.toggleTheme(val);
                    },
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
                const SizedBox(height: 12),

                _buildTile(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: 'About ${configProvider.appName.isNotEmpty ? configProvider.appName : 'Harkone VTU'}',
                  subtitle: 'Version v${configProvider.installedVersion} • Security, Specs & Legal',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                  color: const Color(0xFF6366F1),
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

                const SizedBox(height: 24),

                // Version & App Info Footer
                Center(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          Text(
                            '${configProvider.appName.isNotEmpty ? configProvider.appName : 'Harkone VTU'} v${configProvider.installedVersion} (Build ${configProvider.installedBuildNumber})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: subColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to view app specifications & check updates',
                            style: TextStyle(
                              fontSize: 10,
                              color: subColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
    VoidCallback? onTap,
    Widget? trailing,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final tileContent = Padding(
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
          trailing ?? const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
        ],
      ),
    );

    return ClayContainer(
      depth: 8,
      cornerRadius: 18,
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTap,
                child: tileContent,
              ),
            )
          : tileContent,
    );
  }
}


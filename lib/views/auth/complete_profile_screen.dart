import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../providers/dashboard_provider.dart';
import '../navigation/main_navigation_shell.dart';
import 'login_screen.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_container.dart';
import '../widgets/clay_text_field.dart';

class CompleteProfileScreen extends StatefulWidget {
  final Function(Widget screen)? onNavigate;
  final VoidCallback? onCompleteSuccess;

  const CompleteProfileScreen({
    super.key,
    this.onNavigate,
    this.onCompleteSuccess,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null && user.phone.isNotEmpty) {
      _phoneController.text = user.phone;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _skipToDashboard() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      await SecureStorageService().setPromptedRegistrationSetup(user.id);
    }

    await dashboardProvider.fetchDashboardData();
    if (!mounted) return;

    final Function(Widget) navigateCallback = widget.onNavigate ??
        (screen) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => screen),
            );
          }
        };

    if (widget.onNavigate != null) {
      widget.onNavigate!(MainNavigationShell(onNavigate: navigateCallback));
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainNavigationShell(onNavigate: navigateCallback),
        ),
      );
    }

    if (widget.onCompleteSuccess != null) {
      widget.onCompleteSuccess!();
    }
  }

  void _handleSubmit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    final user = authProvider.user;

    final needsPhone = user == null || user.needsPhone;
    final needsPin = user == null || user.needsPin;

    setState(() {
      _errorMessage = null;
    });

    if (needsPhone) {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter your mobile phone number.';
        });
        return;
      }
      final cleanPhone = phone.replaceAll(RegExp(r'[\s\-]'), '');
      if (cleanPhone.length < 10 || cleanPhone.length > 14) {
        setState(() {
          _errorMessage = 'Please enter a valid phone number (e.g. 08012345678).';
        });
        return;
      }
    }

    if (needsPin) {
      final pin = _pinController.text.trim();
      final confirmPin = _confirmPinController.text.trim();

      if (pin.length != 4) {
        setState(() {
          _errorMessage = 'Transaction PIN must be exactly 4 digits.';
        });
        return;
      }

      if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
        setState(() {
          _errorMessage = 'Transaction PIN must contain numbers only.';
        });
        return;
      }

      if (pin != confirmPin) {
        setState(() {
          _errorMessage = 'Transaction PIN and confirmation do not match.';
        });
        return;
      }
    }

    final response = await authProvider.completeProfile(
      phone: needsPhone ? _phoneController.text.trim() : null,
      pin: needsPin ? _pinController.text.trim() : null,
      confirmPin: needsPin ? _confirmPinController.text.trim() : null,
    );

    if (!mounted) return;

    if (response.status) {
      final user = authProvider.user;
      if (user != null) {
        await SecureStorageService().setPromptedRegistrationSetup(user.id);
      }
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message.isNotEmpty
              ? response.message
              : 'Profile setup completed successfully! Welcome.'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await dashboardProvider.fetchDashboardData();
      if (!mounted) return;

      final Function(Widget) navigateCallback = widget.onNavigate ??
          (screen) {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => screen),
              );
            }
          };

      if (widget.onNavigate != null) {
        widget.onNavigate!(MainNavigationShell(onNavigate: navigateCallback));
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MainNavigationShell(onNavigate: navigateCallback),
          ),
        );
      }

      if (widget.onCompleteSuccess != null) {
        widget.onCompleteSuccess!();
      }
    } else {
      setState(() {
        _errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Failed to complete profile setup. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    final needsPhone = user == null || user.needsPhone;
    final needsPin = user == null || user.needsPin;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _skipToDashboard();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text(
            'Complete Profile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          elevation: 0,
          actions: [
            TextButton(
              onPressed: _skipToDashboard,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Icon / Clay Badge
                  Center(
                    child: ClayContainer(
                      depth: 12,
                      borderRadius: 30,
                      color: cardBg,
                      padding: const EdgeInsets.all(22),
                      child: Icon(
                        Icons.verified_user_rounded,
                        size: 48,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Finish Setting Up Your Account',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'To protect your wallet and authorize instant airtime, data, and bill payments, please complete the requirements below.',
                    style: TextStyle(
                      fontSize: 14,
                      color: subColor,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Error alert box
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── SECTION 1: PHONE NUMBER ──────────────────────────────────
                  if (needsPhone) ...[
                    ClayContainer(
                      depth: 6,
                      borderRadius: 20,
                      color: cardBg,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.phone_android_rounded, color: primaryColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mobile Phone Number',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Required for SMS notifications & wallet identification',
                                      style: TextStyle(fontSize: 12, color: subColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClayTextField(
                            controller: _phoneController,
                            labelText: 'Phone Number',
                            hintText: 'e.g. 08012345678',
                            keyboardType: TextInputType.phone,
                            maxLength: 14,
                            prefixIcon: Icons.phone_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    // Phone already set badge
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Phone Number Connected',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.phone ?? '',
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── SECTION 2: TRANSACTION PIN ───────────────────────────────
                  if (needsPin) ...[
                    ClayContainer(
                      depth: 6,
                      borderRadius: 20,
                      color: cardBg,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.lock_outline_rounded, color: Color(0xFFF59E0B), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Create 4-Digit Transaction PIN',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Used to authorize purchases, data, and bill payments',
                                      style: TextStyle(fontSize: 12, color: subColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClayTextField(
                            controller: _pinController,
                            labelText: '4-Digit Transaction PIN',
                            hintText: '••••',
                            obscureText: _obscurePin,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            prefixIcon: Icons.lock_clock_outlined,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: subColor,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePin = !_obscurePin),
                            ),
                          ),
                          const SizedBox(height: 14),
                          ClayTextField(
                            controller: _confirmPinController,
                            labelText: 'Confirm 4-Digit PIN',
                            hintText: '••••',
                            obscureText: _obscureConfirmPin,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            prefixIcon: Icons.lock_reset_rounded,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: subColor,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Submit Button
                  ClayButton(
                    text: 'Save & Proceed to Dashboard',
                    icon: Icons.arrow_forward_rounded,
                    isLoading: authProvider.isLoading,
                    onPressed: authProvider.isLoading ? null : _handleSubmit,
                  ),
                  const SizedBox(height: 16),

                  // Safe Logout Option (to exit without bypassing PIN)
                  Center(
                    child: TextButton.icon(
                      onPressed: _skipToDashboard,
                      icon: Icon(Icons.arrow_forward_rounded, size: 16, color: primaryColor),
                      label: Text(
                        'Skip for now, go to Dashboard',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Log Out?'),
                            content: const Text(
                              'Are you sure you want to log out? You will be required to set your transaction PIN when you log back in.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFEF4444),
                                ),
                                child: const Text('Log Out'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await authProvider.logout();
                          if (mounted) {
                            final navigateCallback = widget.onNavigate ??
                                (screen) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => screen),
                                    (route) => false,
                                  );
                                };
                            navigateCallback(
                              LoginScreen(
                                onNavigate: navigateCallback,
                                onLoginSuccess: widget.onCompleteSuccess,
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.logout_rounded, size: 16, color: subColor),
                      label: Text(
                        'Log out and set up later',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: subColor,
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
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/auth_provider.dart';
import '../navigation/main_navigation_shell.dart';

import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final Function(Widget) onNavigate;
  final VoidCallback? onVerificationSuccess;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.onNavigate,
    this.onVerificationSuccess,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendTimerSeconds = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _resendTimerSeconds = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimerSeconds > 0) {
        setState(() {
          _resendTimerSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  String _getOtpCode() {
    return _controllers.map((c) => c.text).join();
  }

  void _handleVerify() async {
    final otp = _getOtpCode();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 6 digits of the OTP.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyOtp(widget.email, otp);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP verified successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      widget.onNavigate(MainNavigationShell(onNavigate: widget.onNavigate));
      if (widget.onVerificationSuccess != null) {
        widget.onVerificationSuccess!();
      }
    } else {
      final errorMsg = authProvider.errorMessage ?? 'Verification failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _handleResend() async {
    if (!_canResend) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sent = await authProvider.resendOtp(widget.email);

    if (!mounted) return;

    if (sent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new OTP code has been sent to your email.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      _startTimer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to resend OTP.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              ClayContainer(
                borderRadius: 60,
                depth: 14,
                padding: const EdgeInsets.all(20),
                color: isDark ? const Color(0xFF1B2436) : Colors.white,
                child: Icon(Icons.mark_email_read_rounded, size: 54, color: primaryColor),
              ),
              const SizedBox(height: 24),
              Text(
                'Verify Email Address',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 14,
                  ),
                  children: [
                    const TextSpan(text: 'Enter the 6-digit verification code sent to '),
                    TextSpan(
                      text: widget.email,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // OTP Digits Row in 3D Recessed Clay Containers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 58,
                    child: ClayContainer(
                      isRecessed: true,
                      depth: 6,
                      borderRadius: 14,
                      color: isDark ? const Color(0xFF131A29) : const Color(0xFFF1F5F9),
                      child: Center(
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                            if (_getOtpCode().length == 6) {
                              _handleVerify();
                            }
                          },
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),

              // Verify Button
              ClayButton(
                text: 'Verify Code',
                icon: Icons.verified_user_rounded,
                isLoading: authProvider.isLoading,
                onPressed: authProvider.isLoading ? null : _handleVerify,
              ),
              const SizedBox(height: 28),

              // Resend Timer & Action
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive code? ", style: TextStyle(color: Color(0xFF94A3B8))),
                  _canResend
                      ? GestureDetector(
                          onTap: _handleResend,
                          child: Text(
                            'Resend Code',
                            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                          ),
                        )
                      : Text(
                          'Resend in ${_resendTimerSeconds}s',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final Function(Widget) onNavigate;

  const ForgotPasswordScreen({super.key, required this.onNavigate});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      widget.onNavigate(
        LoginScreen(
          onNavigate: widget.onNavigate,
          onLoginSuccess: () {},
        ),
      );
    }
  }

  void _handleForgotPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.forgotPassword(_emailController.text.trim());

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset OTP sent to your email.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      widget.onNavigate(
        ResetPasswordScreen(
          email: _emailController.text.trim(),
          onNavigate: widget.onNavigate,
        ),
      );
    } else {
      final errorMsg = authProvider.errorMessage ?? 'Request failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _navigateToLogin();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Forgot Password'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _navigateToLogin,
          ),
        ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: ClayContainer(
                    borderRadius: 60,
                    depth: 14,
                    padding: const EdgeInsets.all(20),
                    color: isDark ? const Color(0xFF1B2436) : Colors.white,
                    child: Icon(Icons.lock_reset_rounded, size: 54, color: primaryColor),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Reset Your Password',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter the email address associated with your account and we will send you a reset code.',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Email Field
                ClayTextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF94A3B8)),
                  validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email address' : null,
                ),
                const SizedBox(height: 32),

                // Send Reset Code Button
                ClayButton(
                  text: 'Send Reset Code',
                  icon: Icons.send_rounded,
                  isLoading: authProvider.isLoading,
                  onPressed: authProvider.isLoading ? null : _handleForgotPassword,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}

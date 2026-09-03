import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

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
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_reset_rounded, size: 54, color: primaryColor),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Reset Your Password',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enter the email address associated with your account and we will send you a reset code.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF94A3B8)),
                  ),
                  validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email address' : null,
                ),
                const SizedBox(height: 32),

                // Send Reset Code Button
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleForgotPassword,
                  child: authProvider.isLoading
                      ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                      : const Text('Send Reset Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../navigation/main_navigation_shell.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final Function(Widget) onNavigate;
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.onNavigate,
    this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    final success = await authProvider.login(
      _loginController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful! Welcome back.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      await dashboardProvider.fetchDashboardData();
      if (!mounted) return;
      widget.onNavigate(MainNavigationShell(onNavigate: widget.onNavigate));
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      }
    } else {
      final errorMsg = authProvider.errorMessage ?? 'Login failed. Please check credentials.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _handleBiometricsLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    final authenticated = await authProvider.authenticateWithBiometrics();
    if (!mounted) return;

    if (authenticated) {
      if (authProvider.isAuthenticated) {
        await dashboardProvider.fetchDashboardData();
        if (!mounted) return;
        widget.onNavigate(MainNavigationShell(onNavigate: widget.onNavigate));
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric verified! Please login with your password once to refresh token.'),
            backgroundColor: Colors.amber,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final configProvider = Provider.of<AppConfigProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dynamic Logo & Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: configProvider.config?.logo1Url != null &&
                              configProvider.config!.logo1Url!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: configProvider.config!.logo1Url!,
                              height: 56,
                              width: 56,
                              errorWidget: (_, _, _) => Icon(Icons.bolt_rounded, size: 56, color: primaryColor),
                            )
                          : Icon(Icons.bolt_rounded, size: 56, color: primaryColor),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to access your ${configProvider.appName} wallet',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // Login Input (Email or Phone)
                  TextFormField(
                    controller: _loginController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Email or Phone Number',
                      prefixIcon: Icon(Icons.person_outline_rounded, color: Color(0xFF94A3B8)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email or phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF94A3B8),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        widget.onNavigate(
                          ForgotPasswordScreen(onNavigate: widget.onNavigate),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleLogin,
                    child: authProvider.isLoading
                        ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                        : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),

                  // Biometrics Login Button
                  if (authProvider.isBiometricAvailable) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _handleBiometricsLogin,
                      icon: Icon(Icons.fingerprint_rounded, color: primaryColor),
                      label: Text(
                        'Quick Biometric Login',
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Register Footer Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                      GestureDetector(
                        onTap: () {
                          widget.onNavigate(
                            RegisterScreen(
                              onNavigate: widget.onNavigate,
                              onLoginSuccess: widget.onLoginSuccess,
                            ),
                          );
                        },
                        child: Text(
                          'Register',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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

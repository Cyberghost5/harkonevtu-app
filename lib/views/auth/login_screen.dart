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

import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_text_field.dart';

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

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  // Animated 3D Floating Logo Badge with rounded clip
                  Center(
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: ClayContainer(
                        borderRadius: 60,
                        depth: 16,
                        spread: 3,
                        padding: const EdgeInsets.all(18),
                        color: isDark ? const Color(0xFF1B2436) : Colors.white,
                        child: configProvider.config?.logo1Url != null &&
                                configProvider.config!.logo1Url!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: CachedNetworkImage(
                                  imageUrl: configProvider.config!.logo1Url!,
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => Icon(Icons.bolt_rounded, size: 60, color: primaryColor),
                                ),
                              )
                            : Icon(Icons.bolt_rounded, size: 60, color: primaryColor),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to access your ${configProvider.appName} wallet',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // Login Input (Email or Phone) in 3D Recessed ClayTextField
                  ClayTextField(
                    controller: _loginController,
                    keyboardType: TextInputType.emailAddress,
                    labelText: 'Email or Phone Number',
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF94A3B8)),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email or phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Input in 3D Recessed ClayTextField
                  ClayTextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
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

                  // Submit Button in 3D ClayButton
                  ClayButton(
                    text: 'Sign In',
                    icon: Icons.login_rounded,
                    isLoading: authProvider.isLoading,
                    onPressed: authProvider.isLoading ? null : _handleLogin,
                  ),

                  // Biometrics Login Button in 3D ClayButton
                  if (authProvider.isBiometricAvailable) ...[
                    const SizedBox(height: 16),
                    ClayButton(
                      text: 'Quick Biometric Login',
                      icon: Icons.fingerprint_rounded,
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      textColor: primaryColor,
                      onPressed: _handleBiometricsLogin,
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

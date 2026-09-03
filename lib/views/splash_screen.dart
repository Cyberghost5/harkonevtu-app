import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_config_provider.dart';
import '../core/storage/secure_storage_service.dart';
import 'maintenance_screen.dart';
import 'force_update_screen.dart';
import 'onboarding_screen.dart';
import 'auth/login_screen.dart';

import 'navigation/main_navigation_shell.dart';

class SplashScreen extends StatefulWidget {
  final Function(Widget) onNavigate;

  const SplashScreen({super.key, required this.onNavigate});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final configProvider = Provider.of<AppConfigProvider>(context, listen: false);
    
    // Fetch config from GET /api/v1/app-config
    await configProvider.fetchAppConfig();

    if (!mounted) return;

    // Check maintenance mode
    if (configProvider.isMaintenance) {
      widget.onNavigate(const MaintenanceScreen());
      return;
    }

    // Check force update
    if (configProvider.isForceUpdate) {
      widget.onNavigate(const ForceUpdateScreen());
      return;
    }

    // Check secure storage for token & onboarding status
    final storage = SecureStorageService();
    final isFirstTime = await storage.isFirstTimeInstall();
    final token = await storage.getToken();

    if (!mounted) return;

    if (isFirstTime) {
      widget.onNavigate(
        OnboardingScreen(
          onFinishOnboarding: () {
            _navigateToAuthOrMain(token);
          },
        ),
      );
    } else {
      _navigateToAuthOrMain(token);
    }
  }

  void _navigateToAuthOrMain(String? token) {
    if (token != null && token.isNotEmpty) {
      // Valid session -> Main App Shell
      widget.onNavigate(MainNavigationShell(onNavigate: widget.onNavigate));
    } else {
      // No token -> Login Screen
      widget.onNavigate(
        LoginScreen(
          onNavigate: widget.onNavigate,
          onLoginSuccess: () {
            widget.onNavigate(MainNavigationShell(onNavigate: widget.onNavigate));
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<AppConfigProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF020617)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dynamic Logo with subtle glow border
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: configProvider.config?.logo1Url != null &&
                        configProvider.config!.logo1Url!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: configProvider.config!.logo1Url!,
                        height: 72,
                        width: 72,
                        errorWidget: (_, _, _) => Icon(
                          Icons.bolt_rounded,
                          size: 72,
                          color: primaryColor,
                        ),
                      )
                    : Icon(
                        Icons.bolt_rounded,
                        size: 72,
                        color: primaryColor,
                      ),
              ),
              const SizedBox(height: 28),

              // App Name (only rendered when loaded from config)
              if (configProvider.appName.isNotEmpty) ...[
                Text(
                  configProvider.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                ),
                const SizedBox(height: 8),
              ],

              Text(
                'Fast • Secure • Automated VTU',
                style: TextStyle(
                  color: const Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),

              // Loading Spinner
              SpinKitThreeBounce(
                color: primaryColor,
                size: 24.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

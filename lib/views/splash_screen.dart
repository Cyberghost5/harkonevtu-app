import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_config_provider.dart';
import '../core/storage/secure_storage_service.dart';
import 'widgets/clay_container.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dynamic 3D Claymorphism Logo Container
              ClayContainer(
                depth: 18,
                spread: 4,
                cornerRadius: 50,
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: configProvider.config?.logo1Url != null &&
                          configProvider.config!.logo1Url!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: CachedNetworkImage(
                            imageUrl: configProvider.config!.logo1Url!,
                            height: 72,
                            width: 72,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => Icon(
                              Icons.bolt_rounded,
                              size: 72,
                              color: primaryColor,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.bolt_rounded,
                          size: 72,
                          color: primaryColor,
                        ),
                ),
              ),
              const SizedBox(height: 28),

              // App Name (only rendered when loaded from config)
              if (configProvider.appName.isNotEmpty) ...[
                Text(
                  configProvider.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: 1.1,
                      ),
                ),
                const SizedBox(height: 8),
              ],

              Text(
                'Fast • Secure • Automated VTU',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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


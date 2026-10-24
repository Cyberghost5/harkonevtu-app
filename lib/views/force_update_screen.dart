import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_config_provider.dart';
import 'splash_screen.dart';
import 'widgets/clay_container.dart';
import 'widgets/clay_button.dart';

class ForceUpdateScreen extends StatefulWidget {
  final Function(Widget)? onNavigate;

  const ForceUpdateScreen({super.key, this.onNavigate});

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen> with WidgetsBindingObserver {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns to the app from Play Store or browser, automatically recheck
    if (state == AppLifecycleState.resumed) {
      _checkUpdateStatus(silent: true);
    }
  }

  Future<void> _checkUpdateStatus({bool silent = false}) async {
    if (_isChecking) return;
    if (!silent) {
      setState(() => _isChecking = true);
    }

    final configProvider = Provider.of<AppConfigProvider>(context, listen: false);
    await configProvider.fetchAppConfig();

    if (!mounted) return;

    if (!configProvider.isForceUpdate) {
      // Version requirement satisfied! Proceed into app
      if (widget.onNavigate != null) {
        widget.onNavigate!(SplashScreen(onNavigate: widget.onNavigate!));
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SplashScreen(
              onNavigate: (screen) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => screen),
                );
              },
            ),
          ),
        );
      }
    } else {
      if (!silent) {
        setState(() => _isChecking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Your installed version is v${configProvider.installedVersion}. Please install v${configProvider.serverAppVersion} to continue.',
            ),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openUpdateStore(BuildContext context) async {
    final configProvider = Provider.of<AppConfigProvider>(context, listen: false);

    List<String> candidateUrls = [];

    // 1. Check for brand-specific URLs returned dynamically from backend API
    if (configProvider.updateUrl != null && configProvider.updateUrl!.isNotEmpty) {
      candidateUrls.add(configProvider.updateUrl!);
    }
    if (configProvider.playStoreUrl != null && configProvider.playStoreUrl!.isNotEmpty) {
      candidateUrls.add(configProvider.playStoreUrl!);
    }
    if (configProvider.appStoreUrl != null && configProvider.appStoreUrl!.isNotEmpty) {
      candidateUrls.add(configProvider.appStoreUrl!);
    }

    // 2. Dynamically get current brand's package name at runtime
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;
      if (packageName.isNotEmpty) {
        candidateUrls.add('market://details?id=$packageName');
        candidateUrls.add('https://play.google.com/store/apps/details?id=$packageName');
      }
    } catch (_) {}

    bool launched = false;
    for (final urlStr in candidateUrls) {
      try {
        final Uri uri = Uri.parse(urlStr);
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          launched = true;
          break;
        }
      } catch (_) {}
    }

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open store link. Please search for the app on Google Play Store.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<AppConfigProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final installedVer = configProvider.installedVersion;
    final latestVer = configProvider.serverAppVersion;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClayContainer(
                    depth: 16,
                    spread: 4,
                    cornerRadius: 50,
                    color: primaryColor.withValues(alpha: 0.15),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Icon(
                        Icons.system_update_rounded,
                        size: 64,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    'App Update Required',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'A new version of the app is available with critical performance upgrades, security patches, and new features. Please update to continue.',
                    style: TextStyle(
                      color: subColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Version Details Badge
                  ClayContainer(
                    depth: 6,
                    borderRadius: 16,
                    color: cardBg,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Installed Version',
                              style: TextStyle(fontSize: 11, color: subColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'v$installedVer',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 30,
                          width: 1,
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                        Column(
                          children: [
                            Text(
                              'Latest Version',
                              style: TextStyle(fontSize: 11, color: subColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'v$latestVer',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Update Now Button
                  ClayButton(
                    height: 54,
                    depth: 14,
                    color: primaryColor,
                    onPressed: () => _openUpdateStore(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Update Now',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Re-check / I've already updated button
                  TextButton.icon(
                    onPressed: _isChecking ? null : () => _checkUpdateStatus(silent: false),
                    icon: _isChecking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.refresh_rounded, size: 18, color: subColor),
                    label: Text(
                      _isChecking ? 'Checking update status...' : "I've already updated / Re-check",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: subColor,
                      ),
                    ),
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

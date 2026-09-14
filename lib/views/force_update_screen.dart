import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_config_provider.dart';
import 'widgets/clay_container.dart';
import 'widgets/clay_button.dart';

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

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

    // 2. Dynamically get current brand's package name at runtime (e.g. com.brand1.app)
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
          content: Text('Could not open store link. Please search for the app on Play Store.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(28.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        ),
        child: Center(
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
              const SizedBox(height: 32),
              Text(
                'Update Required',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'A new version of the app is available with critical improvements and features. Please update to continue using the app.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
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
                    Text('Update Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


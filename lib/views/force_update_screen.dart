import 'package:flutter/material.dart';
import 'widgets/clay_container.dart';
import 'widgets/clay_button.dart';

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

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
                onTap: () {
                  // Open App store / Play store URL
                },
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


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_config_provider.dart';
import 'widgets/clay_container.dart';
import 'widgets/clay_button.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<AppConfigProvider>(context);
    final message = configProvider.maintenanceMessage;
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
                color: Colors.amber.withValues(alpha: 0.15),
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Icon(
                    Icons.construction_rounded,
                    size: 64,
                    color: Colors.amber,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Under Maintenance',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ClayButton(
                height: 52,
                width: 180,
                depth: 12,
                color: Theme.of(context).primaryColor,
                onTap: () => configProvider.fetchAppConfig(),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Check Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_config_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/vtu_provider.dart';
import 'providers/bills_provider.dart';
import 'providers/specialized_provider.dart';
import 'core/theme/dynamic_theme.dart';
import 'views/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HarkoneVtuApp());
}

class HarkoneVtuApp extends StatefulWidget {
  const HarkoneVtuApp({super.key});

  @override
  State<HarkoneVtuApp> createState() => _HarkoneVtuAppState();
}

class _HarkoneVtuAppState extends State<HarkoneVtuApp> {
  Widget? _currentScreen;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppConfigProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => VtuProvider()),
        ChangeNotifierProvider(create: (_) => BillsProvider()),
        ChangeNotifierProvider(create: (_) => SpecializedProvider()),
      ],
      child: Consumer<AppConfigProvider>(
        builder: (context, configProvider, child) {
          final themeColor = configProvider.themeColorHex;

          return MaterialApp(
            title: configProvider.appName,
            debugShowCheckedModeBanner: false,
            theme: DynamicTheme.buildLightTheme(themeColor),
            darkTheme: DynamicTheme.buildDarkTheme(themeColor),
            themeMode: configProvider.themeMode,
            home: _currentScreen ??
                SplashScreen(
                  onNavigate: (screen) {
                    setState(() {
                      _currentScreen = screen;
                    });
                  },
                ),
          );
        },
      ),
    );
  }
}

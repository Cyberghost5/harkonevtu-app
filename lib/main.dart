import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/notification_service.dart';
import 'providers/app_config_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/vtu_provider.dart';
import 'providers/bills_provider.dart';
import 'providers/specialized_provider.dart';
import 'core/theme/dynamic_theme.dart';
import 'views/splash_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/navigation/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await NotificationService().initialize();
  } catch (e) {
    developer.log('Firebase initialization notice (place google-services.json in android/app/): $e');
  }

  runApp(const HarkoneVtuApp());
}

class HarkoneVtuApp extends StatefulWidget {
  const HarkoneVtuApp({super.key});

  @override
  State<HarkoneVtuApp> createState() => _HarkoneVtuAppState();
}

class _HarkoneVtuAppState extends State<HarkoneVtuApp> {
  Widget? _currentScreen;

  void _navigateTo(Widget screen) {
    setState(() {
      _currentScreen = screen;
    });
  }

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
            builder: (context, child) {
              return SessionInactivityTracker(
                onNavigate: _navigateTo,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: _currentScreen ??
                SplashScreen(
                  onNavigate: _navigateTo,
                ),
          );
        },
      ),
    );
  }
}

class SessionInactivityTracker extends StatefulWidget {
  final Widget child;
  final Function(Widget) onNavigate;

  const SessionInactivityTracker({
    super.key,
    required this.child,
    required this.onNavigate,
  });

  @override
  State<SessionInactivityTracker> createState() => _SessionInactivityTrackerState();
}

class _SessionInactivityTrackerState extends State<SessionInactivityTracker> with WidgetsBindingObserver {
  DateTime _lastActivity = DateTime.now();
  DateTime? _backgroundTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _checkInactivity());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _recordActivity() {
    _lastActivity = DateTime.now();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _backgroundTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_backgroundTime != null) {
        final elapsed = DateTime.now().difference(_backgroundTime!).inMinutes;
        _backgroundTime = null;
        _checkInactivity(forceCheckElapsed: elapsed);
      }
    }
  }

  void _checkInactivity({int? forceCheckElapsed}) async {
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) return;

    final config = Provider.of<AppConfigProvider>(context, listen: false);
    final timeoutMinutes = config.sessionIdleTimeout;
    if (timeoutMinutes <= 0) return;

    final elapsed = forceCheckElapsed ?? DateTime.now().difference(_lastActivity).inMinutes;

    if (elapsed >= timeoutMinutes) {
      _lastActivity = DateTime.now();
      await auth.handleSessionTimeout();

      if (!mounted) return;

      widget.onNavigate(
        LoginScreen(
          onNavigate: widget.onNavigate,
          onLoginSuccess: () {
            widget.onNavigate(MainNavigationShell(onNavigate: widget.onNavigate));
          },
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session timed out due to inactivity. Please login with biometrics or password.'),
          backgroundColor: Colors.amber,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _recordActivity(),
      onPointerMove: (_) => _recordActivity(),
      child: widget.child,
    );
  }
}


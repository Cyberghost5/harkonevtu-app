import 'package:flutter/material.dart';
import '../core/services/connectivity_service.dart';
import 'widgets/clay_container.dart';
import 'widgets/clay_button.dart';

class OfflineScreen extends StatefulWidget {
  final VoidCallback onRetry;

  const OfflineScreen({
    super.key,
    required this.onRetry,
  });

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> with SingleTickerProviderStateMixin {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isChecking = false;
  String _statusMessage = 'Offline';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      _statusMessage = 'Checking connection...';
    });

    final hasInternet = await _connectivityService.hasInternetConnection();

    if (!mounted) return;

    if (hasInternet) {
      setState(() {
        _statusMessage = 'Connected!';
      });
      await Future.delayed(const Duration(milliseconds: 500));
      widget.onRetry();
    } else {
      setState(() {
        _isChecking = false;
        _statusMessage = 'Still Offline. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No active internet connection found.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final containerColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated 3D Claymorphic Offline Icon Container
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: ClayContainer(
                  depth: 22,
                  spread: 6,
                  cornerRadius: 60,
                  color: containerColor,
                  child: Container(
                    width: 120,
                    height: 120,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 64,
                          color: primaryColor,
                        ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: ClayContainer(
                            depth: 10,
                            spread: 2,
                            cornerRadius: 20,
                            color: Colors.redAccent.shade400,
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.priority_high_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Headline & Description
              Text(
                'No Internet Connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your device is currently offline. Please check your Wi-Fi or mobile data connection to proceed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: subtextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 28),

              // Network Status Clay Badge
              ClayContainer(
                depth: 8,
                spread: 2,
                cornerRadius: 20,
                color: containerColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isChecking
                              ? Colors.amber
                              : (_statusMessage.contains('Connected') ? Colors.green : Colors.redAccent),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Interactive 3D Clay Retry Button
              ClayButton(
                onTap: _isChecking ? null : _handleRetry,
                color: primaryColor,
                borderRadius: 16,
                depth: 14,
                isLoading: _isChecking,
                text: 'Retry Connection',
                icon: Icons.refresh_rounded,
              ),
              const SizedBox(height: 16),
            ],
          ),

        ),
      ),
    );
  }
}

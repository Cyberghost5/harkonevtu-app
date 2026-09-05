import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_config_provider.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/app_config_model.dart';
import 'widgets/clay_container.dart';
import 'widgets/clay_button.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinishOnboarding;

  const OnboardingScreen({super.key, required this.onFinishOnboarding});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDone() async {
    await SecureStorageService().setFirstTimeCompleted();
    widget.onFinishOnboarding();
  }

  IconData _getSlideIcon(int index) {
    switch (index) {
      case 0:
        return Icons.bolt_rounded;
      case 1:
        return Icons.receipt_long_rounded;
      case 2:
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.stars_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<AppConfigProvider>(context);
    final slides = configProvider.config?.onboardingSlides ?? [];
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with 3D Logo Badge & 3D Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClayContainer(
                        depth: 10,
                        cornerRadius: 50,
                        color: primaryColor.withValues(alpha: 0.15),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: configProvider.config?.logo1Url != null &&
                                  configProvider.config!.logo1Url!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: CachedNetworkImage(
                                    imageUrl: configProvider.config!.logo1Url!,
                                    height: 24,
                                    width: 24,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, _, _) => Icon(Icons.bolt_rounded, color: primaryColor, size: 24),
                                  ),
                                )
                              : Icon(Icons.bolt_rounded, color: primaryColor, size: 24),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        configProvider.appName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                      ),
                    ],
                  ),
                  ClayButton(
                    height: 36,
                    width: 76,
                    depth: 8,
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    onTap: _onDone,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  return _buildSlideCard(slide, index, primaryColor, isDark);
                },
              ),
            ),

            // Bottom Navigation Controls
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // 3D Clay Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (index) {
                        final isSelected = _currentIndex == index;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ClayContainer(
                            depth: isSelected ? 8 : 4,
                            cornerRadius: 10,
                            color: isSelected
                                ? primaryColor
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 10,
                              width: isSelected ? 32 : 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Next / Get Started Button (3D ClayButton)
                  ClayButton(
                    height: 54,
                    depth: 14,
                    color: primaryColor,
                    onTap: () {
                      if (_currentIndex < slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _onDone();
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentIndex == slides.length - 1 ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentIndex == slides.length - 1 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideCard(OnboardingSlideModel slide, int index, Color primaryColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration / Image Container (3D Clay)
          ClayContainer(
            depth: 16,
            cornerRadius: 28,
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            child: Container(
              height: 240,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: slide.imageUrl != null && slide.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(
                        imageUrl: slide.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => _buildFallbackIllustration(index, primaryColor),
                      ),
                    )
                  : _buildFallbackIllustration(index, primaryColor),
            ),
          ),
          const SizedBox(height: 40),

          // Slide Title
          Text(
            slide.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Slide Description
          Text(
            slide.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.5,
                  fontSize: 15,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIllustration(int index, Color primaryColor) {
    return Center(
      child: ClayContainer(
        depth: 12,
        cornerRadius: 50,
        color: primaryColor.withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Icon(
            _getSlideIcon(index),
            size: 72,
            color: primaryColor,
          ),
        ),
      ),
    );
  }
}



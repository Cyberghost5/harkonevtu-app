import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_config_provider.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/app_config_model.dart';

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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (configProvider.config?.logo1Url != null &&
                          configProvider.config!.logo1Url!.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: configProvider.config!.logo1Url!,
                          height: 32,
                          errorWidget: (_, _, _) => const Icon(Icons.bolt, color: Colors.white),
                        )
                      else
                        Icon(Icons.bolt_rounded, color: primaryColor, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        configProvider.appName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _onDone,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
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
                  return _buildSlideCard(slide, index, primaryColor);
                },
              ),
            ),

            // Bottom Navigation Controls
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentIndex == index ? 28 : 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? primaryColor
                              : const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Next / Get Started Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentIndex < slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _onDone();
                        }
                      },
                      child: Text(
                        _currentIndex == slides.length - 1 ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildSlideCard(OnboardingSlideModel slide, int index, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration / Image Container
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.15),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: slide.imageUrl != null && slide.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CachedNetworkImage(
                      imageUrl: slide.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _buildFallbackIllustration(index, primaryColor),
                    ),
                  )
                : _buildFallbackIllustration(index, primaryColor),
          ),
          const SizedBox(height: 40),

          // Slide Title
          Text(
            slide.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Slide Description
          Text(
            slide.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF94A3B8),
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
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getSlideIcon(index),
          size: 72,
          color: primaryColor,
        ),
      ),
    );
  }
}

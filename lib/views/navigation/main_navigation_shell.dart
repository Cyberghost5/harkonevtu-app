import 'dart:ui';
import 'package:flutter/material.dart';
import '../home/home_dashboard_view.dart';
import '../services/services_grid_view.dart';
import '../wallet/wallet_view.dart';
import '../profile/profile_view.dart';

class MainNavigationShell extends StatefulWidget {
  final Function(Widget) onNavigate;

  const MainNavigationShell({super.key, required this.onNavigate});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _navItems = const [
    {'label': 'Home', 'icon': Icons.home_rounded, 'activeIcon': Icons.home_rounded},
    {'label': 'Services', 'icon': Icons.grid_view_outlined, 'activeIcon': Icons.grid_view_rounded},
    {'label': 'Wallet', 'icon': Icons.account_balance_wallet_outlined, 'activeIcon': Icons.account_balance_wallet_rounded},
    {'label': 'Profile', 'icon': Icons.person_outline_rounded, 'activeIcon': Icons.person_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final pages = [
      HomeDashboardView(
        onTabSwitch: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      const ServicesGridView(),
      const WalletView(),
      ProfileView(onNavigate: widget.onNavigate),
    ];

    final navGlassBg = isDark
        ? const Color(0xFF151C2C).withValues(alpha: 0.75)
        : Colors.white.withValues(alpha: 0.85);

    final navBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : primaryColor.withValues(alpha: 0.2);

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.02, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: navGlassBg,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: navBorderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.4)
                          : primaryColor.withValues(alpha: 0.12),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_navItems.length, (index) {
                    final isSelected = _currentIndex == index;
                    final item = _navItems[index];

                    return GestureDetector(
                      onTap: () {
                        setState(() => _currentIndex = index);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? Border.all(color: primaryColor.withValues(alpha: 0.4), width: 1)
                              : Border.all(color: Colors.transparent, width: 1),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.2),
                                    blurRadius: 12,
                                    spreadRadius: 0,
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? item['activeIcon'] as IconData : item['icon'] as IconData,
                              color: isSelected
                                  ? primaryColor
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              size: 22,
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: isSelected ? 1.0 : 0.0,
                                child: Text(
                                  item['label'] as String,
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

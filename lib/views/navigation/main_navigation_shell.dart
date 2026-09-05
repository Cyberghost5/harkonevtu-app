import 'dart:ui';
import 'package:flutter/material.dart';
import '../home/home_dashboard_view.dart';
import '../services/services_grid_view.dart';
import '../wallet/wallet_view.dart';
import '../profile/profile_view.dart';

import '../widgets/clay_container.dart';

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

    final navBg = isDark ? const Color(0xFF151C2C) : Colors.white;

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
          child: ClayContainer(
            borderRadius: 26,
            depth: 12,
            color: navBg,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (index) {
                final isSelected = _currentIndex == index;
                final item = _navItems[index];

                Widget tabChild = Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                );

                return GestureDetector(
                  onTap: () {
                    setState(() => _currentIndex = index);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: isSelected
                      ? ClayContainer(
                          borderRadius: 20,
                          depth: 6,
                          isRecessed: true,
                          color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                          child: tabChild,
                        )
                      : tabChild,
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

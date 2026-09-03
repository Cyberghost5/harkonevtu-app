import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/receipt_modal.dart';

class HomeDashboardView extends StatefulWidget {
  final Function(int) onTabSwitch;

  const HomeDashboardView({super.key, required this.onTabSwitch});

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final configProvider = Provider.of<AppConfigProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);

    final user = authProvider.user;
    final primaryColor = Theme.of(context).primaryColor;
    final currencySymbol = configProvider.currencySymbol;
    final services = configProvider.config?.services;

    final balance = user?.wallet?.balance ?? 0.0;
    final formattedBalance = '$currencySymbol${balance.toStringAsFixed(2)}';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await authProvider.fetchProfile();
            await dashboardProvider.fetchDashboardData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: primaryColor.withValues(alpha: 0.2),
                          child: Icon(Icons.person_rounded, color: primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${user?.name ?? 'User'} 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '@${user?.username ?? 'user'}',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Glassmorphic Wallet Balance Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor.withValues(alpha: 0.35),
                        primaryColor.withValues(alpha: 0.1),
                        const Color(0xFF1E293B),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet_rounded,
                                  color: Colors.white70, size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                'Wallet Balance',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              dashboardProvider.hideBalance
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white70,
                              size: 20,
                            ),
                            onPressed: () => dashboardProvider.toggleHideBalance(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Balance display with blur when hidden
                      dashboardProvider.hideBalance
                          ? ImageFilterWidget(
                              child: Text(
                                formattedBalance,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : Text(
                              formattedBalance,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),

                      const SizedBox(height: 20),

                      // Action button row
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => widget.onTabSwitch(2), // Switch to Wallet Tab
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                              label: const Text('Fund Wallet',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Dedicated Virtual Bank Account Card (DVA)
                _buildDvaCard(context, dashboardProvider, primaryColor),
                const SizedBox(height: 28),

                // Quick Services Section Header
                const Text(
                  'Quick Services',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Dynamic Quick Actions Grid based on AppConfig toggles
                _buildQuickActionsGrid(context, services, primaryColor),
                const SizedBox(height: 28),

                // Recent Transactions Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => widget.onTabSwitch(2),
                      child: Text(
                        'View All',
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Transactions List
                _buildRecentTransactionsList(context, dashboardProvider, currencySymbol),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDvaCard(
      BuildContext context, DashboardProvider dashboardProvider, Color primaryColor) {
    final dvaList = dashboardProvider.dvaAccounts;

    if (dashboardProvider.isLoadingDva) {
      return Container(
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: SpinKitThreeBounce(color: primaryColor, size: 18)),
      );
    }

    final dva = dvaList.isNotEmpty ? dvaList.first : null;
    final bankName = dva?.bankName ?? 'Wema Bank';
    final accountNo = dva?.accountNumber ?? 'Generating DVA...';
    final accountName = dva?.accountName ?? 'Harkone Virtual Wallet';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF192234),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B364E)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.account_balance_rounded, color: primaryColor, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bankName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    accountNo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    accountName,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          if (dva != null && accountNo.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: Color(0xFF94A3B8), size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: accountNo));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$bankName account number copied!'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: primaryColor,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(
      BuildContext context, dynamic services, Color primaryColor) {
    final actions = <Map<String, dynamic>>[];

    if (services?.airtime ?? true) {
      actions.add({'title': 'Airtime', 'icon': Icons.phone_android_rounded, 'color': const Color(0xFF3B82F6)});
    }
    if (services?.data ?? true) {
      actions.add({'title': 'Data Bundle', 'icon': Icons.wifi_rounded, 'color': const Color(0xFF10B981)});
    }
    if (services?.electricity ?? true) {
      actions.add({'title': 'Electricity', 'icon': Icons.lightbulb_rounded, 'color': const Color(0xFFA855F7)});
    }
    if (services?.cable ?? true) {
      actions.add({'title': 'Cable TV', 'icon': Icons.tv_rounded, 'color': const Color(0xFFF59E0B)});
    }
    if (services?.epin ?? true) {
      actions.add({'title': 'Exam PINs', 'icon': Icons.school_rounded, 'color': const Color(0xFFEC4899)});
    }
    if (services?.betting ?? true) {
      actions.add({'title': 'Betting', 'icon': Icons.sports_soccer_rounded, 'color': const Color(0xFF06B6D4)});
    }
    if (services?.airtimeToCash ?? true) {
      actions.add({'title': 'Airtime to Cash', 'icon': Icons.currency_exchange_rounded, 'color': const Color(0xFF84CC16)});
    }
    if (services?.rechargeCardPrinting ?? false) {
      actions.add({'title': 'Print Cards', 'icon': Icons.print_rounded, 'color': const Color(0xFF6366F1)});
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final item = actions[index];
        final itemColor = item['color'] as Color;

        return GestureDetector(
          onTap: () {
            // Switch to Services tab
            widget.onTabSwitch(1);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: itemColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: itemColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(item['icon'] as IconData, color: itemColor, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                item['title'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentTransactionsList(
      BuildContext context, DashboardProvider dashboardProvider, String currencySymbol) {
    if (dashboardProvider.isLoadingTransactions) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: SpinKitThreeBounce(color: Theme.of(context).primaryColor, size: 20)),
      );
    }

    final list = dashboardProvider.recentTransactions;

    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2234),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF232D42)),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.history_rounded, size: 40, color: Color(0xFF64748B)),
              SizedBox(height: 8),
              Text(
                'No transactions yet.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length > 5 ? 5 : list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final tx = list[index];
        final isDebit = tx.type == 'debit';
        final isSuccess = tx.status.toLowerCase() == 'success';

        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => ReceiptModal(transaction: tx, currencySymbol: currencySymbol),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2234),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF232D42)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDebit
                        ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                        : const Color(0xFF10B981).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    color: isDebit ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tx.humanDate.isNotEmpty ? tx.humanDate : tx.date,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isDebit ? '-' : '+'}$currencySymbol${tx.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isDebit ? Colors.white : const Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.status.toUpperCase(),
                      style: TextStyle(
                        color: isSuccess ? const Color(0xFF10B981) : Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ImageFilterWidget extends StatelessWidget {
  final Widget child;
  const ImageFilterWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: child,
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/receipt_modal.dart';
import '../vtu/airtime_topup_screen.dart';
import '../vtu/data_bundles_screen.dart';
import '../bills/electricity_bills_screen.dart';
import '../bills/cable_tv_screen.dart';
import '../bills/exam_pins_screen.dart';
import '../specialized/betting_topup_screen.dart';
import '../specialized/airtime_to_cash_screen.dart';
import '../specialized/voucher_printing_screen.dart';
import '../wallet/wallet_view.dart';

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
      Provider.of<AuthProvider>(context, listen: false).fetchProfile();
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

    final rawName = user?.name.trim() ?? '';
    final rawUsername = user?.username.trim() ?? '';

    final displayName = rawName.isNotEmpty
        ? rawName
        : (rawUsername.isNotEmpty ? rawUsername : 'User');

    final avatarUrl = user?.avatar;
    final bool hasAvatar = avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://'));

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
                // Top Header Bar - Tapping user info navigates to Profile Tab (index 3)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => widget.onTabSwitch(3),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: primaryColor.withValues(alpha: 0.2),
                            backgroundImage: hasAvatar ? CachedNetworkImageProvider(avatarUrl) : null,
                            child: !hasAvatar ? Icon(Icons.person_rounded, color: primaryColor) : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $displayName 👋',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                rawUsername.isNotEmpty ? '@$rawUsername' : 'Tap to view profile',
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WalletView(initialTabIndex: 2),
                          ),
                        );
                      },
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

    if (dvaList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF192234),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.account_balance_wallet_outlined, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Virtual Account Generated',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Generate a dedicated bank account for 1-tap instant wallet funding',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => _showBvnModal(context, dashboardProvider),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                backgroundColor: primaryColor,
              ),
              child: const Text('Generate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    final dva = dvaList.first;
    final bankName = dva.bankName;
    final accountNo = dva.accountNumber;
    final accountName = dva.accountName;

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

  void _showBvnModal(BuildContext context, DashboardProvider dashboardProvider) {
    final bvnController = TextEditingController();
    final primaryColor = Theme.of(context).primaryColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF151C2C),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.shield_outlined, color: primaryColor, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Generate Virtual Account',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'CBN Verification Requirement',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Please enter your 11-digit Bank Verification Number (BVN) to create your dedicated bank account for instant wallet funding.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: bvnController,
                      keyboardType: TextInputType.number,
                      maxLength: 11,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2.0),
                      decoration: const InputDecoration(
                        labelText: 'Enter 11-Digit BVN',
                        prefixIcon: Icon(Icons.fingerprint_rounded, color: Color(0xFF94A3B8)),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final bvn = bvnController.text.trim();
                                if (bvn.length != 11) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('BVN must be exactly 11 digits.'),
                                      backgroundColor: Color(0xFFEF4444),
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isSubmitting = true);
                                final response = await dashboardProvider.generateDva(bvn);

                                if (!context.mounted) return;

                                if (response.status) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(response.message.isNotEmpty
                                          ? response.message
                                          : 'Virtual Bank Account generated successfully!'),
                                      backgroundColor: const Color(0xFF10B981),
                                    ),
                                  );
                                } else {
                                  setModalState(() => isSubmitting = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(response.message),
                                      backgroundColor: const Color(0xFFEF4444),
                                    ),
                                  );
                                }
                              },
                        child: isSubmitting
                            ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                            : const Text('Submit BVN & Generate Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActionsGrid(
      BuildContext context, dynamic services, Color primaryColor) {
    final actions = <Map<String, dynamic>>[];

    if (services?.airtime ?? true) {
      actions.add({'key': 'airtime', 'title': 'Airtime', 'icon': Icons.phone_android_rounded, 'color': const Color(0xFF3B82F6)});
    }
    if (services?.data ?? true) {
      actions.add({'key': 'data', 'title': 'Data Bundle', 'icon': Icons.wifi_rounded, 'color': const Color(0xFF10B981)});
    }
    if (services?.electricity ?? true) {
      actions.add({'key': 'electricity', 'title': 'Electricity', 'icon': Icons.lightbulb_rounded, 'color': const Color(0xFFA855F7)});
    }
    if (services?.cable ?? true) {
      actions.add({'key': 'cable', 'title': 'Cable TV', 'icon': Icons.tv_rounded, 'color': const Color(0xFFF59E0B)});
    }
    if (services?.epin ?? true) {
      actions.add({'key': 'epin', 'title': 'Exam PINs', 'icon': Icons.school_rounded, 'color': const Color(0xFFEC4899)});
    }
    if (services?.betting ?? true) {
      actions.add({'key': 'betting', 'title': 'Betting', 'icon': Icons.sports_soccer_rounded, 'color': const Color(0xFF06B6D4)});
    }
    if (services?.airtimeToCash ?? true) {
      actions.add({'key': 'airtimeToCash', 'title': 'Airtime to Cash', 'icon': Icons.currency_exchange_rounded, 'color': const Color(0xFF84CC16)});
    }
    if (services?.rechargeCardPrinting ?? true) {
      actions.add({'key': 'rechargeCardPrinting', 'title': 'Airtime PINs', 'icon': Icons.print_rounded, 'color': const Color(0xFF6366F1)});
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
            final key = item['key'] as String;
            Widget targetScreen;
            switch (key) {
              case 'airtime':
                targetScreen = const AirtimeTopupScreen();
                break;
              case 'data':
                targetScreen = const DataBundlesScreen();
                break;
              case 'electricity':
                targetScreen = const ElectricityBillsScreen();
                break;
              case 'cable':
                targetScreen = const CableTvScreen();
                break;
              case 'epin':
                targetScreen = const ExamPinsScreen();
                break;
              case 'betting':
                targetScreen = const BettingTopupScreen();
                break;
              case 'airtimeToCash':
                targetScreen = const AirtimeToCashScreen();
                break;
              case 'rechargeCardPrinting':
                targetScreen = const VoucherPrintingScreen();
                break;
              default:
                widget.onTabSwitch(1);
                return;
            }
            Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
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

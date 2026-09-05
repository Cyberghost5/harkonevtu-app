import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/specialized_provider.dart';
import '../../core/utils/formatters.dart';
import '../widgets/receipt_modal.dart';
import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_text_field.dart';

class WalletView extends StatefulWidget {
  final int initialTabIndex;
  const WalletView({super.key, this.initialTabIndex = 0});

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final configProvider = Provider.of<AppConfigProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);

    final user = authProvider.user;
    final primaryColor = Theme.of(context).primaryColor;
    final currencySymbol = configProvider.currencySymbol;

    final balance = user?.wallet?.balance ?? 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleCol = isDark ? Colors.white : const Color(0xFF0F172A);
    final subCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet & Funding'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: subCol,
          tabs: const [
            Tab(text: 'Virtual Accounts'),
            Tab(text: 'Redeem Coupon'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Virtual Bank Accounts
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wallet Overview Card (3D Clay)
                ClayContainer(
                  depth: 14,
                  cornerRadius: 24,
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Wallet Balance',
                              style: TextStyle(color: subCol, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppFormatters.formatCurrency(balance, currencySymbol),
                              style: TextStyle(
                                color: titleCol,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        ClayContainer(
                          depth: 10,
                          cornerRadius: 50,
                          color: primaryColor.withValues(alpha: 0.2),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(Icons.account_balance_wallet_rounded, color: primaryColor, size: 28),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Automated Virtual Bank Accounts',
                  style: TextStyle(color: titleCol, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Transfer money to any of these assigned accounts to fund your wallet instantly 24/7.',
                  style: TextStyle(color: subCol, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Accounts List
                dashboardProvider.dvaAccounts.isEmpty
                    ? ClayContainer(
                        depth: 8,
                        cornerRadius: 18,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: primaryColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Virtual bank account details will appear here once generated for your profile.',
                                  style: TextStyle(color: subCol, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dashboardProvider.dvaAccounts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final dva = dashboardProvider.dvaAccounts[index];
                          return ClayContainer(
                            depth: 10,
                            cornerRadius: 20,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dva.bankName,
                                        style: TextStyle(
                                          color: titleCol,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dva.accountNumber,
                                        style: TextStyle(
                                          color: titleCol,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dva.accountName,
                                        style: TextStyle(color: subCol, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  ClayButton(
                                    height: 38,
                                    width: 90,
                                    depth: 8,
                                    color: primaryColor,
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: dva.accountNumber));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${dva.bankName} account number copied!'),
                                          backgroundColor: primaryColor,
                                        ),
                                      );
                                    },
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.copy_rounded, size: 14, color: Colors.white),
                                        SizedBox(width: 6),
                                        Text('Copy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),

          // Tab 2: Coupon Redemption
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Redeem Funding Coupon',
                  style: TextStyle(color: titleCol, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Have a funding voucher or promo coupon code? Enter it below to credit your wallet instantly.',
                  style: TextStyle(color: subCol, fontSize: 13),
                ),
                const SizedBox(height: 28),

                ClayTextField(
                  controller: _couponController,
                  hintText: 'e.g. HARKONE5000',
                  labelText: 'Coupon Code',
                  prefixIcon: Icons.card_giftcard_rounded,
                ),
                const SizedBox(height: 28),

                ClayButton(
                  height: 54,
                  depth: 12,
                  color: primaryColor,
                  onTap: () async {
                    final code = _couponController.text.trim();
                    if (code.isEmpty) return;
                    final specProvider = Provider.of<SpecializedProvider>(context, listen: false);
                    final res = await specProvider.redeemCoupon(code);
                    if (!context.mounted) return;
                    if (res.status) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.message.isNotEmpty ? res.message : 'Coupon redeemed successfully!'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                      _couponController.clear();
                      await authProvider.fetchProfile();
                      await dashboardProvider.fetchDashboardData();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.message),
                          backgroundColor: const Color(0xFFEF4444),
                        ),
                      );
                    }
                  },
                  child: const Text('Redeem Coupon', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Tab 3: Full Transaction History List
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: dashboardProvider.recentTransactions.isEmpty
                ? Center(
                    child: Text(
                      'No transaction history found.',
                      style: TextStyle(color: subCol),
                    ),
                  )
                : ListView.separated(
                    itemCount: dashboardProvider.recentTransactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tx = dashboardProvider.recentTransactions[index];
                      final isDebit = tx.type == 'debit';
                      return ClayContainer(
                        depth: 8,
                        cornerRadius: 18,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (_) => ReceiptModal(transaction: tx, currencySymbol: currencySymbol),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  ClayContainer(
                                    depth: 6,
                                    cornerRadius: 50,
                                    color: isDebit
                                        ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                        : const Color(0xFF10B981).withValues(alpha: 0.15),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Icon(
                                        isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                        color: isDebit ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.title,
                                          style: TextStyle(color: titleCol, fontWeight: FontWeight.bold, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          tx.formattedDate,
                                          style: TextStyle(color: subCol, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${isDebit ? '-' : '+'}${AppFormatters.formatCurrency(tx.amount, currencySymbol)}',
                                    style: TextStyle(
                                      color: isDebit ? titleCol : const Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/specialized_provider.dart';
import '../widgets/receipt_modal.dart';

class WalletView extends StatefulWidget {
  const WalletView({super.key});

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet & Funding'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: const Color(0xFF94A3B8),
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
                // Wallet Overview Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Wallet Balance',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$currencySymbol${balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.account_balance_wallet_rounded, color: primaryColor, size: 28),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Automated Virtual Bank Accounts',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Transfer money to any of these assigned accounts to fund your wallet instantly 24/7.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Accounts List
                dashboardProvider.dvaAccounts.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2234),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: primaryColor),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Virtual bank account details will appear here once generated for your profile.',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dashboardProvider.dvaAccounts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final dva = dashboardProvider.dvaAccounts[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A2234),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF232D42)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dva.bankName,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dva.accountNumber,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dva.accountName,
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: dva.accountNumber));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${dva.bankName} account number copied!'),
                                        backgroundColor: primaryColor,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy_rounded, size: 16),
                                  label: const Text('Copy'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                ),
                              ],
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
                const Text(
                  'Redeem Funding Coupon',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Have a funding voucher or promo coupon code? Enter it below to credit your wallet instantly.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
                const SizedBox(height: 28),

                TextFormField(
                  controller: _couponController,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: 'Coupon Code',
                    hintText: 'e.g. HARKONE5000',
                    prefixIcon: Icon(Icons.card_giftcard_rounded, color: Color(0xFF94A3B8)),
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
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
                    child: const Text('Redeem Coupon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // Tab 3: Full Transaction History List
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: dashboardProvider.recentTransactions.isEmpty
                ? const Center(
                    child: Text(
                      'No transaction history found.',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  )
                : ListView.separated(
                    itemCount: dashboardProvider.recentTransactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tx = dashboardProvider.recentTransactions[index];
                      final isDebit = tx.type == 'debit';
                      return ListTile(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (_) => ReceiptModal(transaction: tx, currencySymbol: currencySymbol),
                          );
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFF232D42)),
                        ),
                        tileColor: const Color(0xFF1A2234),
                        leading: CircleAvatar(
                          backgroundColor: isDebit
                              ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                              : const Color(0xFF10B981).withValues(alpha: 0.15),
                          child: Icon(
                            isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            color: isDebit ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          ),
                        ),
                        title: Text(
                          tx.description,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          tx.date.isNotEmpty ? tx.date : tx.humanDate,
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                        trailing: Text(
                          '${isDebit ? '-' : '+'}$currencySymbol${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isDebit ? Colors.white : const Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
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

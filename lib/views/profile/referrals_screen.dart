import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/utils/formatters.dart';

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  bool _isWithdrawing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      dashboardProvider.fetchReferralSummary();
      dashboardProvider.fetchReferralHistory();
    });
  }

  void _withdrawEarnings() async {
    setState(() => _isWithdrawing = true);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final response = await dashboardProvider.withdrawReferralEarnings();

    if (!mounted) return;
    setState(() => _isWithdrawing = false);

    if (response.status) {
      await authProvider.fetchProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message.isNotEmpty
              ? response.message
              : 'Referral earnings withdrawn to main wallet successfully!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message.isNotEmpty
              ? response.message
              : 'Failed to withdraw referral earnings.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final configProvider = Provider.of<AppConfigProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);

    final primaryColor = Theme.of(context).primaryColor;
    final currencySymbol = configProvider.currencySymbol;
    final user = authProvider.user;
    final summary = dashboardProvider.referralSummary;

    final referralCode = summary?['referral_code']?.toString() ?? user?.referralCode ?? 'VTUAPP';
    final referralLink = summary?['referral_link']?.toString() ?? 'https://nmilleniumresource.com.ng/register?ref=$referralCode';
    final totalReferrals = summary?['total_referrals'] ?? 0;
    
    double referralBalance = 0.0;
    if (summary?['referral_balance'] != null) {
      referralBalance = double.tryParse(summary!['referral_balance'].toString()) ?? 0.0;
    } else if (user?.wallet?.referralBalance != null) {
      referralBalance = user!.wallet!.referralBalance;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final borderCol = isDark ? const Color(0xFF232D42) : const Color(0xFFE2E8F0);
    final titleCol = Theme.of(context).colorScheme.onSurface;
    final subCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Refer & Earn'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await dashboardProvider.fetchReferralSummary();
            await dashboardProvider.fetchReferralHistory();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Banner Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withValues(alpha: 0.75)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Invite Friends & Earn Cash',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Share your referral code or link with friends. Earn cash bonus on every friend who signs up and completes transactions.',
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderCol),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Referrals', style: TextStyle(color: subCol, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              AppFormatters.formatInteger(totalReferrals),
                              style: TextStyle(color: titleCol, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderCol),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Referral Earnings', style: TextStyle(color: subCol, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              AppFormatters.formatCurrency(referralBalance, currencySymbol),
                              style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Withdraw Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_isWithdrawing || referralBalance <= 0) ? null : _withdrawEarnings,
                    icon: _isWithdrawing
                        ? const SizedBox.shrink()
                        : const Icon(Icons.account_balance_wallet_rounded),
                    label: _isWithdrawing
                        ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                        : Text(
                            referralBalance > 0
                                ? 'Withdraw Earnings (${AppFormatters.formatCurrency(referralBalance, currencySymbol)})'
                                : 'No Earnings to Withdraw',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Referral Code Box
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YOUR REFERRAL CODE', style: TextStyle(color: subCol, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            referralCode,
                            style: TextStyle(
                              color: titleCol,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: referralCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Referral code copied to clipboard!'),
                                  backgroundColor: primaryColor,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Copy Code'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor.withValues(alpha: 0.15),
                              foregroundColor: primaryColor,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: borderCol),
                      const SizedBox(height: 12),
                      Text('REFERRAL LINK', style: TextStyle(color: subCol, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              referralLink,
                              style: TextStyle(color: titleCol, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy_rounded, color: primaryColor, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: referralLink));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Referral link copied to clipboard!'),
                                  backgroundColor: primaryColor,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Referred Users History Section Header
                Text(
                  'Referred Users History',
                  style: TextStyle(color: titleCol, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                dashboardProvider.referralHistory.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderCol),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.people_outline_rounded, size: 40, color: subCol),
                            const SizedBox(height: 10),
                            Text('No Referrals Yet', style: TextStyle(color: titleCol, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Share your code to start earning referral rewards.', style: TextStyle(color: subCol, fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dashboardProvider.referralHistory.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = dashboardProvider.referralHistory[index] as Map<String, dynamic>;
                          final name = item['name'] ?? item['username'] ?? 'Referred User';
                          final date = item['created_at'] != null ? AppFormatters.formatDate(item['created_at']) : 'Recently joined';
                          final commission = item['commission'] ?? item['amount'] ?? 0.0;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderCol),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: primaryColor.withValues(alpha: 0.15),
                                  child: Icon(Icons.person_rounded, color: primaryColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: TextStyle(color: titleCol, fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text(date, style: TextStyle(color: subCol, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Text(
                                  '+${AppFormatters.formatCurrency(commission, currencySymbol)}',
                                  style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

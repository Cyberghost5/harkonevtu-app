import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/utils/formatters.dart';
import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';

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
    final titleCol = isDark ? Colors.white : const Color(0xFF0F172A);
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
                // Top Banner Card (3D Clay)
                ClayContainer(
                  depth: 14,
                  cornerRadius: 24,
                  color: primaryColor,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClayContainer(
                              depth: 8,
                              cornerRadius: 50,
                              color: Colors.white.withValues(alpha: 0.2),
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 24),
                              ),
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
                ),
                const SizedBox(height: 20),

                // Stats Row (3D Clay Cards)
                Row(
                  children: [
                    Expanded(
                      child: ClayContainer(
                        depth: 10,
                        cornerRadius: 18,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClayContainer(
                        depth: 10,
                        cornerRadius: 18,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
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
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Withdraw Button (3D Clay)
                ClayButton(
                  height: 52,
                  depth: 12,
                  color: primaryColor,
                  isLoading: _isWithdrawing,
                  onTap: (referralBalance <= 0) ? null : _withdrawEarnings,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        referralBalance > 0
                            ? 'Withdraw Earnings (${AppFormatters.formatCurrency(referralBalance, currencySymbol)})'
                            : 'No Earnings to Withdraw',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Referral Code Box (3D Clay Container)
                ClayContainer(
                  depth: 10,
                  cornerRadius: 22,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('YOUR REFERRAL CODE', style: TextStyle(color: subCol, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        const SizedBox(height: 10),
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
                            ClayButton(
                              height: 38,
                              width: 110,
                              depth: 8,
                              color: primaryColor,
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: referralCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Referral code copied to clipboard!'),
                                    backgroundColor: primaryColor,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.copy_rounded, size: 14, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text('Copy Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: isDark ? const Color(0xFF232D42) : const Color(0xFFE2E8F0)),
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
                ),
                const SizedBox(height: 28),

                // Referred Users History Section Header
                Text(
                  'Referred Users History',
                  style: TextStyle(color: titleCol, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                dashboardProvider.referralHistory.isEmpty
                    ? ClayContainer(
                        depth: 8,
                        cornerRadius: 18,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.people_outline_rounded, size: 40, color: subCol),
                                const SizedBox(height: 10),
                                Text('No Referrals Yet', style: TextStyle(color: titleCol, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Share your code to start earning referral rewards.', style: TextStyle(color: subCol, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dashboardProvider.referralHistory.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = dashboardProvider.referralHistory[index] as Map<String, dynamic>;
                          final name = item['name'] ?? item['username'] ?? 'Referred User';
                          final date = item['created_at'] != null ? AppFormatters.formatDate(item['created_at']) : 'Recently joined';
                          final commission = item['commission'] ?? item['amount'] ?? 0.0;

                          return ClayContainer(
                            depth: 8,
                            cornerRadius: 16,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  ClayContainer(
                                    depth: 6,
                                    cornerRadius: 50,
                                    color: primaryColor.withValues(alpha: 0.15),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(Icons.person_rounded, color: primaryColor, size: 20),
                                    ),
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


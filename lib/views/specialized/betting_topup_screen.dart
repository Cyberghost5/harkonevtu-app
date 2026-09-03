import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/specialized_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/transaction_pin_modal.dart';

class BettingTopupScreen extends StatefulWidget {
  const BettingTopupScreen({super.key});

  @override
  State<BettingTopupScreen> createState() => _BettingTopupScreenState();
}

class _BettingTopupScreenState extends State<BettingTopupScreen> {
  final _customerIdController = TextEditingController();
  final _amountController = TextEditingController();

  int _selectedPlatformIndex = 0;

  final List<Map<String, dynamic>> _platforms = [
    {'key': 'bet9ja', 'name': 'Bet9ja', 'color': const Color(0xFF16A34A)},
    {'key': 'sportybet', 'name': 'SportyBet', 'color': const Color(0xFFDC2626)},
    {'key': '1xbet', 'name': '1xBet', 'color': const Color(0xFF0284C7)},
    {'key': 'bangbet', 'name': 'BangBet', 'color': const Color(0xFFCA8A04)},
    {'key': 'merrybet', 'name': 'MerryBet', 'color': const Color(0xFF9333EA)},
    {'key': 'betway', 'name': 'BetWay', 'color': const Color(0xFF2563EB)},
  ];

  @override
  void dispose() {
    _customerIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _validateAccount() async {
    final customerId = _customerIdController.text.trim();
    if (customerId.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid betting customer User ID.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final platform = _platforms[_selectedPlatformIndex]['key'] as String;
    final specProvider = Provider.of<SpecializedProvider>(context, listen: false);
    final success = await specProvider.validateBettingAccount(
      platform: platform,
      customerId: customerId,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Betting account validated successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(specProvider.errorMessage ?? 'Account validation failed.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _submitOrder() {
    final customerId = _customerIdController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;

    if (customerId.isEmpty || amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter customer ID and valid amount (Minimum ₦100).'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final platformName = _platforms[_selectedPlatformIndex]['name'] as String;
    final currencySymbol = Provider.of<AppConfigProvider>(context, listen: false).currencySymbol;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionPinModal(
        title: '$platformName Wallet Top Up',
        amountText: '$currencySymbol${amount.toStringAsFixed(2)} (User ID: $customerId)',
        onPinConfirmed: (pin) => _executeFunding(customerId, amount, pin),
      ),
    );
  }

  void _executeFunding(String customerId, double amount, String pin) async {
    final platformKey = _platforms[_selectedPlatformIndex]['key'] as String;
    final specProvider = Provider.of<SpecializedProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    final customerName = specProvider.validatedCustomerName ?? 'Betting User';

    final response = await specProvider.fundBetting(
      platform: platformKey,
      customerId: customerId,
      amount: amount,
      customerName: customerName,
      pin: pin,
    );

    if (!mounted) return;

    if (response.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message.isNotEmpty ? response.message : 'Betting wallet funded successfully!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      _customerIdController.clear();
      _amountController.clear();
      specProvider.clearValidation();

      await authProvider.fetchProfile();
      await dashboardProvider.fetchDashboardData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final specProvider = Provider.of<SpecializedProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Betting Wallet Top Up'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Betting Platform',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),

              // Platforms Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: _platforms.length,
                itemBuilder: (context, index) {
                  final plat = _platforms[index];
                  final isSelected = _selectedPlatformIndex == index;
                  final platColor = plat['color'] as Color;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPlatformIndex = index;
                      });
                      specProvider.clearValidation();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? platColor.withValues(alpha: 0.2)
                            : const Color(0xFF1A2234),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? platColor : const Color(0xFF232D42),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_soccer_rounded, color: platColor, size: 26),
                          const SizedBox(height: 6),
                          Text(
                            plat['name'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Customer User ID Input & Validation Button
              const Text(
                'Betting Account / User ID',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _customerIdController,
                      keyboardType: TextInputType.text,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: 'Enter Account / User ID',
                        prefixIcon: Icon(Icons.person_outline_rounded, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: specProvider.isValidating ? null : _validateAccount,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                    child: specProvider.isValidating
                        ? const SpinKitThreeBounce(color: Colors.white, size: 16)
                        : const Text('Validate'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Customer Name Banner
              if (specProvider.validatedCustomerName != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          specProvider.validatedCustomerName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Amount Input
              const Text(
                'Amount (₦)',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'Minimum ₦100',
                  prefixIcon: Icon(Icons.payments_outlined, color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(height: 36),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: specProvider.isLoading ? null : _submitOrder,
                  child: specProvider.isLoading
                      ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                      : const Text('Fund Betting Wallet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

  Map<String, dynamic>? _selectedPlatform;

  final List<Map<String, dynamic>> _platforms = [
    {'key': 'bet9ja', 'name': 'Bet9ja', 'color': const Color(0xFF16A34A)},
    {'key': 'sportybet', 'name': 'SportyBet', 'color': const Color(0xFFDC2626)},
    {'key': '1xbet', 'name': '1xBet', 'color': const Color(0xFF0284C7)},
    {'key': 'bangbet', 'name': 'BangBet', 'color': const Color(0xFFCA8A04)},
    {'key': 'merrybet', 'name': 'MerryBet', 'color': const Color(0xFF9333EA)},
    {'key': 'betway', 'name': 'BetWay', 'color': const Color(0xFF2563EB)},
    {'key': 'nairabet', 'name': 'NairaBet', 'color': const Color(0xFF059669)},
    {'key': 'betking', 'name': 'BetKing (KingMakers)', 'color': const Color(0xFF1D4ED8)},
    {'key': 'paripesa', 'name': 'Paripesa', 'color': const Color(0xFFD97706)},
    {'key': 'msport', 'name': 'MSport', 'color': const Color(0xFFE11D48)},
    {'key': 'melbet', 'name': 'MelBet', 'color': const Color(0xFFF59E0B)},
    {'key': '22bet', 'name': '22Bet', 'color': const Color(0xFF0D9488)},
  ];

  @override
  void initState() {
    super.initState();
    _selectedPlatform = _platforms.first;
  }

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

    final platform = (_selectedPlatform?['key'] ?? 'bet9ja') as String;
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

    final platformName = (_selectedPlatform?['name'] ?? 'Betting') as String;
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
  }  void _executeFunding(String customerId, double amount, String pin) async {
    final platformKey = (_selectedPlatform?['key'] ?? 'bet9ja') as String;
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
    final primaryColor = Theme.of(context).primaryColor;

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
              // Betting Platform Dropdown
              const Text(
                'Select Betting Platform',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2234),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF232D42)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Map<String, dynamic>>(
                    value: _selectedPlatform,
                    isExpanded: true,
                    menuMaxHeight: 320,
                    dropdownColor: const Color(0xFF1A2234),
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
                    items: _platforms.map((plat) {
                      final color = plat['color'] as Color;
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: plat,
                        child: Row(
                          children: [
                            Icon(Icons.sports_soccer_rounded, color: color, size: 20),
                            const SizedBox(width: 12),
                            Text(plat['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedPlatform = val;
                        });
                        specProvider.clearValidation();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

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
                      onChanged: (_) => specProvider.clearValidation(),
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
              const SizedBox(height: 12),

              // Validation Helper Banner / Customer Name Banner
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
              ] else ...[
                const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Please validate betting account/user ID before funding.',
                      style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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

              // Submit Button - Disabled until betting account is validated
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (specProvider.validatedCustomerName == null || specProvider.isLoading)
                      ? null
                      : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: specProvider.validatedCustomerName != null ? primaryColor : const Color(0xFF334155),
                  ),
                  child: specProvider.isLoading
                      ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                      : Text(
                          specProvider.validatedCustomerName != null ? 'Fund Betting Wallet' : 'Validate Betting Account First',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: specProvider.validatedCustomerName != null ? Colors.white : const Color(0xFF94A3B8),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

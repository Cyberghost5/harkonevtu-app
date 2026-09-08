import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/specialized_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/transaction_pin_modal.dart';

import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_text_field.dart';

class BettingTopupScreen extends StatefulWidget {
  const BettingTopupScreen({super.key});

  @override
  State<BettingTopupScreen> createState() => _BettingTopupScreenState();
}

class _BettingTopupScreenState extends State<BettingTopupScreen> {
  final _customerIdController = TextEditingController();
  final _amountController = TextEditingController();

  Map<String, dynamic>? _selectedPlatform;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SpecializedProvider>(context, listen: false).fetchBettingPlatforms();
    });
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
  }

  void _executeFunding(String customerId, double amount, String pin) async {
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
      final msg = response.message.toLowerCase();
      if (msg.contains('pin') || msg.contains('incorrect') || msg.contains('invalid')) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) _submitOrder();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final specProvider = Provider.of<SpecializedProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleCol = Theme.of(context).colorScheme.onSurface;
    final subCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    if (specProvider.bettingPlatforms.isEmpty && !specProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Betting Wallet Top-Up')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 64, color: Color(0xFFEF4444)),
                const SizedBox(height: 16),
                Text(
                  specProvider.errorMessage ?? 'Failed to load betting platforms. Please try again.',
                  style: TextStyle(color: titleCol, fontSize: 15, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ClayButton(
                  text: 'Try Again',
                  icon: Icons.refresh_rounded,
                  width: 160,
                  onPressed: () => specProvider.fetchBettingPlatforms(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activePlatforms = specProvider.bettingPlatforms;
    Map<String, dynamic>? selectedPlatform = _selectedPlatform;
    final currentKey = selectedPlatform?['key'];
    if (currentKey == null || !activePlatforms.any((p) => p['key'] == currentKey)) {
      if (activePlatforms.isNotEmpty) {
        selectedPlatform = activePlatforms.first;
      }
    } else {
      selectedPlatform = activePlatforms.firstWhere((p) => p['key'] == currentKey, orElse: () => activePlatforms.first);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Betting Wallet Top-Up'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Betting Platform Dropdown in 3D ClayContainer
              Text(
                'Select Betting Platform',
                style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              ClayContainer(
                borderRadius: 16,
                depth: 8,
                color: isDark ? const Color(0xFF192234) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Map<String, dynamic>>(
                    value: selectedPlatform,
                    isExpanded: true,
                    menuMaxHeight: 320,
                    dropdownColor: isDark ? const Color(0xFF192234) : Colors.white,
                    icon: Icon(Icons.arrow_drop_down_rounded, color: titleCol),
                    items: activePlatforms.map((plat) {
                      final color = plat['color'] is Color ? plat['color'] as Color : const Color(0xFF0284C7);
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: plat,
                        child: Row(
                          children: [
                            Icon(Icons.sports_soccer_rounded, color: color, size: 20),
                            const SizedBox(width: 12),
                            Text(plat['name'] as String, style: TextStyle(color: titleCol, fontSize: 14)),
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

              // Customer User ID 3D Recessed Input & Validate Button
              Text(
                'Betting Account / User ID',
                style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: ClayTextField(
                      controller: _customerIdController,
                      keyboardType: TextInputType.text,
                      hintText: 'Enter Account / User ID',
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF94A3B8)),
                      onChanged: (_) => specProvider.clearValidation(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClayButton(
                    text: 'Validate',
                    width: 100,
                    height: 52,
                    isLoading: specProvider.isValidating,
                    onPressed: specProvider.isValidating ? null : _validateAccount,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Validation Helper Banner in 3D ClayContainer
              if (specProvider.validatedCustomerName != null) ...[
                ClayContainer(
                  borderRadius: 16,
                  depth: 8,
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderColor: const Color(0xFF10B981).withValues(alpha: 0.4),
                  borderWidth: 1.0,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          specProvider.validatedCustomerName!,
                          style: TextStyle(
                            color: titleCol,
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
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Please validate betting account/user ID before funding.',
                      style: TextStyle(color: subCol, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Amount Input in 3D Recessed ClayTextField
              Text(
                'Amount (₦)',
                style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ClayTextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                hintText: 'Minimum ₦100',
                prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 36),

              // Submit Button
              ClayButton(
                text: specProvider.validatedCustomerName != null ? 'Fund Betting Wallet' : 'Validate Betting Account First',
                icon: Icons.sports_soccer_rounded,
                isLoading: specProvider.isLoading,
                color: specProvider.validatedCustomerName != null ? primaryColor : (isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)),
                onPressed: (specProvider.validatedCustomerName == null || specProvider.isLoading)
                    ? null
                    : _submitOrder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/vtu_provider.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/transaction_pin_modal.dart';

import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_text_field.dart';

class AirtimeTopupScreen extends StatefulWidget {
  const AirtimeTopupScreen({super.key});

  @override
  State<AirtimeTopupScreen> createState() => _AirtimeTopupScreenState();
}

class _AirtimeTopupScreenState extends State<AirtimeTopupScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedNetwork = 'mtn';

  final List<Map<String, dynamic>> _networks = [
    {'key': 'mtn', 'name': 'MTN', 'color': const Color(0xFFFACC15)},
    {'key': 'airtel', 'name': 'Airtel', 'color': const Color(0xFFEF4444)},
    {'key': 'glo', 'name': 'Glo', 'color': const Color(0xFF10B981)},
    {'key': '9mobile', 'name': '9mobile', 'color': const Color(0xFF84CC16)},
  ];

  final List<double> _quickAmounts = [100, 200, 500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user?.phone != null && authProvider.user!.phone.isNotEmpty) {
        _phoneController.text = authProvider.user!.phone;
        _onPhoneChanged(authProvider.user!.phone);
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String phone) async {
    if (phone.length >= 11) {
      final vtuProvider = Provider.of<VtuProvider>(context, listen: false);
      final detected = await vtuProvider.lookupNetwork(phone);
      if (detected != null && mounted) {
        setState(() {
          _selectedNetwork = detected;
        });
      }
    }
  }

  void _submitOrder() {
    final phone = _phoneController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;

    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid recipient phone number.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (amount < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum airtime top-up amount is ₦50.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final currencySymbol = Provider.of<AppConfigProvider>(context, listen: false).currencySymbol;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionPinModal(
        title: 'Airtime Top Up (${_selectedNetwork.toUpperCase()})',
        amountText: '$currencySymbol${amount.toStringAsFixed(2)} to $phone',
        onPinConfirmed: (pin) => _executeAirtimePurchase(phone, amount, pin),
      ),
    );
  }

  void _executeAirtimePurchase(String phone, double amount, String pin) async {
    final vtuProvider = Provider.of<VtuProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    final response = await vtuProvider.purchaseAirtime(
      network: _selectedNetwork,
      phone: phone,
      amount: amount,
      pin: pin,
    );

    if (!mounted) return;

    if (response.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message.isNotEmpty ? response.message : 'Airtime purchase successful!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      _phoneController.clear();
      _amountController.clear();
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
    final vtuProvider = Provider.of<VtuProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleCol = Theme.of(context).colorScheme.onSurface;
    final subCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Airtime Top-Up'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Mobile Network',
                style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              // Network Selector 3D Cards Row
              Row(
                children: _networks.map((net) {
                  final isSelected = _selectedNetwork == net['key'];
                  final netColor = net['color'] as Color;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ClayContainer(
                        borderRadius: 16,
                        depth: isSelected ? 12 : 6,
                        isRecessed: isSelected,
                        color: isSelected
                            ? netColor.withValues(alpha: isDark ? 0.25 : 0.15)
                            : (isDark ? const Color(0xFF192234) : Colors.white),
                        borderColor: isSelected ? netColor : null,
                        borderWidth: isSelected ? 2.0 : 0.0,
                        onTap: () {
                          setState(() {
                            _selectedNetwork = net['key'] as String;
                          });
                        },
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: netColor.withValues(alpha: 0.3),
                              child: Text(
                                (net['name'] as String)[0],
                                style: TextStyle(color: netColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              net['name'] as String,
                              style: TextStyle(
                                color: isSelected ? netColor : subCol,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Phone Number 3D Recessed Input
              Text(
                'Phone Number',
                style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ClayTextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                hintText: 'e.g. 08012345678',
                prefixIcon: Icon(Icons.phone_android_rounded, color: subCol),
                onChanged: _onPhoneChanged,
                suffixIcon: vtuProvider.detectedNetwork != null
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            vtuProvider.detectedNetwork!.toUpperCase(),
                            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 24),

              // Amount Chips & Custom Input
              Text(
                'Amount',
                style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _quickAmounts.map((amt) {
                  final amtStr = amt.toInt().toString();
                  final isSelected = _amountController.text == amtStr;

                  return ClayContainer(
                    borderRadius: 14,
                    depth: isSelected ? 8 : 4,
                    isRecessed: isSelected,
                    color: isSelected
                        ? primaryColor
                        : (isDark ? const Color(0xFF192234) : Colors.white),
                    onTap: () {
                      setState(() {
                        _amountController.text = amtStr;
                      });
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(
                      '₦${AppFormatters.formatInteger(amt)}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : subCol,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              ClayTextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                hintText: 'Or enter custom amount (₦)',
                prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 36),

              // Submit Button
              ClayButton(
                text: 'Proceed to Top Up',
                icon: Icons.flash_on_rounded,
                isLoading: vtuProvider.isLoading,
                onPressed: vtuProvider.isLoading ? null : _submitOrder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

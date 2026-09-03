import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/vtu_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/transaction_pin_modal.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Airtime Top Up'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Mobile Network',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),

              // Network Selector Cards Row
              Row(
                children: _networks.map((net) {
                  final isSelected = _selectedNetwork == net['key'];
                  final netColor = net['color'] as Color;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedNetwork = net['key'] as String;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? netColor.withValues(alpha: 0.2)
                              : const Color(0xFF1A2234),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? netColor : const Color(0xFF232D42),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
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
                                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
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

              // Phone Number Input
              const Text(
                'Phone Number',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                onChanged: _onPhoneChanged,
                decoration: InputDecoration(
                  hintText: 'e.g. 08012345678',
                  prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFF94A3B8)),
                  suffixIcon: vtuProvider.detectedNetwork != null
                      ? Padding(
                          padding: const EdgeInsets.all(12),
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
              ),
              const SizedBox(height: 24),

              // Amount Chips & Custom Input
              const Text(
                'Amount',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _quickAmounts.map((amt) {
                  final amtStr = amt.toInt().toString();
                  final isSelected = _amountController.text == amtStr;

                  return ChoiceChip(
                    label: Text('₦$amtStr'),
                    selected: isSelected,
                    selectedColor: primaryColor,
                    backgroundColor: const Color(0xFF1A2234),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.bold,
                    ),
                    side: BorderSide(
                      color: isSelected ? primaryColor : const Color(0xFF232D42),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _amountController.text = amtStr;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'Or enter custom amount (₦)',
                  prefixIcon: Icon(Icons.payments_outlined, color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(height: 36),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: vtuProvider.isLoading ? null : _submitOrder,
                  child: vtuProvider.isLoading
                      ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                      : const Text('Proceed to Top Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

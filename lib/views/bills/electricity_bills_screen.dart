import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/bills_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/disco_model.dart';
import '../widgets/transaction_pin_modal.dart';

class ElectricityBillsScreen extends StatefulWidget {
  const ElectricityBillsScreen({super.key});

  @override
  State<ElectricityBillsScreen> createState() => _ElectricityBillsScreenState();
}

class _ElectricityBillsScreenState extends State<ElectricityBillsScreen> {
  final _meterController = TextEditingController();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  String _meterType = 'prepaid';
  DiscoModel? _selectedDisco;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user?.phone != null && authProvider.user!.phone.isNotEmpty) {
        _phoneController.text = authProvider.user!.phone;
      }

      final billsProvider = Provider.of<BillsProvider>(context, listen: false);
      billsProvider.fetchDiscos().then((_) {
        if (billsProvider.discos.isNotEmpty && mounted) {
          setState(() {
            _selectedDisco = billsProvider.discos.first;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _meterController.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _validateMeter() async {
    final meter = _meterController.text.trim();
    if (meter.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid meter number.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (_selectedDisco == null) return;

    final billsProvider = Provider.of<BillsProvider>(context, listen: false);
    final success = await billsProvider.validateMeter(
      discoId: _selectedDisco!.id,
      meterNumber: meter,
      meterType: _meterType,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meter validated successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(billsProvider.errorMessage ?? 'Meter validation failed.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _submitOrder() {
    final meter = _meterController.text.trim();
    final amountText = _amountController.text.trim();
    final phone = _phoneController.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;

    if (_selectedDisco == null || meter.isEmpty || amount < 500 || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields (Minimum amount ₦500).'),
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
        title: '${_selectedDisco!.name} Electricity',
        amountText: '$currencySymbol${amount.toStringAsFixed(2)} (Meter: $meter)',
        onPinConfirmed: (pin) => _executePurchase(meter, amount, phone, pin),
      ),
    );
  }

  void _executePurchase(String meter, double amount, String phone, String pin) async {
    final billsProvider = Provider.of<BillsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    final response = await billsProvider.purchaseElectricity(
      discoId: _selectedDisco!.id,
      meterNumber: meter,
      meterType: _meterType,
      amount: amount,
      phone: phone,
      pin: pin,
    );

    if (!mounted) return;

    if (response.status) {
      final tokenStr = response.data?['token']?.toString() ?? 'N/A';
      final unitsStr = response.data?['units']?.toString() ?? '';

      _showTokenModal(tokenStr, unitsStr);
      _meterController.clear();
      _amountController.clear();
      billsProvider.clearValidation();

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

  void _showTokenModal(String token, String units) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final primaryColor = Theme.of(context).primaryColor;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF151C2C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt_rounded, size: 48, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 16),

              const Text(
                'Electricity Token Generated',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (units.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Units: $units',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                ),
              ],
              const SizedBox(height: 20),

              // Token Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor),
                ),
                child: Column(
                  children: [
                    SelectableText(
                      token,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: token));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Electricity token copied to clipboard!'),
                            backgroundColor: primaryColor,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy Token'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final billsProvider = Provider.of<BillsProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Electricity Bill'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Disco Dropdown
              const Text(
                'Distribution Company (Disco)',
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
                  child: DropdownButton<DiscoModel>(
                    value: _selectedDisco,
                    isExpanded: true,
                    menuMaxHeight: 320,
                    dropdownColor: const Color(0xFF1A2234),
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
                    items: billsProvider.discos.map((disco) {
                      return DropdownMenuItem<DiscoModel>(
                        value: disco,
                        child: Text(disco.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedDisco = val;
                        });
                        billsProvider.clearValidation();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Meter Type Toggle (Prepaid vs Postpaid)
              const Text(
                'Meter Type',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Prepaid')),
                      selected: _meterType == 'prepaid',
                      selectedColor: primaryColor,
                      backgroundColor: const Color(0xFF1A2234),
                      labelStyle: TextStyle(
                        color: _meterType == 'prepaid' ? Colors.white : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _meterType = 'prepaid');
                          billsProvider.clearValidation();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Postpaid')),
                      selected: _meterType == 'postpaid',
                      selectedColor: primaryColor,
                      backgroundColor: const Color(0xFF1A2234),
                      labelStyle: TextStyle(
                        color: _meterType == 'postpaid' ? Colors.white : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _meterType = 'postpaid');
                          billsProvider.clearValidation();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Meter Number Input & Validation Button
              const Text(
                'Meter Number',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _meterController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      onChanged: (_) => billsProvider.clearValidation(),
                      decoration: const InputDecoration(
                        hintText: 'Enter Meter Number',
                        prefixIcon: Icon(Icons.speed_rounded, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: billsProvider.isValidating ? null : _validateMeter,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                    child: billsProvider.isValidating
                        ? const SpinKitThreeBounce(color: Colors.white, size: 16)
                        : const Text('Validate'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Validation Helper Banner / Customer Info
              if (billsProvider.validatedCustomerName != null) ...[
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              billsProvider.validatedCustomerName!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (billsProvider.validatedAddress != null)
                              Text(
                                billsProvider.validatedAddress!,
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              ),
                          ],
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
                      'Please validate meter number before paying.',
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
                  hintText: 'e.g. 2000',
                  prefixIcon: Icon(Icons.payments_outlined, color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(height: 20),

              // Recipient Phone Number
              const Text(
                'Phone Number for Notification',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: 'e.g. 08012345678',
                  prefixIcon: Icon(Icons.phone_android_rounded, color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(height: 36),

              // Submit Button - Disabled until meter is validated
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (billsProvider.validatedCustomerName == null || billsProvider.isLoading)
                      ? null
                      : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: billsProvider.validatedCustomerName != null ? primaryColor : const Color(0xFF334155),
                  ),
                  child: billsProvider.isLoading
                      ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                      : Text(
                          billsProvider.validatedCustomerName != null ? 'Pay Electricity Bill' : 'Validate Meter Number First',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: billsProvider.validatedCustomerName != null ? Colors.white : const Color(0xFF94A3B8),
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

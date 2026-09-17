import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bills_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../models/disco_model.dart';
import '../widgets/transaction_pin_modal.dart';

import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_text_field.dart';
import '../transaction_status_screen.dart';

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

    if (_selectedDisco == null || meter.isEmpty || amount < 500 || phone.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 11-digit phone number and complete all fields (Minimum amount ₦500).'),
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

  void _executePurchase(String meter, double amount, String phone, String pin) {
    final disco = _selectedDisco;
    if (disco == null) return;

    _meterController.clear();
    _amountController.clear();
    _phoneController.clear();
    Provider.of<BillsProvider>(context, listen: false).clearValidation();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionStatusScreen(
          title: '${disco.name} Electricity',
          serviceType: 'Electricity Bill',
          planName: '${disco.name} (${_meterType.toUpperCase()})',
          recipient: 'Meter: $meter ($phone)',
          amount: amount,
          action: () => Provider.of<BillsProvider>(context, listen: false).purchaseElectricity(
            discoId: disco.id,
            meterNumber: meter,
            meterType: _meterType,
            amount: amount,
            phone: phone,
            pin: pin,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billsProvider = Provider.of<BillsProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleCol = Theme.of(context).colorScheme.onSurface;
    final subCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    if (billsProvider.isLoading && billsProvider.discos.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pay Electricity Bill')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (billsProvider.discos.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pay Electricity Bill')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 64, color: Color(0xFFEF4444)),
                const SizedBox(height: 16),
                Text(
                  billsProvider.errorMessage ?? 'Failed to load electricity discos. Please try again.',
                  style: TextStyle(color: titleCol, fontSize: 15, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ClayButton(
                  text: 'Try Again',
                  icon: Icons.refresh_rounded,
                  width: 160,
                  onPressed: () {
                    billsProvider.fetchDiscos().then((_) {
                      if (billsProvider.discos.isNotEmpty && mounted) {
                        setState(() {
                          _selectedDisco = billsProvider.discos.first;
                        });
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_selectedDisco == null && billsProvider.discos.isNotEmpty) {
      _selectedDisco = billsProvider.discos.first;
    }

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
              // Disco Dropdown in 3D ClayContainer
              Text(
                'Distribution Company (Disco)',
                style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              ClayContainer(
                borderRadius: 16,
                depth: 8,
                color: isDark ? const Color(0xFF192234) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DiscoModel>(
                    value: _selectedDisco,
                    isExpanded: true,
                    menuMaxHeight: 320,
                    dropdownColor: isDark ? const Color(0xFF192234) : Colors.white,
                    icon: Icon(Icons.arrow_drop_down_rounded, color: titleCol),
                    items: billsProvider.discos.map((disco) {
                      return DropdownMenuItem<DiscoModel>(
                        value: disco,
                        child: Text(disco.name, style: TextStyle(color: titleCol, fontSize: 14)),
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

              // Meter Type Toggle 3D Chips
              Text(
                'Meter Type',
                style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: ClayContainer(
                      borderRadius: 14,
                      depth: _meterType == 'prepaid' ? 8 : 4,
                      isRecessed: _meterType == 'prepaid',
                      color: _meterType == 'prepaid'
                          ? primaryColor
                          : (isDark ? const Color(0xFF192234) : Colors.white),
                      onTap: () {
                        setState(() => _meterType = 'prepaid');
                        billsProvider.clearValidation();
                      },
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Prepaid',
                          style: TextStyle(
                            color: _meterType == 'prepaid' ? Colors.white : subCol,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClayContainer(
                      borderRadius: 14,
                      depth: _meterType == 'postpaid' ? 8 : 4,
                      isRecessed: _meterType == 'postpaid',
                      color: _meterType == 'postpaid'
                          ? primaryColor
                          : (isDark ? const Color(0xFF192234) : Colors.white),
                      onTap: () {
                        setState(() => _meterType = 'postpaid');
                        billsProvider.clearValidation();
                      },
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Postpaid',
                          style: TextStyle(
                            color: _meterType == 'postpaid' ? Colors.white : subCol,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Meter Number 3D Recessed Input & Validate Button
              Text(
                'Meter Number',
                style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: ClayTextField(
                      controller: _meterController,
                      keyboardType: TextInputType.number,
                      hintText: 'Enter Meter Number',
                      prefixIcon: const Icon(Icons.speed_rounded, color: Color(0xFF94A3B8)),
                      onChanged: (_) => billsProvider.clearValidation(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClayButton(
                    text: 'Validate',
                    width: 100,
                    height: 52,
                    isLoading: billsProvider.isValidating,
                    onPressed: billsProvider.isValidating ? null : _validateMeter,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Validation Helper Banner in 3D ClayContainer
              if (billsProvider.validatedCustomerName != null) ...[
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              billsProvider.validatedCustomerName!,
                              style: TextStyle(
                                color: titleCol,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (billsProvider.validatedAddress != null)
                              Text(
                                billsProvider.validatedAddress!,
                                style: TextStyle(color: subCol, fontSize: 12),
                              ),
                          ],
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
                      'Please validate meter number before paying.',
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
                hintText: 'e.g. 2000',
                prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 20),

              // Phone Number Input in 3D Recessed ClayTextField
              Text(
                'Phone Number for Notification',
                style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ClayTextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                hintText: 'e.g. 08012345678',
                prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 36),

              // Submit Button
              ClayButton(
                text: billsProvider.validatedCustomerName != null ? 'Pay Electricity Bill' : 'Validate Meter Number First',
                icon: Icons.power_rounded,
                isLoading: billsProvider.isLoading,
                color: billsProvider.validatedCustomerName != null ? primaryColor : (isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)),
                onPressed: (billsProvider.validatedCustomerName == null || billsProvider.isLoading)
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

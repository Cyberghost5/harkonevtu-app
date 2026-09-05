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

import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_text_field.dart';

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
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ClayContainer(
          borderRadius: 24,
          depth: 16,
          color: isDark ? const Color(0xFF151C2C) : Colors.white,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClayContainer(
                borderRadius: 40,
                depth: 8,
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                child: const Icon(Icons.bolt_rounded, size: 48, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 16),

              Text(
                'Electricity Token Generated',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (units.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Units: $units',
                  style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 14),
                ),
              ],
              const SizedBox(height: 20),

              // 3D Recessed Token Box
              ClayContainer(
                borderRadius: 16,
                depth: 8,
                isRecessed: true,
                padding: const EdgeInsets.all(16),
                color: isDark ? const Color(0xFF131A29) : const Color(0xFFF1F5F9),
                child: Column(
                  children: [
                    SelectableText(
                      token,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ClayButton(
                      text: 'Copy Token',
                      icon: Icons.copy_rounded,
                      height: 42,
                      borderRadius: 12,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: token));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Electricity token copied to clipboard!'),
                            backgroundColor: primaryColor,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ClayButton(
                text: 'Done',
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                textColor: primaryColor,
                onPressed: () => Navigator.pop(context),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleCol = Theme.of(context).colorScheme.onSurface;
    final subCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

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

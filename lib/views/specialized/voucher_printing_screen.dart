import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/specialized_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/transaction_pin_modal.dart';
import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_text_field.dart';

class VoucherPrintingScreen extends StatefulWidget {
  const VoucherPrintingScreen({super.key});

  @override
  State<VoucherPrintingScreen> createState() => _VoucherPrintingScreenState();
}

class _VoucherPrintingScreenState extends State<VoucherPrintingScreen> {
  final _denominationController = TextEditingController(text: '100');
  String _selectedNetwork = 'mtn';
  int _quantity = 1;

  final List<Map<String, dynamic>> _networks = [
    {'key': 'mtn', 'name': 'MTN', 'color': const Color(0xFFFACC15)},
    {'key': 'airtel', 'name': 'Airtel', 'color': const Color(0xFFEF4444)},
    {'key': 'glo', 'name': 'Glo', 'color': const Color(0xFF10B981)},
    {'key': '9mobile', 'name': '9mobile', 'color': const Color(0xFF84CC16)},
  ];

  @override
  void dispose() {
    _denominationController.dispose();
    super.dispose();
  }

  void _submitOrder() {
    final denomText = _denominationController.text.trim();
    final denom = double.tryParse(denomText) ?? 0.0;

    if (denom < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum voucher denomination is ₦100.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final totalPrice = denom * _quantity;
    final currencySymbol = Provider.of<AppConfigProvider>(context, listen: false).currencySymbol;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionPinModal(
        title: '${_selectedNetwork.toUpperCase()} Recharge Vouchers ($_quantity cards)',
        amountText: '$currencySymbol${totalPrice.toStringAsFixed(2)}',
        onPinConfirmed: (pin) => _executeGeneration(denom, pin),
      ),
    );
  }

  void _executeGeneration(double denom, String pin) async {
    final specProvider = Provider.of<SpecializedProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    final response = await specProvider.generateVouchers(
      network: _selectedNetwork,
      denomination: denom,
      quantity: _quantity,
      pin: pin,
    );

    if (!mounted) return;

    if (response.status) {
      final list = response.data?['vouchers'] as List<dynamic>? ?? [];
      _showVouchersModal(list);

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

  void _showVouchersModal(List<dynamic> vouchers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = Theme.of(context).primaryColor;
        final modalBg = Theme.of(context).cardColor;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: modalBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClayContainer(
                depth: 12,
                spread: 3,
                cornerRadius: 50,
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Icon(Icons.print_rounded, size: 44, color: Color(0xFF10B981)),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Recharge Cards Generated',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vouchers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = vouchers[index] as Map<String, dynamic>;
                  final pinStr = item['pin']?.toString() ?? '1234-5678-9012';
                  final serialStr = item['serial']?.toString() ?? 'SN998877';

                  return ClayContainer(
                    depth: 10,
                    cornerRadius: 16,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('PIN:', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              SelectableText(
                                pinStr,
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Serial:', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              SelectableText(
                                serialStr,
                                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClayButton(
                            height: 40,
                            depth: 8,
                            color: primaryColor.withValues(alpha: 0.15),
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: 'PIN: $pinStr Serial: $serialStr'));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Recharge voucher pin copied!'),
                                  backgroundColor: primaryColor,
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.copy_rounded, size: 16, color: primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Copy Voucher',
                                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              ClayButton(
                height: 50,
                depth: 8,
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Done',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                  ),
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
    final specProvider = Provider.of<SpecializedProvider>(context);
    final configProvider = Provider.of<AppConfigProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;
    final currencySymbol = configProvider.currencySymbol;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final denom = double.tryParse(_denominationController.text.trim()) ?? 0.0;
    final totalPrice = denom * _quantity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recharge Card Printing'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Mobile Network',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: _networks.map((net) {
                  final isSelected = _selectedNetwork == net['key'];
                  final netColor = net['color'] as Color;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedNetwork = net['key'] as String;
                          });
                        },
                        child: ClayContainer(
                          depth: isSelected ? 12 : 6,
                          cornerRadius: 16,
                          color: isSelected
                              ? netColor.withValues(alpha: 0.25)
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? netColor : Colors.transparent,
                                width: isSelected ? 2 : 0,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                net['name'] as String,
                                style: TextStyle(
                                  color: isSelected ? netColor : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Denomination Input
              Text(
                'Card Denomination (₦)',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ClayTextField(
                controller: _denominationController,
                keyboardType: TextInputType.number,
                hintText: 'e.g. 100, 200, 500, 1000',
                prefixIcon: Icons.payments_outlined,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),

              // Quantity Selector
              Text(
                'Quantity of Cards',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  ClayContainer(
                    depth: 8,
                    cornerRadius: 16,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          onPressed: () {
                            if (_quantity > 1) {
                              setState(() {
                                _quantity--;
                              });
                            }
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '$_quantity',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          onPressed: () {
                            setState(() {
                              _quantity++;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ClayContainer(
                    depth: 8,
                    cornerRadius: 16,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Total Price:', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 11)),
                          Text(
                            '$currencySymbol${totalPrice.toStringAsFixed(2)}',
                            style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Submit Button
              ClayButton(
                height: 54,
                depth: 12,
                color: primaryColor,
                isLoading: specProvider.isLoading,
                onTap: _submitOrder,
                child: const Text(
                  'Generate Recharge Pins',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/specialized_provider.dart';
import '../../providers/app_config_provider.dart';
import '../widgets/transaction_pin_modal.dart';
import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_text_field.dart';
import '../transaction_status_screen.dart';

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
    {'key': 'etisalat', 'name': '9mobile', 'color': const Color(0xFF84CC16)},
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

  void _executeGeneration(double denom, String pin) {
    final qty = _quantity;
    final totalPrice = denom * qty;
    final net = _selectedNetwork.toUpperCase();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionStatusScreen(
          title: '$net Voucher Printing',
          serviceType: 'Voucher Printing',
          planName: '$net ₦${denom.toStringAsFixed(0)} (Qty: $qty)',
          recipient: 'Recharge Voucher',
          amount: totalPrice,
          action: () => Provider.of<SpecializedProvider>(context, listen: false).generateVouchers(
            network: _selectedNetwork,
            denomination: denom,
            quantity: qty,
            pin: pin,
          ),
        ),
      ),
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


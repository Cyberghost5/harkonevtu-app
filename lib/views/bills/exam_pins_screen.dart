import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/bills_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/transaction_pin_modal.dart';

class ExamPinsScreen extends StatefulWidget {
  const ExamPinsScreen({super.key});

  @override
  State<ExamPinsScreen> createState() => _ExamPinsScreenState();
}

class _ExamPinsScreenState extends State<ExamPinsScreen> {
  final _phoneController = TextEditingController();

  int _selectedExamIndex = 0;
  int _quantity = 1;

  final List<Map<String, dynamic>> _examTypes = [
    {'id': 1, 'name': 'WAEC Result Checker', 'price': 3600.0, 'code': 'waec', 'color': const Color(0xFF3B82F6)},
    {'id': 2, 'name': 'NECO Result Token', 'price': 1200.0, 'code': 'neco', 'color': const Color(0xFF10B981)},
    {'id': 3, 'name': 'NABTEB Result Checker', 'price': 1000.0, 'code': 'nabteb', 'color': const Color(0xFFF59E0B)},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submitOrder() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final exam = _examTypes[_selectedExamIndex];
    final totalPrice = (exam['price'] as double) * _quantity;
    final currencySymbol = Provider.of<AppConfigProvider>(context, listen: false).currencySymbol;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionPinModal(
        title: '${exam['name']} ($_quantity card/s)',
        amountText: '$currencySymbol${totalPrice.toStringAsFixed(2)}',
        onPinConfirmed: (pin) => _executePurchase(exam['id'], phone, pin),
      ),
    );
  }

  void _executePurchase(dynamic examTypeId, String phone, String pin) async {
    final billsProvider = Provider.of<BillsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    final response = await billsProvider.purchaseExamPin(
      examTypeId: examTypeId,
      quantity: _quantity,
      phone: phone,
      pin: pin,
    );

    if (!mounted) return;

    if (response.status) {
      final tokensList = response.data?['tokens'] as List<dynamic>? ?? [];
      _showPinsModal(tokensList);
      _phoneController.clear();
      setState(() {
        _quantity = 1;
      });

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

  void _showPinsModal(List<dynamic> tokens) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                child: const Icon(Icons.school_rounded, size: 44, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 16),

              const Text(
                'Exam PIN Purchased Successfully',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tokens.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = tokens[index] as Map<String, dynamic>;
                  final pinStr = item['pin']?.toString() ?? '';
                  final serialStr = item['serial']?.toString() ?? '';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF232D42)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('PIN:', style: TextStyle(color: Color(0xFF94A3B8))),
                            SelectableText(
                              pinStr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        if (serialStr.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Serial:', style: TextStyle(color: Color(0xFF94A3B8))),
                              SelectableText(
                                serialStr,
                                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: 'PIN: $pinStr Serial: $serialStr'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Exam PIN copied to clipboard!'),
                                backgroundColor: primaryColor,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 14),
                          label: const Text('Copy PIN Details'),
                        ),
                      ],
                    ),
                  );
                },
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
    final configProvider = Provider.of<AppConfigProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;
    final currencySymbol = configProvider.currencySymbol;

    final selectedExam = _examTypes[_selectedExamIndex];
    final totalPrice = (selectedExam['price'] as double) * _quantity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam PIN Scratch Cards'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Examination Body',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),

              // Exam Type Cards
              Column(
                children: List.generate(_examTypes.length, (index) {
                  final exam = _examTypes[index];
                  final isSelected = _selectedExamIndex == index;
                  final examColor = exam['color'] as Color;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedExamIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? examColor.withValues(alpha: 0.15)
                            : const Color(0xFF1A2234),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? examColor : const Color(0xFF232D42),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: examColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.school_rounded, color: examColor, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exam['name'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Price per card: $currencySymbol${(exam['price'] as double).toStringAsFixed(2)}',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? examColor : const Color(0xFF64748B),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.circle,
                              size: 10,
                              color: isSelected ? examColor : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Quantity Selector
              const Text(
                'Quantity',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2234),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF232D42)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_rounded, color: Colors.white),
                          onPressed: () {
                            if (_quantity > 1) {
                              setState(() {
                                _quantity--;
                              });
                            }
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_rounded, color: Colors.white),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total Amount:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      Text(
                        '$currencySymbol${totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(color: primaryColor, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recipient Phone Input
              const Text(
                'Phone Number for PIN Receipt',
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

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: billsProvider.isLoading ? null : _submitOrder,
                  child: billsProvider.isLoading
                      ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                      : const Text('Purchase Exam PIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

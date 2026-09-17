import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bills_provider.dart';
import '../../core/utils/formatters.dart';
import '../../providers/app_config_provider.dart';
import '../widgets/transaction_pin_modal.dart';

import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_text_field.dart';
import '../transaction_status_screen.dart';

class ExamPinsScreen extends StatefulWidget {
  const ExamPinsScreen({super.key});

  @override
  State<ExamPinsScreen> createState() => _ExamPinsScreenState();
}

class _ExamPinsScreenState extends State<ExamPinsScreen> {
  final _phoneController = TextEditingController();

  int _selectedExamIndex = 0;
  int _quantity = 1;

  List<Map<String, dynamic>> _getExamTypes(BillsProvider billsProvider) {
    final colors = [const Color(0xFF3B82F6), const Color(0xFF10B981), const Color(0xFFF59E0B), const Color(0xFF8B5CF6)];
    return billsProvider.examTypes.asMap().entries.map((entry) {
      final idx = entry.key;
      final map = entry.value;
      final rawPrice = map['price'] ?? map['unit_price'] ?? 0;
      final price = (rawPrice is num) ? rawPrice.toDouble() : (double.tryParse(rawPrice.toString()) ?? 0.0);
      return {
        ...map,
        'price': price,
        'color': colors[idx % colors.length],
      };
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final billsProvider = Provider.of<BillsProvider>(context, listen: false);
      billsProvider.fetchExamTypes();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submitOrder() {
    final phone = _phoneController.text.trim();
    if (phone.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 11-digit phone number.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final billsProvider = Provider.of<BillsProvider>(context, listen: false);
    final examTypes = _getExamTypes(billsProvider);
    if (examTypes.isEmpty) return;
    final safeIndex = (_selectedExamIndex >= 0 && _selectedExamIndex < examTypes.length) ? _selectedExamIndex : 0;
    final exam = examTypes[safeIndex];
    final totalPrice = ((exam['price'] as num? ?? 0.0).toDouble()) * _quantity;
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

  void _executePurchase(dynamic examTypeId, String phone, String pin) {
    final billsProvider = Provider.of<BillsProvider>(context, listen: false);
    final examTypes = _getExamTypes(billsProvider);
    if (examTypes.isEmpty) return;
    final safeIndex = (_selectedExamIndex >= 0 && _selectedExamIndex < examTypes.length) ? _selectedExamIndex : 0;
    final exam = examTypes[safeIndex];
    final totalPrice = ((exam['price'] as num? ?? 0.0).toDouble()) * _quantity;
    final examName = (exam['name'] ?? 'Exam PIN') as String;

    _phoneController.clear();
    final qty = _quantity;
    setState(() {
      _quantity = 1;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionStatusScreen(
          title: '$examName PIN',
          serviceType: 'Exam PIN',
          planName: '$examName (Qty: $qty)',
          recipient: phone,
          amount: totalPrice,
          action: () => Provider.of<BillsProvider>(context, listen: false).purchaseExamPin(
            examTypeId: examTypeId,
            quantity: qty,
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
    final configProvider = Provider.of<AppConfigProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;
    final currencySymbol = configProvider.currencySymbol;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleCol = Theme.of(context).colorScheme.onSurface;
    final subCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    if (billsProvider.isLoading && billsProvider.examTypes.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam Result PINs')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (billsProvider.examTypes.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam Result PINs')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 64, color: Color(0xFFEF4444)),
                const SizedBox(height: 16),
                Text(
                  billsProvider.errorMessage ?? 'Failed to load exam PIN services. Please try again.',
                  style: TextStyle(color: titleCol, fontSize: 15, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ClayButton(
                  text: 'Try Again',
                  icon: Icons.refresh_rounded,
                  width: 160,
                  onPressed: () => billsProvider.fetchExamTypes(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final examTypes = _getExamTypes(billsProvider);
    final safeIndex = (_selectedExamIndex >= 0 && _selectedExamIndex < examTypes.length) ? _selectedExamIndex : 0;
    final selectedExam = examTypes[safeIndex];
    final totalPrice = ((selectedExam['price'] as num? ?? 0.0).toDouble()) * _quantity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Result PINs'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Examination Body',
                style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              // Exam Type 3D Selector Cards
              Column(
                children: List.generate(examTypes.length, (index) {
                  final exam = examTypes[index];
                  final isSelected = safeIndex == index;
                  final examColor = exam['color'] as Color;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClayContainer(
                      borderRadius: 18,
                      depth: isSelected ? 12 : 6,
                      isRecessed: isSelected,
                      color: isSelected
                          ? examColor.withValues(alpha: isDark ? 0.25 : 0.15)
                          : (isDark ? const Color(0xFF192234) : Colors.white),
                      borderColor: isSelected ? examColor : null,
                      borderWidth: isSelected ? 2.0 : 0.0,
                      onTap: () {
                        setState(() {
                          _selectedExamIndex = index;
                        });
                      },
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          ClayContainer(
                            borderRadius: 12,
                            depth: 6,
                            color: examColor.withValues(alpha: 0.2),
                            padding: const EdgeInsets.all(10),
                            child: Icon(Icons.school_rounded, color: examColor, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exam['name'] as String,
                                  style: TextStyle(
                                    color: titleCol,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Price per card: ${AppFormatters.formatCurrency(exam['price'] as double, currencySymbol)}',
                                  style: TextStyle(color: subCol, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? examColor : subCol,
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

              // Quantity Selector 3D Box
              Text(
                'Quantity',
                style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  ClayContainer(
                    borderRadius: 16,
                    depth: 8,
                    color: isDark ? const Color(0xFF192234) : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove_rounded, color: titleCol),
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
                            style: TextStyle(color: titleCol, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_rounded, color: titleCol),
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
                      Text('Total Amount:', style: TextStyle(color: subCol, fontSize: 12)),
                      Text(
                        '$currencySymbol${totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(color: primaryColor, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recipient Phone 3D Recessed Input
              Text(
                'Phone Number for PIN Receipt',
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
                text: 'Purchase Exam PIN',
                icon: Icons.school_rounded,
                isLoading: billsProvider.isLoading,
                onPressed: billsProvider.isLoading ? null : _submitOrder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

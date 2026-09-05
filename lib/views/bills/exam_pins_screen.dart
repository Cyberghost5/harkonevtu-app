import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/bills_provider.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/transaction_pin_modal.dart';

import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_text_field.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user?.phone != null && authProvider.user!.phone.isNotEmpty) {
        _phoneController.text = authProvider.user!.phone;
      }
    });
  }

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
                child: const Icon(Icons.school_rounded, size: 44, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 16),

              Text(
                'Exam PIN Purchased Successfully',
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
                itemCount: tokens.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = tokens[index] as Map<String, dynamic>;
                  final pinStr = item['pin']?.toString() ?? '';
                  final serialStr = item['serial']?.toString() ?? '';

                  return ClayContainer(
                    borderRadius: 16,
                    depth: 8,
                    isRecessed: true,
                    padding: const EdgeInsets.all(16),
                    color: isDark ? const Color(0xFF131A29) : const Color(0xFFF1F5F9),
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
                        if (serialStr.isNotEmpty) ...[
                          const SizedBox(height: 6),
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
                        ],
                        const SizedBox(height: 12),
                        ClayButton(
                          text: 'Copy PIN Details',
                          icon: Icons.copy_rounded,
                          height: 42,
                          borderRadius: 12,
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: 'PIN: $pinStr Serial: $serialStr'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Exam PIN copied to clipboard!'),
                                backgroundColor: primaryColor,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
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
    final configProvider = Provider.of<AppConfigProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;
    final currencySymbol = configProvider.currencySymbol;

    final selectedExam = _examTypes[_selectedExamIndex];
    final totalPrice = (selectedExam['price'] as double) * _quantity;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleCol = Theme.of(context).colorScheme.onSurface;
    final subCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

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
                children: List.generate(_examTypes.length, (index) {
                  final exam = _examTypes[index];
                  final isSelected = _selectedExamIndex == index;
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

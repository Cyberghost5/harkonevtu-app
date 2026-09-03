import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/bills_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/disco_model.dart';
import '../widgets/transaction_pin_modal.dart';

class CableTvScreen extends StatefulWidget {
  const CableTvScreen({super.key});

  @override
  State<CableTvScreen> createState() => _CableTvScreenState();
}

class _CableTvScreenState extends State<CableTvScreen> {
  final _smartcardController = TextEditingController();
  final _phoneController = TextEditingController();

  int _selectedProviderIndex = 0;
  CablePlanModel? _selectedPlan;

  final List<Map<String, dynamic>> _providers = [
    {'id': 1, 'name': 'DSTV', 'color': const Color(0xFF0284C7)},
    {'id': 2, 'name': 'GOtv', 'color': const Color(0xFF16A34A)},
    {'id': 3, 'name': 'StarTimes', 'color': const Color(0xFFEA580C)},
    {'id': 4, 'name': 'Showmax', 'color': const Color(0xFFE11D48)},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user?.phone != null && authProvider.user!.phone.isNotEmpty) {
        _phoneController.text = authProvider.user!.phone;
      }
      _loadCablePlans();
    });
  }

  @override
  void dispose() {
    _smartcardController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadCablePlans() {
    final providerId = _providers[_selectedProviderIndex]['id'];
    Provider.of<BillsProvider>(context, listen: false).fetchCablePlans(providerId);
    setState(() {
      _selectedPlan = null;
    });
  }

  void _validateSmartcard() async {
    final smartcard = _smartcardController.text.trim();
    if (smartcard.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid smartcard/IUC number.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final providerId = _providers[_selectedProviderIndex]['id'];
    final billsProvider = Provider.of<BillsProvider>(context, listen: false);
    final success = await billsProvider.validateSmartcard(
      providerId: providerId,
      smartcard: smartcard,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Smartcard validated successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(billsProvider.errorMessage ?? 'Smartcard validation failed.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _submitOrder() {
    final smartcard = _smartcardController.text.trim();
    final phone = _phoneController.text.trim();

    if (_selectedPlan == null || smartcard.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a package plan and enter smartcard number.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final currencySymbol = Provider.of<AppConfigProvider>(context, listen: false).currencySymbol;
    final providerName = _providers[_selectedProviderIndex]['name'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionPinModal(
        title: '$providerName ${_selectedPlan!.name}',
        amountText: '$currencySymbol${_selectedPlan!.price.toStringAsFixed(2)} ($smartcard)',
        onPinConfirmed: (pin) => _executePurchase(smartcard, phone, pin),
      ),
    );
  }

  void _executePurchase(String smartcard, String phone, String pin) async {
    final providerId = _providers[_selectedProviderIndex]['id'];
    final billsProvider = Provider.of<BillsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    final response = await billsProvider.purchaseCable(
      providerId: providerId,
      planId: _selectedPlan!.id,
      smartcard: smartcard,
      phone: phone,
      pin: pin,
    );

    if (!mounted) return;

    if (response.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message.isNotEmpty ? response.message : 'Cable TV subscription successful!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      _smartcardController.clear();
      _phoneController.clear();
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

  @override
  Widget build(BuildContext context) {
    final billsProvider = Provider.of<BillsProvider>(context);
    final configProvider = Provider.of<AppConfigProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;
    final currencySymbol = configProvider.currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cable TV Subscription'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider Tabs
              Row(
                children: List.generate(_providers.length, (index) {
                  final prov = _providers[index];
                  final isSelected = _selectedProviderIndex == index;
                  final provColor = prov['color'] as Color;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedProviderIndex = index;
                        });
                        billsProvider.clearValidation();
                        _loadCablePlans();
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? provColor.withValues(alpha: 0.2)
                              : const Color(0xFF1A2234),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? provColor : const Color(0xFF232D42),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            prov['name'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Smartcard Number Input & Validation
              const Text(
                'Smartcard / IUC Number',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _smartcardController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      onChanged: (_) => billsProvider.clearValidation(),
                      decoration: const InputDecoration(
                        hintText: 'Enter Smartcard / IUC',
                        prefixIcon: Icon(Icons.credit_card_rounded, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: billsProvider.isValidating ? null : _validateSmartcard,
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

              // Validation Helper Banner / Customer Name Banner
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
                        child: Text(
                          billsProvider.validatedCustomerName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
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
                      'Please validate smartcard/IUC number before subscribing.',
                      style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Package Plan Selector Dropdown
              const Text(
                'Package Plan',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              billsProvider.isLoading
                  ? Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2234),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: SpinKitThreeBounce(color: primaryColor, size: 18)),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2234),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF232D42)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CablePlanModel>(
                          value: _selectedPlan,
                          hint: const Text('Select Subscription Package',
                              style: TextStyle(color: Color(0xFF94A3B8))),
                          isExpanded: true,
                          menuMaxHeight: 320,
                          dropdownColor: const Color(0xFF1A2234),
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
                          items: billsProvider.cablePlans.map((plan) {
                            return DropdownMenuItem<CablePlanModel>(
                              value: plan,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(plan.name,
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  Text('$currencySymbol${plan.price.toStringAsFixed(2)}',
                                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedPlan = val;
                            });
                          },
                        ),
                      ),
                    ),
              const SizedBox(height: 20),

              // Recipient Phone Input
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

              // Submit Button - Disabled until smartcard is validated
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
                          billsProvider.validatedCustomerName != null ? 'Subscribe Cable TV' : 'Validate Smartcard Number First',
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

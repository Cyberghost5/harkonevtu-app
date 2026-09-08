import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/bills_provider.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/disco_model.dart';
import '../widgets/transaction_pin_modal.dart';

import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_text_field.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user?.phone != null && authProvider.user!.phone.isNotEmpty) {
        _phoneController.text = authProvider.user!.phone;
      }
      final billsProvider = Provider.of<BillsProvider>(context, listen: false);
      await billsProvider.fetchCableProviders();
      _loadCablePlans();
    });
  }

  @override
  void dispose() {
    _smartcardController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getProviders() {
    final billsProvider = Provider.of<BillsProvider>(context, listen: false);
    return billsProvider.cableProviders;
  }

  void _loadCablePlans() {
    final providers = _getProviders();
    final safeIndex = _selectedProviderIndex < providers.length ? _selectedProviderIndex : 0;
    final providerId = providers[safeIndex]['id'];
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

    final providers = _getProviders();
    final safeIndex = _selectedProviderIndex < providers.length ? _selectedProviderIndex : 0;
    final providerId = providers[safeIndex]['id'];
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
    final providers = _getProviders();
    final safeIndex = _selectedProviderIndex < providers.length ? _selectedProviderIndex : 0;
    final providerName = providers[safeIndex]['name'];

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
    final providers = _getProviders();
    final safeIndex = _selectedProviderIndex < providers.length ? _selectedProviderIndex : 0;
    final providerId = providers[safeIndex]['id'];
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
      final msg = response.message.toLowerCase();
      if (msg.contains('pin') || msg.contains('incorrect') || msg.contains('invalid')) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) _submitOrder();
        });
      }
    }
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

    if (billsProvider.cableProviders.isEmpty && !billsProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cable TV Subscription')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 64, color: Color(0xFFEF4444)),
                const SizedBox(height: 16),
                Text(
                  billsProvider.errorMessage ?? 'Failed to load Cable TV providers. Please try again.',
                  style: TextStyle(color: titleCol, fontSize: 15, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ClayButton(
                  text: 'Try Again',
                  icon: Icons.refresh_rounded,
                  width: 160,
                  onPressed: () async {
                    await billsProvider.fetchCableProviders();
                    _loadCablePlans();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activeProviders = billsProvider.cableProviders;
    final safeSelectedIndex = _selectedProviderIndex < activeProviders.length ? _selectedProviderIndex : 0;

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
              // Provider Selector 3D Cards Row
              Text(
                'Select TV Provider',
                style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(activeProviders.length, (index) {
                    final prov = activeProviders[index];
                    final isSelected = safeSelectedIndex == index;
                    final provColor = prov['color'] is Color ? prov['color'] as Color : const Color(0xFF0284C7);
                    final screenWidth = MediaQuery.of(context).size.width - 40;
                    final itemWidth = activeProviders.length <= 4
                        ? (screenWidth - (activeProviders.length - 1) * 8) / activeProviders.length
                        : 95.0;

                    return SizedBox(
                      width: itemWidth,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClayContainer(
                          borderRadius: 16,
                          depth: isSelected ? 12 : 6,
                          isRecessed: isSelected,
                          color: isSelected
                              ? provColor.withValues(alpha: isDark ? 0.25 : 0.15)
                              : (isDark ? const Color(0xFF192234) : Colors.white),
                          borderColor: isSelected ? provColor : null,
                          borderWidth: isSelected ? 2.0 : 0.0,
                          onTap: () {
                            setState(() {
                              _selectedProviderIndex = index;
                            });
                            billsProvider.clearValidation();
                            _loadCablePlans();
                          },
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              prov['name'] as String,
                              style: TextStyle(
                                color: isSelected ? provColor : subCol,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Smartcard Number 3D Recessed Input & Validate Button
              Text(
                'Smartcard / IUC Number',
                style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: ClayTextField(
                      controller: _smartcardController,
                      keyboardType: TextInputType.number,
                      hintText: 'Enter Smartcard / IUC',
                      prefixIcon: const Icon(Icons.credit_card_rounded, color: Color(0xFF94A3B8)),
                      onChanged: (_) => billsProvider.clearValidation(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClayButton(
                    text: 'Validate',
                    width: 100,
                    height: 52,
                    isLoading: billsProvider.isValidating,
                    onPressed: billsProvider.isValidating ? null : _validateSmartcard,
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
                        child: Text(
                          billsProvider.validatedCustomerName!,
                          style: TextStyle(
                            color: titleCol,
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
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Please validate smartcard/IUC number before subscribing.',
                      style: TextStyle(color: subCol, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Package Plan Selector Dropdown in 3D ClayContainer
              Text(
                'Package Plan',
                style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              billsProvider.isLoading
                  ? ClayContainer(
                      borderRadius: 16,
                      depth: 6,
                      color: isDark ? const Color(0xFF1A2234) : Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Center(child: SpinKitThreeBounce(color: primaryColor, size: 18)),
                    )
                  : ClayContainer(
                      borderRadius: 16,
                      depth: 8,
                      color: isDark ? const Color(0xFF192234) : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CablePlanModel>(
                          value: _selectedPlan,
                          hint: Text('Select Subscription Package',
                              style: TextStyle(color: subCol)),
                          isExpanded: true,
                          menuMaxHeight: 320,
                          dropdownColor: isDark ? const Color(0xFF192234) : Colors.white,
                          icon: Icon(Icons.arrow_drop_down_rounded, color: titleCol),
                          items: billsProvider.cablePlans.map((plan) {
                            return DropdownMenuItem<CablePlanModel>(
                              value: plan,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(plan.name,
                                        style: TextStyle(color: titleCol, fontSize: 14),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  Text(AppFormatters.formatCurrency(plan.price, currencySymbol),
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

              // Recipient Phone Input in 3D Recessed ClayTextField
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
                text: billsProvider.validatedCustomerName != null ? 'Subscribe Cable TV' : 'Validate Smartcard Number First',
                icon: Icons.tv_rounded,
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/vtu_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/data_plan_model.dart';
import '../widgets/transaction_pin_modal.dart';

class DataBundlesScreen extends StatefulWidget {
  const DataBundlesScreen({super.key});

  @override
  State<DataBundlesScreen> createState() => _DataBundlesScreenState();
}

class _DataBundlesScreenState extends State<DataBundlesScreen> {
  final _phoneController = TextEditingController();
  String _selectedNetwork = 'mtn';
  String _selectedTypeFilter = 'all';
  DataPlanModel? _selectedPlan;

  final List<Map<String, dynamic>> _networks = [
    {'key': 'mtn', 'name': 'MTN', 'color': const Color(0xFFFACC15)},
    {'key': 'airtel', 'name': 'Airtel', 'color': const Color(0xFFEF4444)},
    {'key': 'glo', 'name': 'Glo', 'color': const Color(0xFF10B981)},
    {'key': '9mobile', 'name': '9mobile', 'color': const Color(0xFF84CC16)},
  ];

  final List<Map<String, String>> _typeFilters = [
    {'key': 'all', 'label': 'All Plans'},
    {'key': 'sme', 'label': 'SME'},
    {'key': 'gifting', 'label': 'Gifting'},
    {'key': 'corporate', 'label': 'Corporate'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataPlans();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _loadDataPlans() {
    Provider.of<VtuProvider>(context, listen: false).fetchDataPlans(_selectedNetwork);
    setState(() {
      _selectedPlan = null;
    });
  }

  void _submitOrder() {
    final phone = _phoneController.text.trim();

    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a data plan bundle to purchase.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid recipient phone number.'),
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
        title: '${_selectedNetwork.toUpperCase()} ${_selectedPlan!.planName}',
        amountText: '$currencySymbol${_selectedPlan!.price.toStringAsFixed(2)} to $phone',
        onPinConfirmed: (pin) => _executeDataPurchase(phone, pin),
      ),
    );
  }

  void _executeDataPurchase(String phone, String pin) async {
    final vtuProvider = Provider.of<VtuProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    final response = await vtuProvider.purchaseData(
      planId: _selectedPlan!.id,
      phone: phone,
      pin: pin,
    );

    if (!mounted) return;

    if (response.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message.isNotEmpty ? response.message : 'Data bundle purchased successfully!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      _phoneController.clear();
      setState(() {
        _selectedPlan = null;
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

  @override
  Widget build(BuildContext context) {
    final vtuProvider = Provider.of<VtuProvider>(context);
    final configProvider = Provider.of<AppConfigProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;
    final currencySymbol = configProvider.currencySymbol;

    final filteredPlans = vtuProvider.dataPlans.where((plan) {
      if (_selectedTypeFilter == 'all') return true;
      return plan.dataType.toLowerCase().contains(_selectedTypeFilter);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Data Bundles'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Network Tabs
              Row(
                children: _networks.map((net) {
                  final isSelected = _selectedNetwork == net['key'];
                  final netColor = net['color'] as Color;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedNetwork = net['key'] as String;
                        });
                        _loadDataPlans();
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? netColor.withValues(alpha: 0.2)
                              : const Color(0xFF1A2234),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? netColor : const Color(0xFF232D42),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            net['name'] as String,
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
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Phone Number Input
              const Text(
                'Recipient Phone Number',
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
              const SizedBox(height: 20),

              // Data Type Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _typeFilters.map((tf) {
                    final isSelected = _selectedTypeFilter == tf['key'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(tf['label']!),
                        selected: isSelected,
                        selectedColor: primaryColor,
                        backgroundColor: const Color(0xFF1A2234),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedTypeFilter = tf['key']!;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Data Plans Catalog
              const Text(
                'Select Data Plan',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              vtuProvider.isLoading
                  ? Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(child: SpinKitThreeBounce(color: primaryColor, size: 20)),
                    )
                  : filteredPlans.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2234),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'No data plans found for selected filter.',
                              style: TextStyle(color: Color(0xFF94A3B8)),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredPlans.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final plan = filteredPlans[index];
                            final isSelected = _selectedPlan?.id == plan.id;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPlan = plan;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryColor.withValues(alpha: 0.15)
                                      : const Color(0xFF1A2234),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? primaryColor : const Color(0xFF232D42),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              plan.planName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: primaryColor.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                plan.typeLabel,
                                                style: TextStyle(
                                                  color: primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Validity: ${plan.validity}',
                                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '$currencySymbol${plan.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: isSelected ? primaryColor : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              const SizedBox(height: 32),

              // Submit Purchase Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: vtuProvider.isLoading ? null : _submitOrder,
                  child: vtuProvider.isLoading
                      ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                      : const Text('Purchase Data Bundle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/vtu_provider.dart';
import '../../core/utils/formatters.dart';
import '../../providers/app_config_provider.dart';
import '../../models/data_plan_model.dart';
import '../widgets/transaction_pin_modal.dart';

import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_text_field.dart';
import '../transaction_status_screen.dart';

class DataBundlesScreen extends StatefulWidget {
  const DataBundlesScreen({super.key});

  @override
  State<DataBundlesScreen> createState() => _DataBundlesScreenState();
}

class _DataBundlesScreenState extends State<DataBundlesScreen> {
  final _phoneController = TextEditingController();
  String _selectedNetwork = 'mtn';
  String _selectedTypeFilter = '';
  DataPlanModel? _selectedPlan;

  final List<Map<String, dynamic>> _networks = [
    {'key': 'mtn', 'name': 'MTN', 'color': const Color(0xFFFACC15)},
    {'key': 'airtel', 'name': 'Airtel', 'color': const Color(0xFFEF4444)},
    {'key': 'glo', 'name': 'Glo', 'color': const Color(0xFF10B981)},
    {'key': 'etisalat', 'name': '9mobile', 'color': const Color(0xFF84CC16)},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vtuProvider = Provider.of<VtuProvider>(context, listen: false);
      vtuProvider.fetchDataNetworks();
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

  void _onPhoneChanged(String val) async {
    if (val.length >= 10) {
      final vtuProvider = Provider.of<VtuProvider>(context, listen: false);
      final network = await vtuProvider.lookupNetwork(val);
      if (network != null && mounted) {
        final lower = network.toLowerCase();
        if (_selectedNetwork != lower) {
          setState(() {
            _selectedNetwork = lower;
            _selectedTypeFilter = '';
          });
          _loadDataPlans();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Auto-detected network: ${network.toUpperCase()}'),
              duration: const Duration(seconds: 2),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    }
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

    if (phone.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 11-digit recipient phone number.'),
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

  void _executeDataPurchase(String phone, String pin) {
    final plan = _selectedPlan;
    if (plan == null) return;

    _phoneController.clear();
    setState(() {
      _selectedPlan = null;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionStatusScreen(
          title: '${_selectedNetwork.toUpperCase()} Data',
          serviceType: 'Data Bundle',
          planName: plan.planName,
          recipient: phone,
          amount: plan.price,
          action: () => Provider.of<VtuProvider>(context, listen: false).purchaseData(
            planId: plan.id,
            phone: phone,
            pin: pin,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vtuProvider = Provider.of<VtuProvider>(context);
    final configProvider = Provider.of<AppConfigProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;
    final currencySymbol = configProvider.currencySymbol;

    final apiDataTypes = vtuProvider.getDataTypesForNetwork(_selectedNetwork);

    List<Map<String, String>> dynamicTypeFilters = [];
    if (apiDataTypes.isNotEmpty) {
      dynamicTypeFilters = apiDataTypes.map((dt) => {'key': dt.typeKey, 'label': dt.name}).toList();
    } else if (vtuProvider.dataPlans.isNotEmpty) {
      final Map<String, String> typesMap = {};
      for (var plan in vtuProvider.dataPlans) {
        if (plan.dataType.isNotEmpty) {
          typesMap[plan.dataType] = plan.typeLabel.isNotEmpty ? plan.typeLabel : plan.dataType.toUpperCase();
        }
      }
      dynamicTypeFilters = typesMap.entries.map((e) => {'key': e.key, 'label': e.value}).toList();
    }

    if (dynamicTypeFilters.isNotEmpty) {
      final exists = dynamicTypeFilters.any((f) => f['key'] == _selectedTypeFilter);
      if (!exists) {
        _selectedTypeFilter = dynamicTypeFilters.first['key']!;
      }
    }

    final filteredPlans = vtuProvider.dataPlans.where((plan) {
      if (_selectedTypeFilter.isEmpty) return true;
      final target = _selectedTypeFilter.toLowerCase();
      final pType = plan.dataType.toLowerCase();
      final pLabel = plan.typeLabel.toLowerCase();
      return pType == target || pType.contains(target) || pLabel.contains(target) || target.contains(pType);
    }).toList();


    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleCol = Theme.of(context).colorScheme.onSurface;
    final subCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

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
              // Select Network 3D Cards Row
              Text(
                'Select Mobile Network',
                style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: _networks.map((net) {
                  final isSelected = _selectedNetwork == net['key'];
                  final netColor = net['color'] as Color;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ClayContainer(
                        borderRadius: 16,
                        depth: isSelected ? 12 : 6,
                        isRecessed: isSelected,
                        color: isSelected
                            ? netColor.withValues(alpha: isDark ? 0.25 : 0.15)
                            : (isDark ? const Color(0xFF192234) : Colors.white),
                        borderColor: isSelected ? netColor : null,
                        borderWidth: isSelected ? 2.0 : 0.0,
                        onTap: () {
                          setState(() {
                            _selectedNetwork = net['key'] as String;
                            _selectedTypeFilter = 'all';
                            _selectedPlan = null;
                          });
                          vtuProvider.fetchDataPlans(net['key'] as String);
                        },
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: netColor.withValues(alpha: 0.3),
                              child: Text(
                                (net['name'] as String)[0],
                                style: TextStyle(color: netColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              net['name'] as String,
                              style: TextStyle(
                                color: isSelected ? netColor : subCol,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Phone Number 3D Recessed Input
              Text(
                'Recipient Phone Number',
                style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ClayTextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                hintText: 'e.g. 08012345678',
                prefixIcon: Icon(Icons.phone_android_rounded, color: subCol),
                onChanged: _onPhoneChanged,
              ),
              const SizedBox(height: 24),

              // Data Type Filter 3D Chips (Dynamically populated from /data/networks API)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: dynamicTypeFilters.map((tf) {
                    final isSelected = _selectedTypeFilter == tf['key'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: ClayContainer(
                        borderRadius: 14,
                        depth: isSelected ? 8 : 4,
                        isRecessed: isSelected,
                        color: isSelected
                            ? primaryColor
                            : (isDark ? const Color(0xFF192234) : Colors.white),
                        onTap: () {
                          setState(() {
                            _selectedTypeFilter = tf['key']!;
                          });
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text(
                          tf['label']!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : subCol,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Data Plans Catalog Grid
              Text(
                'Select Data Plan',
                style: TextStyle(color: titleCol, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              vtuProvider.isLoading
                  ? ClayContainer(
                      borderRadius: 16,
                      depth: 6,
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      padding: const EdgeInsets.all(40),
                      child: Center(child: SpinKitThreeBounce(color: primaryColor, size: 20)),
                    )
                  : filteredPlans.isEmpty
                      ? ClayContainer(
                          borderRadius: 16,
                          depth: 6,
                          color: isDark ? const Color(0xFF1A2234) : Colors.white,
                          padding: const EdgeInsets.all(28),
                          child: Center(
                            child: Text(
                              'No data plans found for selected filter.',
                              style: TextStyle(color: subCol),
                            ),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.95,
                          ),
                          itemCount: filteredPlans.length,
                          itemBuilder: (context, index) {
                            final plan = filteredPlans[index];
                            final isSelected = _selectedPlan?.id == plan.id;

                            return ClayContainer(
                              borderRadius: 16,
                              depth: isSelected ? 10 : 5,
                              isRecessed: isSelected,
                              color: isSelected
                                  ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.15)
                                  : (isDark ? const Color(0xFF192234) : Colors.white),
                              borderColor: isSelected ? primaryColor : null,
                              borderWidth: isSelected ? 2.0 : 0.0,
                              onTap: () {
                                setState(() {
                                  _selectedPlan = plan;
                                });
                              },
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    plan.planName,
                                    style: TextStyle(
                                      color: isSelected ? primaryColor : titleCol,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppFormatters.formatCurrency(plan.price, currencySymbol),
                                    style: TextStyle(
                                      color: isSelected ? primaryColor : titleCol,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected ? primaryColor : primaryColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      plan.validity.isNotEmpty ? plan.validity : plan.typeLabel,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
              const SizedBox(height: 32),

              // Submit Purchase Button
              ClayButton(
                text: 'Purchase Data Bundle',
                icon: Icons.wifi_rounded,
                isLoading: vtuProvider.isLoading,
                onPressed: vtuProvider.isLoading ? null : _submitOrder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

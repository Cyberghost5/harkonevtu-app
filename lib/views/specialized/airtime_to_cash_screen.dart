import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/specialized_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../core/utils/formatters.dart';

import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_text_field.dart';
import '../widgets/transaction_pin_modal.dart';
import '../transaction_status_screen.dart';

class NetworkInfo {
  final String key;
  final String name;
  final String fullName;
  final Color brandColor;
  final String defaultProtocol;
  final String defaultPin;
  final String pinInstructions;

  const NetworkInfo({
    required this.key,
    required this.name,
    required this.fullName,
    required this.brandColor,
    required this.defaultProtocol,
    required this.defaultPin,
    required this.pinInstructions,
  });
}

const List<NetworkInfo> kSupportedNetworks = [
  NetworkInfo(
    key: 'mtn',
    name: 'MTN',
    fullName: 'MTN Nigeria',
    brandColor: Color(0xFFFACC15),
    defaultProtocol: "Share 'N' Sell (*321#)",
    defaultPin: '0000',
    pinInstructions: 'Default PIN is 0000. To change PIN via SMS, send "defaultPIN NewPIN NewPIN" to 321 (e.g. 0000 1234 1234).',
  ),
  NetworkInfo(
    key: 'airtel',
    name: 'Airtel',
    fullName: 'Airtel Nigeria',
    brandColor: Color(0xFFEF4444),
    defaultProtocol: "Me2U (*432#)",
    defaultPin: '1234',
    pinInstructions: 'Default PIN is 1234. To change PIN via SMS, send "PIN OldPIN NewPIN" to 432 (e.g. PIN 1234 5678).',
  ),
  NetworkInfo(
    key: 'glo',
    name: 'Glo',
    fullName: 'Globacom (Glo)',
    brandColor: Color(0xFF10B981),
    defaultProtocol: "EasyShare (*131#)",
    defaultPin: '00000',
    pinInstructions: 'Default PIN is 00000. To change PIN, dial *132*OldPIN*NewPIN*NewPIN# on your phone.',
  ),
  NetworkInfo(
    key: '9mobile',
    name: '9mobile',
    fullName: '9mobile (Etisalat)',
    brandColor: Color(0xFF0D9488),
    defaultProtocol: "Airtime Transfer (*223#)",
    defaultPin: '0000',
    pinInstructions: 'Default PIN is 0000. To change PIN, dial *247*OldPIN*NewPIN# on your phone.',
  ),
];

class AirtimeToCashScreen extends StatefulWidget {
  const AirtimeToCashScreen({super.key});

  @override
  State<AirtimeToCashScreen> createState() => _AirtimeToCashScreenState();
}

class _AirtimeToCashScreenState extends State<AirtimeToCashScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _customPinController = TextEditingController();

  String _selectedNetwork = 'mtn';
  XFile? _proofFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SpecializedProvider>(context, listen: false).fetchAirtimeToCashSettings().then((_) {
        if (!mounted) return;
        final settings = Provider.of<SpecializedProvider>(context, listen: false).airtimeToCashSettings;
        _autoSelectActiveNetwork(settings);
      });
    });

    _amountController.addListener(() {
      setState(() {});
    });
    _customPinController.addListener(() {
      setState(() {});
    });
  }

  void _autoSelectActiveNetwork(Map<String, dynamic>? settings) {
    if (settings == null) return;
    final networks = settings['networks'];
    if (networks is Map<String, dynamic>) {
      final current = networks[_selectedNetwork];
      final currentEnabled = current is Map<String, dynamic> ? (current['enabled'] != false) : true;
      if (!currentEnabled) {
        for (final net in kSupportedNetworks) {
          final data = networks[net.key];
          if (data is Map<String, dynamic> && data['enabled'] == true) {
            setState(() {
              _selectedNetwork = net.key;
            });
            break;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _customPinController.dispose();
    super.dispose();
  }

  NetworkInfo get _activeNetworkInfo {
    return kSupportedNetworks.firstWhere(
      (n) => n.key == _selectedNetwork,
      orElse: () => kSupportedNetworks.first,
    );
  }

  Map<String, dynamic>? _getNetworkData(Map<String, dynamic>? settings, String networkKey) {
    if (settings == null) return null;
    final networks = settings['networks'];
    if (networks is Map<String, dynamic> && networks[networkKey] is Map<String, dynamic>) {
      return networks[networkKey] as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> _pickProofImage() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final titleCol = isDark ? Colors.white : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attach Proof of Transfer',
              style: TextStyle(color: titleCol, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClayContainer(
                    depth: 8,
                    cornerRadius: 16,
                    color: isDark ? const Color(0xFF1E283C) : const Color(0xFFF1F5F9),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final file = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
                      if (file != null) {
                        setState(() => _proofFile = file);
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.camera_alt_rounded, size: 28, color: Color(0xFF45BAE6)),
                          SizedBox(height: 6),
                          Text('Camera', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ClayContainer(
                    depth: 8,
                    cornerRadius: 16,
                    color: isDark ? const Color(0xFF1E283C) : const Color(0xFFF1F5F9),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
                      if (file != null) {
                        setState(() => _proofFile = file);
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.photo_library_rounded, size: 28, color: Color(0xFF45BAE6)),
                          SizedBox(height: 6),
                          Text('Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submitRequest() {
    final phone = _phoneController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;
    final reference = _referenceController.text.trim();

    final specProvider = Provider.of<SpecializedProvider>(context, listen: false);
    final settings = specProvider.airtimeToCashSettings;
    final netData = _getNetworkData(settings, _selectedNetwork);

    final isEnabled = netData == null ? true : (netData['enabled'] != false);
    final receiverPhone = netData?['phone']?.toString().trim() ?? '';

    if (!isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_activeNetworkInfo.fullName} conversion is currently disabled by admin.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (receiverPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Receiver number for ${_activeNetworkInfo.fullName} has not been configured.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    final minAmount = double.tryParse(settings?['min_amount']?.toString() ?? '500') ?? 500.0;
    final maxAmount = double.tryParse(settings?['max_amount']?.toString() ?? '50000') ?? 50000.0;

    if (phone.length != 11 || amount < minAmount || amount > maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter an 11-digit sender phone number and amount (₦${minAmount.toStringAsFixed(0)} - ₦${maxAmount.toStringAsFixed(0)}).'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (_proofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach transfer proof (screenshot or receipt).'),
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
        title: '${_activeNetworkInfo.name} Airtime to Cash',
        amountText: '$currencySymbol${amount.toStringAsFixed(2)}',
        onPinConfirmed: (pin) => _executeSubmission(phone, amount, reference, pin),
      ),
    );
  }

  void _executeSubmission(String phone, double amount, String reference, String pin) {
    final proofPath = _proofFile?.path;
    _amountController.clear();
    _referenceController.clear();
    _customPinController.clear();
    setState(() => _proofFile = null);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionStatusScreen(
          title: 'Airtime to Cash',
          serviceType: 'Airtime to Cash',
          planName: '${_selectedNetwork.toUpperCase()} Conversion',
          recipient: phone,
          amount: amount,
          action: () => Provider.of<SpecializedProvider>(context, listen: false).submitAirtimeToCash(
            network: _selectedNetwork,
            phone: phone,
            amount: amount,
            proofPath: proofPath,
            reference: reference.isNotEmpty ? reference : null,
            pin: pin,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<AppConfigProvider>(context);
    final specProvider = Provider.of<SpecializedProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;
    final currencySymbol = configProvider.currencySymbol;
    final settings = specProvider.airtimeToCashSettings;

    final netInfo = _activeNetworkInfo;
    final netData = _getNetworkData(settings, _selectedNetwork);

    final isEnabled = netData == null ? true : (netData['enabled'] != false);
    final receiverPhone = netData?['phone']?.toString().trim() ?? '';
    final payoutRate = netData?['payout_rate']?.toString() ?? '80%';
    final chargePercent = netData?['charge_percent'] != null ? '${netData!['charge_percent']}%' : '20%';
    final chargeNum = double.tryParse(netData?['charge_percent']?.toString() ?? '20') ?? 20.0;
    final minAmount = settings?['min_amount']?.toString() ?? '500';
    final maxAmount = settings?['max_amount']?.toString() ?? '50000';

    final ussdTpl = netData?['ussd_template']?.toString() ?? '*321*{phone}*{amount}*{pin}#';
    final effectivePin = _customPinController.text.trim().isNotEmpty
        ? _customPinController.text.trim()
        : (netData?['default_pin']?.toString() ?? netInfo.defaultPin);
    final enteredAmount = _amountController.text.trim();
    final ussdSample = ussdTpl
        .replaceAll('{phone}', receiverPhone.isNotEmpty ? receiverPhone : 'RECEIVER')
        .replaceAll('{amount}', enteredAmount.isNotEmpty ? enteredAmount : '1000')
        .replaceAll('{pin}', effectivePin);

    final parsedAmount = double.tryParse(enteredAmount) ?? 0.0;
    final feeAmount = (parsedAmount * chargeNum) / 100;
    final receiveAmount = parsedAmount > feeAmount ? (parsedAmount - feeAmount) : 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleCol = Theme.of(context).colorScheme.onSurface;
    final subCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Airtime to Cash'),
      ),
      body: SafeArea(
        child: specProvider.isLoading && settings == null
            ? Center(child: SpinKitThreeBounce(color: primaryColor, size: 24))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Network Selection Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Network',
                          style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '4 Networks Available',
                          style: TextStyle(color: subCol, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 4 Network Selection Row
                    Row(
                      children: kSupportedNetworks.map((net) {
                        final data = _getNetworkData(settings, net.key);
                        final netEnabled = data == null ? true : (data['enabled'] != false);
                        final isSelected = _selectedNetwork == net.key;
                        final netPayout = data?['payout_rate']?.toString() ?? '80%';

                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (!netEnabled) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${net.fullName} is currently offline.'),
                                    backgroundColor: const Color(0xFFEF4444),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              setState(() {
                                _selectedNetwork = net.key;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              child: ClayContainer(
                                borderRadius: 16,
                                depth: isSelected ? 8 : 3,
                                color: isSelected
                                    ? net.brandColor.withValues(alpha: isDark ? 0.25 : 0.15)
                                    : (isDark ? const Color(0xFF192234) : Colors.white),
                                borderColor: isSelected
                                    ? net.brandColor
                                    : (netEnabled ? Colors.transparent : Colors.grey.withValues(alpha: 0.3)),
                                borderWidth: isSelected ? 2.0 : 1.0,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                child: Opacity(
                                  opacity: netEnabled ? 1.0 : 0.45,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: net.brandColor,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: net.brandColor.withValues(alpha: 0.4),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  )
                                                ]
                                              : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          net.name,
                                          style: TextStyle(
                                            color: net.key == 'mtn' ? Colors.black : Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        net.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: titleCol,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: netEnabled
                                              ? (isSelected
                                                  ? net.brandColor.withValues(alpha: 0.2)
                                                  : const Color(0xFF10B981).withValues(alpha: 0.15))
                                              : Colors.grey.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          netEnabled ? netPayout : 'Off',
                                          style: TextStyle(
                                            color: netEnabled
                                                ? (isSelected ? (isDark ? Colors.white : const Color(0xFF0F172A)) : const Color(0xFF10B981))
                                                : Colors.grey,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Destination Receiver Phone 3D Box
                    ClayContainer(
                      borderRadius: 18,
                      depth: 10,
                      color: isDark ? const Color(0xFF192234) : Colors.white,
                      borderColor: netInfo.brandColor.withValues(alpha: 0.3),
                      borderWidth: 1.0,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${netInfo.name} Receiver Number',
                                style: TextStyle(color: subCol, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isEnabled
                                      ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                      : Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isEnabled ? 'Payout: $payoutRate ($chargePercent Fee)' : 'Service Disabled',
                                  style: TextStyle(
                                    color: isEnabled ? const Color(0xFF10B981) : Colors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isEnabled
                                    ? (receiverPhone.isNotEmpty ? receiverPhone : 'Not Configured')
                                    : 'Offline',
                                style: TextStyle(
                                  color: isEnabled && receiverPhone.isNotEmpty ? titleCol : Colors.grey,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              ClayButton(
                                text: 'Copy',
                                icon: Icons.copy_rounded,
                                width: 84,
                                height: 38,
                                borderRadius: 10,
                                onPressed: isEnabled && receiverPhone.isNotEmpty
                                    ? () {
                                        Clipboard.setData(ClipboardData(text: receiverPhone));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${netInfo.name} receiver line $receiverPhone copied!'),
                                            backgroundColor: primaryColor,
                                          ),
                                        );
                                      }
                                    : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Limits: ${AppFormatters.formatCurrency(num.tryParse(minAmount.toString()) ?? 0, currencySymbol)} - ${AppFormatters.formatCurrency(num.tryParse(maxAmount.toString()) ?? 0, currencySymbol)} per request.',
                            style: TextStyle(color: subCol, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Detailed Instructions 3D ClayContainer Card
                    ClayContainer(
                      borderRadius: 18,
                      depth: 10,
                      color: isDark ? const Color(0xFF192234) : Colors.white,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.help_outline_rounded, color: primaryColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'How to Transfer Airtime on ${netInfo.name}',
                                style: TextStyle(color: titleCol, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildInstructionStep(
                            step: '1',
                            title: 'Transfer Airtime via USSD',
                            desc: 'Dial the USSD command below on your ${netInfo.name} phone line:',
                            codeSnippet: ussdSample,
                            onCopy: () {
                              Clipboard.setData(ClipboardData(text: ussdSample));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('USSD code ($ussdSample) copied!'),
                                  backgroundColor: primaryColor,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'ℹ️ ${netInfo.pinInstructions}',
                            style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, height: 1.4),
                          ),
                          const SizedBox(height: 14),
                          _buildInstructionStep(
                            step: '2',
                            title: 'Enter Transfer Details Below',
                            desc: 'Input your sending phone number, the airtime amount, and upload the proof screenshot.',
                          ),
                          const SizedBox(height: 14),
                          _buildInstructionStep(
                            step: '3',
                            title: 'Instant Automated Wallet Credit',
                            desc: 'Upon verification, $payoutRate of the transferred airtime value will be credited to your wallet balance!',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sender Phone Number 3D Recessed Input
                    Text(
                      'Your Sending Phone Number',
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
                    const SizedBox(height: 20),

                    // Amount 3D Recessed Input & Quick Chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transferred Airtime Amount',
                          style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '$currencySymbol$minAmount - $currencySymbol$maxAmount',
                          style: TextStyle(color: subCol, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClayTextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      hintText: 'e.g. $minAmount',
                      prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 10),

                    // Quick Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [500, 1000, 2000, 5000, 10000].map((preset) {
                        final isSelected = _amountController.text == preset.toString();
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _amountController.text = preset.toString();
                            });
                          },
                          child: ClayContainer(
                            borderRadius: 10,
                            depth: isSelected ? 6 : 2,
                            color: isSelected
                                ? primaryColor.withValues(alpha: 0.2)
                                : (isDark ? const Color(0xFF1E283C) : const Color(0xFFF1F5F9)),
                            borderColor: isSelected ? primaryColor : Colors.transparent,
                            borderWidth: 1.0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Text(
                              '$currencySymbol${preset.toString()}',
                              style: TextStyle(
                                color: isSelected ? primaryColor : subCol,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Live Return Summary Card
                    if (parsedAmount > 0) ...[
                      ClayContainer(
                        borderRadius: 16,
                        depth: 6,
                        color: isDark ? const Color(0xFF192234) : const Color(0xFFF8FAFC),
                        borderColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                        borderWidth: 1.0,
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You Will Receive In Wallet:',
                                  style: TextStyle(color: subCol, fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$currencySymbol${receiveAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Fee: $chargePercent (-$currencySymbol${feeAmount.toStringAsFixed(2)})',
                                style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Proof of Transfer Attachment
                    Text(
                      'Attach Proof of Payment (Screenshot / SMS Receipt)',
                      style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (_proofFile != null)
                      ClayContainer(
                        depth: 6,
                        cornerRadius: 16,
                        padding: const EdgeInsets.all(12),
                        color: isDark ? const Color(0xFF1E283C) : const Color(0xFFF1F5F9),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(_proofFile!.path),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _proofFile!.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: titleCol, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text('Proof attached successfully', style: TextStyle(color: Color(0xFF10B981), fontSize: 11)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4444)),
                              onPressed: () => setState(() => _proofFile = null),
                            ),
                          ],
                        ),
                      )
                    else
                      ClayContainer(
                        depth: 6,
                        cornerRadius: 16,
                        onTap: _pickProofImage,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        color: isDark ? const Color(0xFF1E283C) : const Color(0xFFF1F5F9),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded, color: primaryColor, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Upload Screenshot / Receipt',
                              style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Optional Transfer Reference / SMS ID
                    Text(
                      'SMS Reference / Transaction ID (Optional)',
                      style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ClayTextField(
                      controller: _referenceController,
                      hintText: 'e.g. TXN-99887766',
                      prefixIcon: const Icon(Icons.receipt_long_rounded, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    ClayButton(
                      text: isEnabled
                          ? 'Submit ${_activeNetworkInfo.name} Conversion'
                          : '${_activeNetworkInfo.name} Service Offline',
                      icon: Icons.currency_exchange_rounded,
                      isLoading: specProvider.isLoading,
                      onPressed: (specProvider.isLoading || !isEnabled || receiverPhone.isEmpty) ? null : _submitRequest,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInstructionStep({
    required String step,
    required String title,
    required String desc,
    String? codeSnippet,
    VoidCallback? onCopy,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleCol = Theme.of(context).colorScheme.onSurface;
    final subCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClayContainer(
          borderRadius: 20,
          depth: 4,
          color: primaryColor.withValues(alpha: 0.15),
          padding: const EdgeInsets.all(8),
          child: Text(
            step,
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: titleCol, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(color: subCol, fontSize: 12, height: 1.3),
              ),
              if (codeSnippet != null) ...[
                const SizedBox(height: 6),
                ClayContainer(
                  borderRadius: 10,
                  depth: 6,
                  isRecessed: true,
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        codeSnippet,
                        style: const TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      if (onCopy != null)
                        GestureDetector(
                          onTap: onCopy,
                          child: const Icon(Icons.copy_rounded, color: Color(0xFF94A3B8), size: 14),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

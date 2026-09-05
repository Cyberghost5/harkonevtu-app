import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/specialized_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';

import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_text_field.dart';
import '../widgets/transaction_pin_modal.dart';

class AirtimeToCashScreen extends StatefulWidget {
  const AirtimeToCashScreen({super.key});

  @override
  State<AirtimeToCashScreen> createState() => _AirtimeToCashScreenState();
}

class _AirtimeToCashScreenState extends State<AirtimeToCashScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final String _selectedNetwork = 'mtn';
  XFile? _proofFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user?.phone != null && authProvider.user!.phone.isNotEmpty) {
        _phoneController.text = authProvider.user!.phone;
      }
      Provider.of<SpecializedProvider>(context, listen: false).fetchAirtimeToCashSettings();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
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
    final minAmount = double.tryParse(settings?['min_amount']?.toString() ?? '1000') ?? 1000.0;

    if (phone.length < 10 || amount < minAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter valid sender phone number and amount (Minimum ₦${minAmount.toStringAsFixed(0)}).'),
          backgroundColor: const Color(0xFFEF4444),
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
        title: 'Airtime to Cash Request',
        amountText: '$currencySymbol${amount.toStringAsFixed(2)}',
        onPinConfirmed: (pin) => _executeSubmission(phone, amount, reference, pin),
      ),
    );
  }

  void _executeSubmission(String phone, double amount, String reference, String pin) async {
    final specProvider = Provider.of<SpecializedProvider>(context, listen: false);

    final response = await specProvider.submitAirtimeToCash(
      network: _selectedNetwork,
      phone: phone,
      amount: amount,
      proofPath: _proofFile?.path,
      reference: reference.isNotEmpty ? reference : null,
      pin: pin,
    );

    if (!mounted) return;

    if (response.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message.isNotEmpty
              ? response.message
              : 'Airtime to cash request submitted! Funds will credit your wallet upon transfer verification.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      _amountController.clear();
      _referenceController.clear();
      setState(() => _proofFile = null);
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
          if (mounted) _submitRequest();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<AppConfigProvider>(context);
    final specProvider = Provider.of<SpecializedProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;
    final currencySymbol = configProvider.currencySymbol;
    final settings = specProvider.airtimeToCashSettings;

    final transferPhone = settings?['transfer_phone']?.toString() ?? '09031704109';
    final payoutRate = settings?['payout_rate']?.toString() ?? '83%';
    final chargePercent = settings?['charge_percent']?.toString() ?? '17%';
    final minAmount = settings?['min_amount']?.toString() ?? '1000';
    final maxAmount = settings?['max_amount']?.toString() ?? '5000';

    final ussdSample = '*321*$transferPhone*1000*0000#';

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
                    // Network Badge 3D ClayContainer
                    ClayContainer(
                      borderRadius: 16,
                      depth: 8,
                      color: const Color(0xFFFACC15).withValues(alpha: 0.15),
                      borderColor: const Color(0xFFFACC15).withValues(alpha: 0.4),
                      borderWidth: 1.0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.phone_android_rounded, color: Color(0xFFFACC15), size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MTN Airtime Share \'N\' Sell Supported',
                                  style: TextStyle(color: titleCol, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Convert excess MTN airtime balance to wallet cash',
                                  style: TextStyle(color: subCol, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Destination Receiver Phone 3D Box
                    ClayContainer(
                      borderRadius: 18,
                      depth: 10,
                      color: isDark ? const Color(0xFF192234) : Colors.white,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'MTN Receiver Phone Number',
                                style: TextStyle(color: subCol, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Payout: $payoutRate ($chargePercent Fee)',
                                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                transferPhone,
                                style: TextStyle(
                                  color: titleCol,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              ClayButton(
                                text: 'Copy',
                                icon: Icons.copy_rounded,
                                width: 84,
                                height: 38,
                                borderRadius: 10,
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: transferPhone));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('MTN receiver number $transferPhone copied!'),
                                      backgroundColor: primaryColor,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Allowed Range: ${AppFormatters.formatCurrency(num.tryParse(minAmount.toString()) ?? 0, currencySymbol)} - ${AppFormatters.formatCurrency(num.tryParse(maxAmount.toString()) ?? 0, currencySymbol)} per request.',
                            style: TextStyle(color: subCol, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

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
                                'How to Transfer Airtime on MTN',
                                style: TextStyle(color: titleCol, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildInstructionStep(
                            step: '1',
                            title: 'Transfer Airtime via USSD',
                            desc: 'Dial *321*$transferPhone*<Amount>*<PIN># on your MTN phone.\nExample for ₦1,000:',
                            codeSnippet: ussdSample,
                            onCopy: () {
                              Clipboard.setData(ClipboardData(text: ussdSample));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('USSD code format copied!'),
                                  backgroundColor: primaryColor,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '💡 Note: Default MTN Share PIN is 0000. If you have not changed your PIN, dial *321*1*OldPIN*NewPIN*NewPIN# to set a new PIN.',
                            style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, height: 1.4),
                          ),
                          const SizedBox(height: 14),
                          _buildInstructionStep(
                            step: '2',
                            title: 'Enter Transfer Details Below',
                            desc: 'Input your sending phone number and the exact airtime amount transferred.',
                          ),
                          const SizedBox(height: 14),
                          _buildInstructionStep(
                            step: '3',
                            title: 'Submit & Get Wallet Credit',
                            desc: 'Tap Submit Transfer Request. Upon automated verification, $payoutRate of the transferred airtime value will credit your wallet instantly!',
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
                      hintText: 'e.g. 08012345678',
                      prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 20),

                    // Amount 3D Recessed Input
                    Text(
                      'Transferred Airtime Amount (₦$minAmount - ₦$maxAmount)',
                      style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ClayTextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      hintText: 'e.g. $minAmount',
                      prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 20),

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
                      text: 'Submit Transfer Request',
                      icon: Icons.currency_exchange_rounded,
                      isLoading: specProvider.isLoading,
                      onPressed: specProvider.isLoading ? null : _submitRequest,
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

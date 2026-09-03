import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/specialized_provider.dart';
import '../../providers/auth_provider.dart';

class AirtimeToCashScreen extends StatefulWidget {
  const AirtimeToCashScreen({super.key});

  @override
  State<AirtimeToCashScreen> createState() => _AirtimeToCashScreenState();
}

class _AirtimeToCashScreenState extends State<AirtimeToCashScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final String _selectedNetwork = 'mtn';

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
    super.dispose();
  }

  void _submitRequest() async {
    final phone = _phoneController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;

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

    final response = await specProvider.submitAirtimeToCash(
      network: _selectedNetwork,
      phone: phone,
      amount: amount,
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
    final specProvider = Provider.of<SpecializedProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;
    final settings = specProvider.airtimeToCashSettings;

    final transferPhone = settings?['transfer_phone']?.toString() ?? '09031704109';
    final payoutRate = settings?['payout_rate']?.toString() ?? '83%';
    final chargePercent = settings?['charge_percent']?.toString() ?? '17%';
    final minAmount = settings?['min_amount']?.toString() ?? '1000';
    final maxAmount = settings?['max_amount']?.toString() ?? '5000';

    final ussdSample = '*321*$transferPhone*1000*0000#';

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
                    // Network Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFACC15).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFACC15).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.phone_android_rounded, color: Color(0xFFFACC15), size: 22),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MTN Airtime Share \'N\' Sell Supported',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Convert excess MTN airtime balance to wallet cash',
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Destination Receiver Phone Box
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'MTN Receiver Phone Number',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: transferPhone));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('MTN receiver number $transferPhone copied!'),
                                      backgroundColor: primaryColor,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded, size: 14),
                                label: const Text('Copy Number'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Allowed Range: ₦$minAmount - ₦$maxAmount per request.',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Detailed Instructions Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF192234),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF2B364E)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.help_outline_rounded, color: primaryColor, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'How to Transfer Airtime on MTN',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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

                    // Sender Phone Number Input
                    const Text(
                      'Your Sending Phone Number',
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

                    // Amount Input
                    Text(
                      'Transferred Airtime Amount (₦$minAmount - ₦$maxAmount)',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      decoration: InputDecoration(
                        hintText: 'e.g. $minAmount',
                        prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF94A3B8)),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: specProvider.isLoading ? null : _submitRequest,
                        child: specProvider.isLoading
                            ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                            : const Text('Submit Transfer Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.3),
              ),
              if (codeSnippet != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
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

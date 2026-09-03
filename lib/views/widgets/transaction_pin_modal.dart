import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/storage/secure_storage_service.dart';

class TransactionPinModal extends StatefulWidget {
  final String title;
  final String amountText;
  final Function(String pin) onPinConfirmed;

  const TransactionPinModal({
    super.key,
    required this.title,
    required this.amountText,
    required this.onPinConfirmed,
  });

  @override
  State<TransactionPinModal> createState() => _TransactionPinModalState();
}

class _TransactionPinModalState extends State<TransactionPinModal> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isAuthenticatingBio = false;
  String? _savedPin;

  @override
  void initState() {
    super.initState();
    _checkAndPromptBiometrics();
  }

  Future<void> _checkAndPromptBiometrics() async {
    final storage = SecureStorageService();
    _savedPin = await storage.getPin();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.isBiometricAvailable && authProvider.isBiometricEnabled) {
        _triggerBiometrics(authProvider);
      }
    });
  }

  Future<void> _triggerBiometrics(AuthProvider authProvider) async {
    if (_isAuthenticatingBio) return;
    setState(() => _isAuthenticatingBio = true);

    final authenticated = await authProvider.authenticateWithBiometrics();

    if (!mounted) return;
    setState(() => _isAuthenticatingBio = false);

    if (authenticated) {
      final pin = _savedPin ?? _getPin();
      if (pin.length == 4) {
        for (int i = 0; i < 4; i++) {
          _controllers[i].text = pin[i];
        }
        Navigator.of(context).pop();
        widget.onPinConfirmed(pin);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometrics verified! Please enter your 4-digit PIN once to save it for 1-tap future biometric payments.'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _getPin() {
    return _controllers.map((c) => c.text).join();
  }

  void _handleConfirm() async {
    final pin = _getPin();
    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your complete 4-digit Transaction PIN.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // Save PIN to SecureStorage for seamless 1-tap future biometric payments
    await SecureStorageService().savePin(pin);

    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onPinConfirmed(pin);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final titleCol = Theme.of(context).colorScheme.onSurface;
    final subCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final showBiometricOption = authProvider.isBiometricAvailable && authProvider.isBiometricEnabled;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: subCol.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_outline_rounded, size: 36, color: primaryColor),
          ),
          const SizedBox(height: 16),

          Text(
            widget.title,
            style: TextStyle(color: titleCol, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            widget.amountText,
            style: TextStyle(color: primaryColor, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Enter your 4-digit Transaction PIN to confirm this order',
            style: TextStyle(color: subCol, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // 4-digit PIN row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                width: 50,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: TextFormField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  obscureText: true,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: titleCol),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: subCol.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && index < 3) {
                      _focusNodes[index + 1].requestFocus();
                    } else if (val.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }
                    if (_getPin().length == 4) {
                      _handleConfirm();
                    }
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Confirm & Pay Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleConfirm,
              child: const Text('Confirm & Pay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),

          // Biometrics Fingerprint Button (if available & enabled)
          if (showBiometricOption) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isAuthenticatingBio ? null : () => _triggerBiometrics(authProvider),
                icon: const Icon(Icons.fingerprint_rounded, size: 24),
                label: const Text(
                  'Authorize with Biometrics (Fingerprint / FaceID)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/storage/secure_storage_service.dart';
import 'clay_container.dart';
import 'clay_button.dart';

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
  final List<FocusNode> _keyboardFocusNodes = List.generate(4, (_) => FocusNode());
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

    _savedPin ??= await SecureStorageService().getPin();

    final authenticated = await authProvider.authenticateWithBiometrics();

    if (!mounted) return;
    setState(() => _isAuthenticatingBio = false);

    if (authenticated) {
      final pin = (_savedPin != null && _savedPin!.isNotEmpty) ? _savedPin! : _getPin();
      Navigator.of(context).pop();
      widget.onPinConfirmed(pin);
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
    for (var k in _keyboardFocusNodes) {
      k.dispose();
    }
    super.dispose();
  }

  String _getPin() {
    return _controllers.map((c) => c.text).join();
  }

  String? _errorMessage;

  void _handleConfirm() async {
    final pin = _getPin();
    if (pin.length < 4) {
      setState(() {
        _errorMessage = 'Please enter your complete 4-digit Transaction PIN.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

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

          if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 4-digit PIN row (Recessed 3D Clay Sockets)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                width: 52,
                height: 58,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: ClayContainer(
                  borderRadius: 14,
                  depth: 6,
                  isRecessed: true,
                  child: Center(
                    child: KeyboardListener(
                      focusNode: _keyboardFocusNodes[index],
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                          if (_controllers[index].text.isEmpty && index > 0) {
                            _controllers[index - 1].clear();
                            _focusNodes[index - 1].requestFocus();
                          }
                        }
                      },
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        obscureText: true,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: titleCol),
                        decoration: const InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                        ),
                        onChanged: (val) {
                          if (val.isNotEmpty && index < 3) {
                            _focusNodes[index + 1].requestFocus();
                          } else if (val.isEmpty && index > 0) {
                            _controllers[index - 1].clear();
                            _focusNodes[index - 1].requestFocus();
                          }
                          if (_getPin().length == 4) {
                            _handleConfirm();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // 3D Pressable Clay Confirm & Pay Button
          ClayButton(
            text: 'Confirm & Pay',
            icon: Icons.check_circle_outline_rounded,
            onPressed: _handleConfirm,
            depth: 10,
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

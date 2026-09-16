import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api/api_client.dart';
import '../core/utils/formatters.dart';
import '../providers/app_config_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/transaction_model.dart';
import 'widgets/clay_container.dart';
import 'widgets/clay_button.dart';
import 'widgets/receipt_modal.dart';

enum TransactionScreenState {
  processing,
  success,
  failed,
  pending,
}

class TransactionStatusScreen extends StatefulWidget {
  final String title;
  final String serviceType;
  final String? planName;
  final String recipient;
  final double amount;
  final Future<ApiResponse> Function() action;

  const TransactionStatusScreen({
    super.key,
    required this.title,
    required this.serviceType,
    this.planName,
    required this.recipient,
    required this.amount,
    required this.action,
  });

  @override
  State<TransactionStatusScreen> createState() => _TransactionStatusScreenState();
}

class _TransactionStatusScreenState extends State<TransactionStatusScreen>
    with TickerProviderStateMixin {
  TransactionScreenState _currentState = TransactionScreenState.processing;
  ApiResponse? _apiResponse;
  String _reference = '';
  DateTime _transactionTime = DateTime.now();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _resultController;
  late Animation<double> _scaleAnimation;

  Timer? _statusTickerTimer;
  int _currentTickerIndex = 0;
  final List<String> _processingSteps = [
    'Validating transaction details...',
    'Encrypting secure payload...',
    'Connecting to provider gateway...',
    'Awaiting network confirmation...',
    'Finalizing transaction status...',
  ];

  @override
  void initState() {
    super.initState();
    _transactionTime = DateTime.now();
    _reference = 'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}';

    // Pulse animation for processing ripple
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Result scale up animation
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _resultController,
      curve: Curves.elasticOut,
    );

    // Cycle processing ticker steps
    _statusTickerTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (_currentState == TransactionScreenState.processing && mounted) {
        setState(() {
          _currentTickerIndex = (_currentTickerIndex + 1) % _processingSteps.length;
        });
      }
    });

    // Execute API transaction
    _executeTransaction();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _resultController.dispose();
    _statusTickerTimer?.cancel();
    super.dispose();
  }

  Future<void> _executeTransaction() async {
    try {
      final response = await widget.action();
      if (!mounted) return;

      // Extract transaction data if present
      dynamic responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData['reference'] != null) {
          _reference = responseData['reference'].toString();
        } else if (responseData['transaction'] != null && responseData['transaction']['reference'] != null) {
          _reference = responseData['transaction']['reference'].toString();
        }
      }

      setState(() {
        _apiResponse = response;
        if (response.status) {
          final msg = response.message.toLowerCase();
          if (msg.contains('pending') || msg.contains('processing')) {
            _currentState = TransactionScreenState.pending;
          } else {
            _currentState = TransactionScreenState.success;
          }
        } else {
          _currentState = TransactionScreenState.failed;
        }
      });

      _pulseController.stop();
      _resultController.forward();

      // Refresh User profile and Dashboard data
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      await authProvider.fetchProfile();
      await dashboardProvider.fetchDashboardData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _apiResponse = ApiResponse(status: false, message: 'An unexpected error occurred. Please check your transaction history.');
        _currentState = TransactionScreenState.failed;
      });
      _pulseController.stop();
      _resultController.forward();
    }
  }

  void _openSupportWhatsApp(BuildContext context) async {
    final support = Provider.of<AppConfigProvider>(context, listen: false).config?.support;
    final whatsapp = (support?.whatsapp != null && support!.whatsapp.isNotEmpty)
        ? support.whatsapp
        : (support?.phone ?? '');
    if (whatsapp.isNotEmpty) {
      final cleanNum = whatsapp.replaceAll(RegExp(r'[^0-9+]'), '');
      final Uri url = Uri.parse('https://wa.me/$cleanNum?text=${Uri.encodeComponent('Hello, I need help with transaction: $_reference (${widget.title})')}');
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  void _showReceiptModal(BuildContext context) {
    final configProvider = Provider.of<AppConfigProvider>(context, listen: false);
    final currencySymbol = configProvider.currencySymbol;

    dynamic responseData = _apiResponse?.data;
    double balBefore = 0.0;
    double balAfter = 0.0;

    if (responseData is Map<String, dynamic>) {
      balBefore = double.tryParse(responseData['balance_before']?.toString() ?? '0') ?? 0.0;
      balAfter = double.tryParse(responseData['balance_after']?.toString() ?? '0') ?? 0.0;
    }

    final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(_transactionTime);
    final transaction = TransactionModel(
      id: 0,
      reference: _reference,
      type: 'debit',
      amount: widget.amount,
      balanceBefore: balBefore,
      balanceAfter: balAfter,
      description: widget.title,
      status: _currentState == TransactionScreenState.success
          ? 'success'
          : (_currentState == TransactionScreenState.pending ? 'pending' : 'failed'),
      serviceType: widget.serviceType,
      date: dateStr,
      humanDate: DateFormat('dd MMM yyyy, hh:mm a').format(_transactionTime),
      createdAt: _transactionTime.toIso8601String(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReceiptModal(
        transaction: transaction,
        currencySymbol: currencySymbol,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<AppConfigProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencySymbol = configProvider.currencySymbol;
    final titleCol = Theme.of(context).colorScheme.onSurface;
    final subCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return PopScope(
      canPop: _currentState != TransactionScreenState.processing,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _currentState == TransactionScreenState.processing
                ? _buildProcessingView(primaryColor, isDark, titleCol, subCol)
                : _buildResultView(primaryColor, currencySymbol, isDark, titleCol, subCol),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // 1. FULL SCREEN PROCESSING VIEW
  // ------------------------------------------------------------------
  Widget _buildProcessingView(Color primaryColor, bool isDark, Color titleCol, Color subCol) {
    return Center(
      key: const ValueKey('processing_view'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Pulsating Ripple Rings Container
            ScaleTransition(
              scale: _pulseAnimation,
              child: ClayContainer(
                depth: 20,
                spread: 6,
                cornerRadius: 65,
                color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
                padding: const EdgeInsets.all(28),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Service Title & Amount
            Text(
              'Processing Transaction',
              style: TextStyle(
                color: titleCol,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.serviceType.toUpperCase()} • ${widget.title}',
              style: TextStyle(
                color: primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Recipient: ${widget.recipient}',
              style: TextStyle(color: subCol, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),

            // Dynamic Step Ticker Badge
            ClayContainer(
              borderRadius: 20,
              depth: 6,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _processingSteps[_currentTickerIndex],
                      key: ValueKey<int>(_currentTickerIndex),
                      style: TextStyle(
                        color: titleCol,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Please do not close or navigate away while your transaction is being processed.',
              style: TextStyle(color: subCol.withValues(alpha: 0.8), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // 2. FULL SCREEN RESULT VIEW (SUCCESS / FAILURE / PENDING)
  // ------------------------------------------------------------------
  Widget _buildResultView(Color primaryColor, String currencySymbol, bool isDark, Color titleCol, Color subCol) {
    final bool isSuccess = _currentState == TransactionScreenState.success;
    final bool isPending = _currentState == TransactionScreenState.pending;
    final bool isFailed = _currentState == TransactionScreenState.failed;

    final Color themeColor = isSuccess
        ? const Color(0xFF10B981)
        : (isPending ? Colors.amber : const Color(0xFFEF4444));

    final IconData statusIcon = isSuccess
        ? Icons.check_circle_rounded
        : (isPending ? Icons.hourglass_top_rounded : Icons.error_rounded);

    final String statusHeading = isSuccess
        ? 'Transaction Successful!'
        : (isPending ? 'Transaction Pending' : 'Transaction Failed');

    return SingleChildScrollView(
      key: const ValueKey('result_view'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Animated Status Badge Icon
          ScaleTransition(
            scale: _scaleAnimation,
            child: ClayContainer(
              depth: 16,
              spread: 4,
              cornerRadius: 60,
              color: themeColor.withValues(alpha: isDark ? 0.25 : 0.15),
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeColor,
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(statusIcon, size: 54, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Status Heading & API Message
          Text(
            statusHeading,
            style: TextStyle(
              color: titleCol,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _apiResponse?.message ?? (isSuccess ? 'Transaction completed successfully.' : 'Unable to complete transaction.'),
              style: TextStyle(
                color: themeColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),

          // Detailed Breakdown Card
          ClayContainer(
            borderRadius: 20,
            depth: 8,
            color: isDark ? const Color(0xFF192234) : Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Amount Row
                Text(
                  'TOTAL AMOUNT',
                  style: TextStyle(color: subCol, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.formatCurrency(widget.amount, currencySymbol),
                  style: TextStyle(
                    color: titleCol,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0)),
                const SizedBox(height: 12),

                _buildResultRow('Service', widget.serviceType.toUpperCase(), titleCol, subCol),
                _buildResultRow('Item / Plan', widget.planName ?? widget.title, titleCol, subCol),
                _buildResultRow('Recipient', widget.recipient, titleCol, subCol),
                _buildResultRow('Reference', _reference, titleCol, subCol, isCopyable: true),
                _buildResultRow('Date & Time', DateFormat('dd MMM yyyy, hh:mm a').format(_transactionTime), titleCol, subCol),

                // Special PIN / Serial Token Display (For Exam PINs or Recharge Cards)
                if (isSuccess && _apiResponse?.data != null) _buildSpecialDataWidget(_apiResponse!.data, titleCol, subCol, primaryColor),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Action Buttons
          if (isSuccess) ...[
            ClayButton(
              text: 'Done & Return Home',
              icon: Icons.home_rounded,
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClayButton(
                    text: 'View Receipt',
                    icon: Icons.receipt_long_rounded,
                    depth: 6,
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    textColor: titleCol,
                    onPressed: () => _showReceiptModal(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClayButton(
                    text: 'New Order',
                    icon: Icons.add_shopping_cart_rounded,
                    depth: 6,
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    textColor: primaryColor,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ] else if (isFailed) ...[
            ClayButton(
              text: 'Try Again',
              icon: Icons.refresh_rounded,
              color: primaryColor,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClayButton(
                    text: 'Contact Support',
                    icon: Icons.support_agent_rounded,
                    depth: 6,
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    textColor: const Color(0xFF10B981),
                    onPressed: () => _openSupportWhatsApp(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClayButton(
                    text: 'Back to Home',
                    icon: Icons.home_rounded,
                    depth: 6,
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    textColor: titleCol,
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ),
              ],
            ),
          ] else ...[
            ClayButton(
              text: 'Back to Home',
              icon: Icons.home_rounded,
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color titleCol, Color subCol, {bool isCopyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: subCol, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(color: titleCol, fontSize: 13, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCopyable) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Icon(Icons.copy_rounded, size: 15, color: subCol),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialDataWidget(dynamic data, Color titleCol, Color subCol, Color primaryColor) {
    if (data is! Map<String, dynamic>) return const SizedBox.shrink();

    final pin = data['pin'] ?? data['token'] ?? data['serial'] ?? data['cards'];
    if (pin == null) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 12),
        Divider(color: Colors.grey.withValues(alpha: 0.3)),
        const SizedBox(height: 8),
        Text('YOUR PIN / TOKEN CODE', style: TextStyle(color: subCol, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                pin.toString(),
                style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.5),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: pin.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN copied to clipboard!')),
                  );
                },
                child: Icon(Icons.copy_rounded, color: primaryColor, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

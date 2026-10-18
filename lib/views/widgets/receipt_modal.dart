import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/api_client.dart';
import '../../models/transaction_model.dart';
import '../../core/utils/formatters.dart';
import 'clay_button.dart';

class ReceiptModal extends StatefulWidget {
  final TransactionModel transaction;
  final String currencySymbol;

  const ReceiptModal({
    super.key,
    required this.transaction,
    required this.currencySymbol,
  });

  @override
  State<ReceiptModal> createState() => _ReceiptModalState();
}

class _ReceiptModalState extends State<ReceiptModal> {
  String? _token;
  String? _units;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _token = widget.transaction.token;
    _units = widget.transaction.units;

    final isElectricity = widget.transaction.serviceType.toLowerCase().contains('elec') ||
        widget.transaction.description.toLowerCase().contains('elec') ||
        widget.transaction.reference.toUpperCase().startsWith('ELE');

    if ((_token == null || _token!.isEmpty) && isElectricity && widget.transaction.reference.isNotEmpty) {
      _fetchLiveTransactionDetails();
    }
  }

  Future<void> _fetchLiveTransactionDetails() async {
    setState(() => _isLoadingDetails = true);
    try {
      final res = await ApiClient().get('/wallet/transactions/${widget.transaction.reference}');
      if (res.status && res.data != null && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        final meta = data['metadata'] is Map<String, dynamic> ? (data['metadata'] as Map<String, dynamic>) : <String, dynamic>{};

        final rawToken = data['token'] ??
            meta['token'] ??
            data['purchased_code'] ??
            meta['purchased_code'] ??
            data['Token'] ??
            meta['Token'] ??
            data['mainToken'] ??
            meta['mainToken'];

        final rawUnits = data['units'] ??
            meta['units'] ??
            data['meter_units'] ??
            meta['meter_units'];

        String? fetchedToken;
        if (rawToken != null) {
          final s = rawToken.toString().trim().replaceFirst(RegExp(r'^token\s*[:\-]\s*', caseSensitive: false), '').trim();
          if (s.isNotEmpty && s.toUpperCase() != 'N/A') {
            fetchedToken = s;
          }
        }

        String? fetchedUnits;
        if (rawUnits != null) {
          final s = rawUnits.toString().trim();
          if (s.isNotEmpty && s.toUpperCase() != 'N/A') {
            fetchedUnits = s;
          }
        }

        if (mounted && (fetchedToken != null || fetchedUnits != null)) {
          setState(() {
            _token = fetchedToken ?? _token;
            _units = fetchedUnits ?? _units;
          });
        }
      }
    } catch (_) {
      // Best effort; keep original values
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'successful':
      case 'completed':
        return const Color(0xFF10B981);
      case 'pending':
      case 'processing':
        return Colors.amber;
      case 'failed':
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.transaction.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modalBg = Theme.of(context).cardColor;
    final titleColor = Theme.of(context).colorScheme.onSurface;
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final effectiveToken = _token;
    final effectiveUnits = _units;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: modalBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag handle indicator
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Icon Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.transaction.status.toLowerCase() == 'success'
                    ? Icons.check_circle_rounded
                    : (widget.transaction.status.toLowerCase() == 'pending'
                        ? Icons.hourglass_empty_rounded
                        : Icons.cancel_rounded),
                size: 44,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Transaction Receipt',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              AppFormatters.formatCurrency(widget.transaction.amount, widget.currencySymbol),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
            ),
            const SizedBox(height: 12),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                widget.transaction.status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Divider(color: isDark ? const Color(0xFF232D42) : const Color(0xFFE2E8F0)),
            const SizedBox(height: 16),

            // Detail rows
            _buildRow('Description', widget.transaction.title, context: context),
            _buildRow('Service Type', widget.transaction.serviceType.toUpperCase(), context: context),
            _buildRow(
              'Reference',
              widget.transaction.reference,
              isCopyable: true,
              context: context,
            ),

            // Token Row with Copy Button (just like Reference)
            if (effectiveToken != null && effectiveToken.isNotEmpty && effectiveToken.toUpperCase() != 'N/A') ...[
              _buildRow(
                'Token',
                effectiveToken,
                isCopyable: true,
                context: context,
              ),
            ] else if (_isLoadingDetails) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Token', style: TextStyle(color: subColor, fontSize: 14)),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ),
              ),
            ],

            if (effectiveUnits != null && effectiveUnits.isNotEmpty && effectiveUnits.toUpperCase() != 'N/A') ...[
              _buildRow(
                'Units',
                effectiveUnits,
                context: context,
              ),
            ],

            _buildRow('Date & Time', widget.transaction.formattedDate, context: context),
            _buildRow('Balance Before', AppFormatters.formatCurrency(widget.transaction.balanceBefore, widget.currencySymbol), context: context),
            _buildRow('Balance After', AppFormatters.formatCurrency(widget.transaction.balanceAfter, widget.currencySymbol), context: context),

            // Prominent Highlighted Token Display Box on Receipt
            if (effectiveToken != null && effectiveToken.isNotEmpty && effectiveToken.toUpperCase() != 'N/A') ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Text(
                      'ELECTRICITY TOKEN',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            effectiveToken,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: effectiveToken));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Token copied to clipboard!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Icon(Icons.copy_rounded, color: statusColor, size: 20),
                        ),
                      ],
                    ),
                    if (effectiveUnits != null && effectiveUnits.isNotEmpty && effectiveUnits.toUpperCase() != 'N/A') ...[
                      const SizedBox(height: 6),
                      Text(
                        'Units: $effectiveUnits',
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 3D Pressable Clay Close Button
            ClayButton(
              text: 'Close Receipt',
              icon: Icons.check_circle_outline_rounded,
              onPressed: () => Navigator.pop(context),
              depth: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isCopyable = false, required BuildContext context}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = Theme.of(context).colorScheme.onSurface;
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: subColor, fontSize: 14),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
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
                        SnackBar(
                          content: Text('$label copied to clipboard!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Icon(Icons.copy_rounded, size: 16, color: subColor),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

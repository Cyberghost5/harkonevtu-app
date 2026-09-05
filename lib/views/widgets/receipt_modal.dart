import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/transaction_model.dart';
import '../../core/utils/formatters.dart';
import 'clay_button.dart';
import 'clay_container.dart';

class ReceiptModal extends StatelessWidget {
  final TransactionModel transaction;
  final String currencySymbol;

  const ReceiptModal({
    super.key,
    required this.transaction,
    required this.currencySymbol,
  });

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
    final statusColor = _getStatusColor(transaction.status);
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modalBg = Theme.of(context).cardColor;
    final titleColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: modalBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
              transaction.status.toLowerCase() == 'success'
                  ? Icons.check_circle_rounded
                  : (transaction.status.toLowerCase() == 'pending'
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
            AppFormatters.formatCurrency(transaction.amount, currencySymbol),
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
              transaction.status.toUpperCase(),
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
          _buildRow('Description', transaction.title, context: context),
          _buildRow('Service Type', transaction.serviceType.toUpperCase(), context: context),
          _buildRow(
            'Reference',
            transaction.reference,
            isCopyable: true,
            context: context,
          ),
          _buildRow('Date & Time', transaction.formattedDate, context: context),
          _buildRow('Balance Before', AppFormatters.formatCurrency(transaction.balanceBefore, currencySymbol), context: context),
          _buildRow('Balance After', AppFormatters.formatCurrency(transaction.balanceAfter, currencySymbol), context: context),

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
                        const SnackBar(
                          content: Text('Reference copied to clipboard!'),
                          duration: Duration(seconds: 2),
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

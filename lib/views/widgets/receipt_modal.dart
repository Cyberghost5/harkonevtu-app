import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/transaction_model.dart';

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

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF151C2C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              color: const Color(0xFF334155),
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
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '$currencySymbol${transaction.amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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

          const Divider(color: Color(0xFF232D42)),
          const SizedBox(height: 16),

          // Detail rows
          _buildRow('Description', transaction.description),
          _buildRow('Service Type', transaction.serviceType.toUpperCase()),
          _buildRow(
            'Reference',
            transaction.reference,
            isCopyable: true,
            context: context,
          ),
          _buildRow('Date & Time', transaction.date.isNotEmpty ? transaction.date : transaction.humanDate),
          _buildRow('Balance Before', '$currencySymbol${transaction.balanceBefore.toStringAsFixed(2)}'),
          _buildRow('Balance After', '$currencySymbol${transaction.balanceAfter.toStringAsFixed(2)}'),

          const SizedBox(height: 24),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              child: const Text('Close Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isCopyable = false, BuildContext? context}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCopyable && context != null) ...[
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
                    child: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF94A3B8)),
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

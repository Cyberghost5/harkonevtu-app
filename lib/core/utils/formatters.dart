import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _amountFormatter = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _integerFormatter = NumberFormat('#,##0', 'en_US');

  /// Formats amount with thousand separators and 2 decimal places.
  /// Example: 15000 -> "15,000.00"
  static String formatAmount(num amount) {
    return _amountFormatter.format(amount);
  }

  /// Formats amount without trailing zeros if integer, e.g. 15000 -> "15,000"
  static String formatInteger(num amount) {
    return _integerFormatter.format(amount);
  }

  /// Formats amount with currency symbol.
  /// Example: (15000, '₦') -> "₦15,000.00"
  static String formatCurrency(num amount, [String symbol = '₦']) {
    return '$symbol${_amountFormatter.format(amount)}';
  }

  /// Formats raw date string or DateTime object into professional human readable format.
  /// Example: "2026-09-03T18:08:59.000000Z" -> "Sep 03, 2026 • 06:08 PM"
  static String formatDate(dynamic dateInput) {
    if (dateInput == null) return '';
    final str = dateInput.toString().trim();
    if (str.isEmpty) return '';

    try {
      DateTime dt;
      if (dateInput is DateTime) {
        dt = dateInput.toLocal();
      } else {
        dt = DateTime.parse(str).toLocal();
      }
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
    } catch (_) {
      return str;
    }
  }

  /// Short date format: "Sep 03, 2026"
  static String formatShortDate(dynamic dateInput) {
    if (dateInput == null) return '';
    final str = dateInput.toString().trim();
    if (str.isEmpty) return '';

    try {
      DateTime dt;
      if (dateInput is DateTime) {
        dt = dateInput.toLocal();
      } else {
        dt = DateTime.parse(str).toLocal();
      }
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {
      return str;
    }
  }
}

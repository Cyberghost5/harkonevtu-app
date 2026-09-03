import '../core/utils/formatters.dart';

class TransactionModel {
  final int id;
  final String reference;
  final String type; // 'debit' or 'credit'
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String description;
  final String status; // 'success', 'pending', 'failed'
  final String serviceType; // 'airtime', 'data', 'electricity', 'cable', 'epin', 'betting', etc.
  final String date;
  final String humanDate;
  final String createdAt;
  final Map<String, dynamic>? metadata;

  TransactionModel({
    required this.id,
    required this.reference,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.description,
    required this.status,
    required this.serviceType,
    required this.date,
    required this.humanDate,
    required this.createdAt,
    this.metadata,
  });

  String get formattedAmount => AppFormatters.formatAmount(amount);
  String get formattedBalanceBefore => AppFormatters.formatAmount(balanceBefore);
  String get formattedBalanceAfter => AppFormatters.formatAmount(balanceAfter);
  String get formattedDate => AppFormatters.formatDate(createdAt.isNotEmpty ? createdAt : (date.isNotEmpty ? date : humanDate));

  String get title {
    if (description.isNotEmpty) return description;
    return '${serviceType.toUpperCase()} Transaction';
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    final rawDate = json['created_at'] ?? json['date'] ?? json['human_date'] ?? '';
    final formattedDateStr = AppFormatters.formatDate(rawDate);

    return TransactionModel(
      id: json['id'] ?? 0,
      reference: json['reference'] ?? json['tx_ref'] ?? json['trans_id'] ?? '',
      type: json['type'] ?? 'debit',
      amount: parseDouble(json['amount']),
      balanceBefore: parseDouble(json['balance_before'] ?? json['old_balance']),
      balanceAfter: parseDouble(json['balance_after'] ?? json['new_balance']),
      description: json['description'] ?? json['title'] ?? json['service'] ?? '',
      status: json['status'] ?? 'pending',
      serviceType: json['service_type'] ?? json['service'] ?? 'service',
      date: json['date'] ?? '',
      humanDate: json['human_date'] ?? '',
      createdAt: formattedDateStr,
      metadata: json['metadata'] is Map<String, dynamic> ? json['metadata'] : null,
    );
  }
}

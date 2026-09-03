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
    this.metadata,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return TransactionModel(
      id: json['id'] ?? 0,
      reference: json['reference'] ?? '',
      type: json['type'] ?? 'debit',
      amount: parseDouble(json['amount']),
      balanceBefore: parseDouble(json['balance_before']),
      balanceAfter: parseDouble(json['balance_after']),
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      serviceType: json['service_type'] ?? 'service',
      date: json['date'] ?? '',
      humanDate: json['human_date'] ?? '',
      metadata: json['metadata'] is Map<String, dynamic> ? json['metadata'] : null,
    );
  }
}

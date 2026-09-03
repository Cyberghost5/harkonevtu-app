class DvaAccountModel {
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String? provider;

  DvaAccountModel({
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    this.provider,
  });

  factory DvaAccountModel.fromJson(Map<String, dynamic> json) {
    return DvaAccountModel(
      bankName: json['bank_name'] ?? json['bankName'] ?? 'Wema Bank',
      accountNumber: json['account_number'] ?? json['accountNumber'] ?? '',
      accountName: json['account_name'] ?? json['accountName'] ?? '',
      provider: json['provider'],
    );
  }
}

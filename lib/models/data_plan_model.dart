import '../core/utils/formatters.dart';

class DataPlanModel {
  final int id;
  final String planName;
  final String networkKey;
  final String dataType;
  final String typeLabel;
  final String validity;
  final double price;
  final double regularPrice;

  DataPlanModel({
    required this.id,
    required this.planName,
    required this.networkKey,
    required this.dataType,
    required this.typeLabel,
    required this.validity,
    required this.price,
    required this.regularPrice,
  });

  String get formattedPrice => AppFormatters.formatAmount(price);

  factory DataPlanModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return DataPlanModel(
      id: json['id'] ?? 0,
      planName: json['plan_name'] ?? json['name'] ?? '',
      networkKey: json['network_key'] ?? 'mtn',
      dataType: json['data_type'] ?? 'sme',
      typeLabel: json['type_label'] ?? 'SME',
      validity: json['validity'] ?? '',
      price: parseDouble(json['price']),
      regularPrice: parseDouble(json['regular_price'] ?? json['price']),
    );
  }
}

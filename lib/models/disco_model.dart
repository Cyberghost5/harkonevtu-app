class DiscoModel {
  final dynamic id;
  final String name;
  final String code;

  DiscoModel({
    required this.id,
    required this.name,
    required this.code,
  });

  factory DiscoModel.fromJson(Map<String, dynamic> json) {
    return DiscoModel(
      id: json['id'] ?? 1,
      name: json['name'] ?? json['disco_name'] ?? '',
      code: json['code'] ?? json['network_key'] ?? '',
    );
  }
}

class CablePlanModel {
  final dynamic id;
  final String name;
  final double price;

  CablePlanModel({
    required this.id,
    required this.name,
    required this.price,
  });

  factory CablePlanModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return CablePlanModel(
      id: json['id'] ?? json['plan_id'] ?? 1,
      name: json['name'] ?? json['plan_name'] ?? '',
      price: parseDouble(json['price'] ?? json['amount']),
    );
  }
}

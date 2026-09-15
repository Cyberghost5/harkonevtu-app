class DataTypeModel {
  final String typeKey;
  final String name;

  DataTypeModel({
    required this.typeKey,
    required this.name,
  });

  factory DataTypeModel.fromJson(Map<String, dynamic> json) {
    return DataTypeModel(
      typeKey: json['type_key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class DataNetworkModel {
  final int id;
  final String name;
  final String networkKey;
  final List<DataTypeModel> availableDataTypes;

  DataNetworkModel({
    required this.id,
    required this.name,
    required this.networkKey,
    required this.availableDataTypes,
  });

  factory DataNetworkModel.fromJson(Map<String, dynamic> json) {
    final typesList = (json['available_data_types'] as List<dynamic>?)
            ?.map((e) => DataTypeModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return DataNetworkModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      networkKey: json['network_key'] ?? '',
      availableDataTypes: typesList,
    );
  }
}

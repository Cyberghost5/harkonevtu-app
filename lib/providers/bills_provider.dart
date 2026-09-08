import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../models/disco_model.dart';

class BillsProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<DiscoModel> _discos = [];
  List<CablePlanModel> _cablePlans = [];
  bool _isLoading = false;
  bool _isValidating = false;
  String? _validatedCustomerName;
  String? _validatedAddress;
  String? _errorMessage;

  List<DiscoModel> get discos => _discos;
  List<CablePlanModel> get cablePlans => _cablePlans;
  bool get isLoading => _isLoading;
  bool get isValidating => _isValidating;
  String? get validatedCustomerName => _validatedCustomerName;
  String? get validatedAddress => _validatedAddress;
  String? get errorMessage => _errorMessage;

  void clearValidation() {
    _validatedCustomerName = null;
    _validatedAddress = null;
    notifyListeners();
  }

  Future<void> fetchDiscos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    int attempts = 0;
    bool success = false;

    while (attempts < 3 && !success) {
      attempts++;
      try {
        final response = await _apiClient.get(
          '/bills/electricity/discos',
          queryParameters: {'per_page': 100, 'limit': 100},
        );

        if (response.status && response.data != null) {
          List<dynamic>? list;
          if (response.data is List) {
            list = response.data as List<dynamic>;
          } else if (response.data is Map<String, dynamic>) {
            final map = response.data as Map<String, dynamic>;
            final rawList = map['discos'] ?? map['data'] ?? map['items'] ?? map['services'];
            if (rawList is List) {
              list = rawList;
            }
          }

          if (list != null && list.isNotEmpty) {
            _discos = list.map((item) => DiscoModel.fromJson(item as Map<String, dynamic>)).toList();
            success = true;
          }
        }
      } catch (_) {}

      if (!success && attempts < 3) {
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }

    if (_discos.isEmpty) {
      _errorMessage = 'Failed to load electricity discos. Please check your network connection and try again later.';
    }

    _isLoading = false;
    notifyListeners();
  }


  Future<bool> validateMeter({
    required dynamic discoId,
    required String meterNumber,
    required String meterType,
  }) async {
    _isValidating = true;
    _errorMessage = null;
    _validatedCustomerName = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/bills/electricity/validate-meter', data: {
        'disco_id': discoId,
        'meter_number': meterNumber,
        'meter_type': meterType.toLowerCase(),
      });

      if (response.status && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        _validatedCustomerName = data['customer_name']?.toString() ?? 'VALIDATED CUSTOMER';
        _validatedAddress = data['address']?.toString();
        _isValidating = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message.isNotEmpty ? response.message : 'Invalid meter number.';
        _isValidating = false;
        notifyListeners();
        return false;
      }
    } catch (_) {
      _errorMessage = 'Failed to validate meter number.';
      _isValidating = false;
      notifyListeners();
      return false;
    }
  }

  Future<ApiResponse> purchaseElectricity({
    required dynamic discoId,
    required String meterNumber,
    required String meterType,
    required double amount,
    required String phone,
    required String pin,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.post('/bills/electricity/purchase', data: {
        'disco_id': discoId,
        'meter_number': meterNumber,
        'meter_type': meterType.toLowerCase(),
        'amount': amount,
        'phone': phone,
        'transaction_pin': pin,
      });

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse(status: false, message: 'Electricity token purchase failed.');
    }
  }

  List<Map<String, dynamic>> _cableProviders = [];
  List<Map<String, dynamic>> get cableProviders => _cableProviders;

  Future<void> fetchCableProviders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    int attempts = 0;
    bool success = false;

    while (attempts < 3 && !success) {
      attempts++;
      try {
        var response = await _apiClient.get(
          '/bills/cable/providers',
          queryParameters: {'per_page': 100, 'limit': 100},
        );
        if (!response.status || response.data == null) {
          response = await _apiClient.get(
            '/bills/cable',
            queryParameters: {'per_page': 100, 'limit': 100},
          );
        }

        if (response.status && response.data != null) {
          List<dynamic>? list;
          if (response.data is List) {
            list = response.data as List<dynamic>;
          } else if (response.data is Map<String, dynamic>) {
            final map = response.data as Map<String, dynamic>;
            final rawList = map['providers'] ?? map['cables'] ?? map['data'] ?? map['items'] ?? map['services'];
            if (rawList is List) {
              list = rawList;
            }
          }

          if (list != null && list.isNotEmpty) {
            _cableProviders = list.map((item) {
              if (item is Map<String, dynamic>) {
                final id = item['id'] ?? item['provider_id'] ?? item['cable_id'] ?? item['code'] ?? item['key'];
                final name = item['name'] ?? item['provider_name'] ?? item['title'] ?? item['cable_name'] ?? id?.toString() ?? 'Cable TV';
                return {
                  'id': id,
                  'name': name.toString(),
                  'color': _getCableProviderColor(name.toString()),
                };
              }
              return {
                'id': item,
                'name': item.toString(),
                'color': const Color(0xFF0284C7),
              };
            }).toList();
            success = true;
          }
        }
      } catch (_) {}

      if (!success && attempts < 3) {
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }

    if (_cableProviders.isEmpty) {
      _errorMessage = 'Failed to load Cable TV providers. Please check your network connection and try again later.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Color _getCableProviderColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('dstv')) return const Color(0xFF0284C7);
    if (lower.contains('gotv')) return const Color(0xFF16A34A);
    if (lower.contains('startimes') || lower.contains('startime')) return const Color(0xFFEA580C);
    if (lower.contains('showmax')) return const Color(0xFFE11D48);
    return const Color(0xFF6366F1);
  }

  Future<void> fetchCablePlans(dynamic providerId) async {
    _isLoading = true;
    _cablePlans = [];
    _errorMessage = null;
    notifyListeners();

    int attempts = 0;
    bool success = false;

    while (attempts < 3 && !success) {
      attempts++;
      try {
        var response = await _apiClient.post('/bills/cable/plans', data: {
          'provider_id': providerId,
          'cable_id': providerId,
          'per_page': 100,
          'limit': 100,
        });

        if (!response.status || response.data == null) {
          response = await _apiClient.get(
            '/bills/cable/plans',
            queryParameters: {
              'provider_id': providerId,
              'cable_id': providerId,
              'per_page': 100,
              'limit': 100,
            },
          );
        }

        if (response.status && response.data != null) {
          dynamic listData;
          if (response.data is List) {
            listData = response.data;
          } else if (response.data is Map<String, dynamic>) {
            final map = response.data as Map<String, dynamic>;
            listData = map['plans'] ?? map['data'] ?? map['packages'] ?? map['items'];
          }

          if (listData is List) {
            _cablePlans = listData
                .map((item) => CablePlanModel.fromJson(item as Map<String, dynamic>))
                .toList();
            if (_cablePlans.isNotEmpty) success = true;
          }
        }
      } catch (_) {}

      if (!success && attempts < 3) {
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }

    if (_cablePlans.isEmpty) {
      _errorMessage = 'Failed to load package plans for this provider. Please try again later.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> validateSmartcard({
    required dynamic providerId,
    required String smartcard,
  }) async {
    _isValidating = true;
    _errorMessage = null;
    _validatedCustomerName = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/bills/cable/validate-card', data: {
        'provider_id': providerId,
        'smartcard': smartcard,
      });

      if (response.status && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        _validatedCustomerName = data['customer_name']?.toString() ?? 'VALIDATED SUBSCRIBER';
        _isValidating = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message.isNotEmpty ? response.message : 'Invalid smartcard number.';
        _isValidating = false;
        notifyListeners();
        return false;
      }
    } catch (_) {
      _errorMessage = 'Failed to validate smartcard.';
      _isValidating = false;
      notifyListeners();
      return false;
    }
  }

  Future<ApiResponse> purchaseCable({
    required dynamic providerId,
    required dynamic planId,
    required String smartcard,
    required String phone,
    required String pin,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.post('/bills/cable/purchase', data: {
        'provider_id': providerId,
        'plan_id': planId,
        'smartcard': smartcard,
        'phone': phone,
        'transaction_pin': pin,
      });

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse(status: false, message: 'Cable TV subscription failed.');
    }
  }

  List<Map<String, dynamic>> _examTypes = [];
  List<Map<String, dynamic>> get examTypes => _examTypes;

  Future<void> fetchExamTypes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    int attempts = 0;
    bool success = false;

    while (attempts < 3 && !success) {
      attempts++;
      try {
        final response = await _apiClient.get(
          '/bills/exam-pins/types',
          queryParameters: {'per_page': 100, 'limit': 100},
        );
        if (response.status && response.data != null) {
          dynamic typesData;
          if (response.data is Map && response.data['types'] != null) {
            typesData = response.data['types'];
          } else if (response.data is Map && response.data['data'] != null && response.data['data']['types'] != null) {
            typesData = response.data['data']['types'];
          } else if (response.data is List) {
            typesData = response.data;
          }

          if (typesData is List) {
            _examTypes = typesData.map((e) {
              final map = Map<String, dynamic>.from(e as Map);
              return {
                'id': map['id'],
                'name': map['name'] ?? map['title'] ?? 'Exam PIN',
                'price': (map['unit_price'] ?? map['price'] ?? 0).toDouble(),
                'code': map['code'],
              };
            }).toList();
            if (_examTypes.isNotEmpty) success = true;
          }
        }
      } catch (e) {
        debugPrint('Error fetching exam pin types: $e');
      }

      if (!success && attempts < 3) {
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }

    if (_examTypes.isEmpty) {
      _errorMessage = 'Failed to load exam PIN services. Please check your network connection and try again later.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<ApiResponse> purchaseExamPin({
    required dynamic examTypeId,
    required int quantity,
    required String phone,
    required String pin,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final parsedId = int.tryParse(examTypeId.toString()) ?? examTypeId;
      final payload = {
        'exam_type_id': parsedId,
        'quantity': quantity,
        'phone': phone,
        'pin': pin,
        'transaction_pin': pin,
      };

      final response = await _apiClient.post('/bills/exam-pins/purchase', data: payload);

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse(status: false, message: 'Exam PIN purchase failed.');
    }
  }
}

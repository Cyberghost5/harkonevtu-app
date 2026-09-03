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
    try {
      final response = await _apiClient.get('/bills/electricity/discos');
      if (response.status && response.data != null) {
        final list = response.data as List<dynamic>?;
        if (list != null) {
          _discos = list.map((item) => DiscoModel.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {
      // Fallback default Discos
      _discos = [
        DiscoModel(id: 1, name: 'Abuja Electricity (AEDC)', code: 'abuja'),
        DiscoModel(id: 2, name: 'Eko Electricity (EKEDC)', code: 'eko'),
        DiscoModel(id: 3, name: 'Ikeja Electric (IKEDC)', code: 'ikeja'),
        DiscoModel(id: 4, name: 'Ibadan Electricity (IBEDC)', code: 'ibadan'),
        DiscoModel(id: 5, name: 'Enugu Electricity (EEDC)', code: 'enugu'),
        DiscoModel(id: 6, name: 'Kano Electricity (KEDCO)', code: 'kano'),
        DiscoModel(id: 7, name: 'Port Harcourt (PHED)', code: 'portharcourt'),
      ];
    }
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

  Future<void> fetchCablePlans(dynamic providerId) async {
    _isLoading = true;
    _cablePlans = [];
    notifyListeners();

    try {
      var response = await _apiClient.post('/bills/cable/plans', data: {
        'provider_id': providerId,
        'cable_id': providerId,
      });

      if (!response.status || response.data == null) {
        response = await _apiClient.get('/bills/cable/plans', queryParameters: {'provider_id': providerId});
      }

      if (response.status && response.data != null) {
        dynamic listData;
        if (response.data is List) {
          listData = response.data;
        } else if (response.data is Map<String, dynamic>) {
          final map = response.data as Map<String, dynamic>;
          listData = map['plans'] ?? map['data'] ?? map['packages'];
        }

        if (listData is List) {
          _cablePlans = listData
              .map((item) => CablePlanModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  Future<ApiResponse> purchaseExamPin({
    required dynamic examTypeId,
    required int quantity,
    required String phone,
    required String pin,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.post('/bills/exam-pins/purchase', data: {
        'exam_type_id': examTypeId,
        'quantity': quantity,
        'phone': phone,
        'pin': pin,
      });

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

import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../models/data_plan_model.dart';

class VtuProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  String? _detectedNetwork;
  List<DataPlanModel> _dataPlans = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get detectedNetwork => _detectedNetwork;
  List<DataPlanModel> get dataPlans => _dataPlans;
  String? get errorMessage => _errorMessage;

  void clearNetworkLookup() {
    _detectedNetwork = null;
    notifyListeners();
  }

  Future<String?> lookupNetwork(String phone) async {
    if (phone.length < 10) return null;
    try {
      final response = await _apiClient.post('/airtime/network-lookup', data: {'phone': phone});
      if (response.status && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        _detectedNetwork = data['network_key']?.toString();
        notifyListeners();
        return _detectedNetwork;
      }
    } catch (_) {}
    return null;
  }

  Future<ApiResponse> purchaseAirtime({
    required String network,
    required String phone,
    required double amount,
    required String pin,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/airtime/purchase', data: {
        'network': network.toLowerCase(),
        'phone': phone,
        'amount': amount,
        'airtime_type': 'VTU',
        'transaction_pin': pin,
      });

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse(status: false, message: 'Airtime purchase failed.');
    }
  }

  Future<void> fetchDataPlans(String networkKey) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/data/plans', queryParameters: {'network': networkKey.toLowerCase()});
      if (response.status && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final list = data['plans'] as List<dynamic>?;
        if (list != null) {
          _dataPlans = list
              .map((item) => DataPlanModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch data plans.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ApiResponse> purchaseData({
    required int planId,
    required String phone,
    required String pin,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/data/purchase', data: {
        'plan_id': planId,
        'phone': phone,
        'transaction_pin': pin,
      });

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse(status: false, message: 'Data purchase failed.');
    }
  }
}

import 'package:flutter/material.dart';
import '../core/api/api_client.dart';

class SpecializedProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  bool _isValidating = false;
  String? _validatedCustomerName;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isValidating => _isValidating;
  String? get validatedCustomerName => _validatedCustomerName;
  String? get errorMessage => _errorMessage;

  void clearValidation() {
    _validatedCustomerName = null;
    notifyListeners();
  }

  Future<bool> validateBettingAccount({
    required String platform,
    required String customerId,
  }) async {
    _isValidating = true;
    _errorMessage = null;
    _validatedCustomerName = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/betting/validate-account', data: {
        'platform': platform.toLowerCase(),
        'customer_id': customerId,
      });

      if (response.status && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        _validatedCustomerName = data['customer_name']?.toString() ?? 'VALIDATED BETTING ACCOUNT';
        _isValidating = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message.isNotEmpty ? response.message : 'Invalid customer ID.';
        _isValidating = false;
        notifyListeners();
        return false;
      }
    } catch (_) {
      _errorMessage = 'Failed to validate betting account.';
      _isValidating = false;
      notifyListeners();
      return false;
    }
  }

  Future<ApiResponse> fundBetting({
    required String platform,
    required String customerId,
    required double amount,
    required String customerName,
    required String pin,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.post('/betting/fund', data: {
        'platform': platform.toLowerCase(),
        'customer_id': customerId,
        'amount': amount,
        'customer_name': customerName,
        'pin': pin,
      });

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse(status: false, message: 'Betting wallet funding failed.');
    }
  }

  Map<String, dynamic>? _airtimeToCashSettings;
  Map<String, dynamic>? get airtimeToCashSettings => _airtimeToCashSettings;

  Future<void> fetchAirtimeToCashSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.get('/airtime-to-cash/settings');
      if (response.status && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          _airtimeToCashSettings = response.data as Map<String, dynamic>;
        }
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ApiResponse> submitAirtimeToCash({
    required String network,
    required String phone,
    required double amount,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.post('/airtime-to-cash/submit', data: {
        'network': network.toLowerCase(),
        'phone': phone,
        'amount': amount,
      });

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse(status: false, message: 'Airtime to cash request failed.');
    }
  }

  Future<ApiResponse> redeemCoupon(String code) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.post('/payments/redeem-coupon', data: {
        'code': code.trim(),
      });

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse(status: false, message: 'Failed to redeem coupon code.');
    }
  }

  Future<ApiResponse> generateVouchers({
    required String network,
    required double denomination,
    required int quantity,
    required String pin,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.post('/vouchers/generate', data: {
        'network': network.toLowerCase(),
        'denomination': denomination,
        'quantity': quantity,
        'pin': pin,
      });

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse(status: false, message: 'Voucher generation failed.');
    }
  }
}

import 'package:flutter/material.dart';
import '../core/api/api_client.dart';

class SpecializedProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  bool _isValidating = false;
  String? _validatedCustomerName;
  String? _errorMessage;
  List<Map<String, dynamic>> _bettingPlatforms = [];

  bool get isLoading => _isLoading;
  bool get isValidating => _isValidating;
  String? get validatedCustomerName => _validatedCustomerName;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get bettingPlatforms => _bettingPlatforms;

  void clearValidation() {
    _validatedCustomerName = null;
    notifyListeners();
  }

  Future<void> fetchBettingPlatforms() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    int attempts = 0;
    bool success = false;

    while (attempts < 3 && !success) {
      attempts++;
      try {
        var response = await _apiClient.get(
          '/betting/platforms',
          queryParameters: {'per_page': 100, 'limit': 100},
        );
        if (!response.status || response.data == null) {
          response = await _apiClient.get(
            '/betting',
            queryParameters: {'per_page': 100, 'limit': 100},
          );
        }

        if (response.status && response.data != null) {
          List<dynamic>? list;
          if (response.data is List) {
            list = response.data as List<dynamic>;
          } else if (response.data is Map<String, dynamic>) {
            final map = response.data as Map<String, dynamic>;
            final rawList = map['platforms'] ?? map['data'] ?? map['items'] ?? map['services'] ?? map['betting'];
            if (rawList is List) {
              list = rawList;
            }
          }

          if (list != null && list.isNotEmpty) {
            _bettingPlatforms = list.map((item) {
              if (item is Map<String, dynamic>) {
                final key = item['key'] ?? item['code'] ?? item['platform'] ?? item['id']?.toString() ?? '';
                final name = item['name'] ?? item['platform_name'] ?? item['title'] ?? key;
                return {
                  'key': key.toString(),
                  'name': name.toString(),
                  'color': _getPlatformColor(key.toString()),
                };
              }
              return {
                'key': item.toString(),
                'name': item.toString(),
                'color': const Color(0xFF0284C7),
              };
            }).toList();
            if (_bettingPlatforms.isNotEmpty) success = true;
          }
        }
      } catch (_) {}

      if (!success && attempts < 3) {
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }

    if (_bettingPlatforms.isEmpty) {
      _errorMessage = 'Failed to load betting platforms. Please check your network connection and try again later.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Color _getPlatformColor(String key) {
    final lowerKey = key.toLowerCase();
    if (lowerKey.contains('sporty')) return const Color(0xFFDC2626);
    if (lowerKey.contains('9ja')) return const Color(0xFF16A34A);
    if (lowerKey.contains('1x')) return const Color(0xFF0284C7);
    if (lowerKey.contains('king')) return const Color(0xFF1D4ED8);
    if (lowerKey.contains('way')) return const Color(0xFF2563EB);
    if (lowerKey.contains('naira')) return const Color(0xFF059669);
    if (lowerKey.contains('merry')) return const Color(0xFF9333EA);
    if (lowerKey.contains('bang')) return const Color(0xFFCA8A04);
    if (lowerKey.contains('msport')) return const Color(0xFFE11D48);
    if (lowerKey.contains('mel')) return const Color(0xFFF59E0B);
    return const Color(0xFF0284C7);
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
    String? proofPath,
    String? reference,
    String? pin,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        'network': network.toLowerCase(),
        'phone': phone,
        'amount': amount,
        if (reference != null && reference.isNotEmpty) 'reference': reference,
        if (proofPath != null && proofPath.isNotEmpty) 'proof_image': proofPath,
        if (proofPath != null && proofPath.isNotEmpty) 'proof': proofPath,
        if (pin != null && pin.isNotEmpty) 'pin': pin,
        if (pin != null && pin.isNotEmpty) 'transaction_pin': pin,
      };

      final response = await _apiClient.post('/airtime-to-cash/submit', data: payload);

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
        'type': 'airtime',
        'network': network.toLowerCase(),
        'value': denomination,
        'denomination': denomination,
        'quantity': quantity,
        'transaction_pin': pin,
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

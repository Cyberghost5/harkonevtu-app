import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../models/transaction_model.dart';
import '../models/dva_account_model.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<TransactionModel> _recentTransactions = [];
  List<DvaAccountModel> _dvaAccounts = [];
  Map<String, dynamic>? _referralSummary;
  List<dynamic> _referralHistory = [];
  bool _isLoadingTransactions = false;
  bool _isLoadingDva = false;
  bool _isLoadingReferrals = false;
  bool _hideBalance = false;
  String? _errorMessage;

  List<TransactionModel> get recentTransactions => _recentTransactions;
  List<DvaAccountModel> get dvaAccounts => _dvaAccounts;
  Map<String, dynamic>? get referralSummary => _referralSummary;
  List<dynamic> get referralHistory => _referralHistory;
  bool get isLoadingTransactions => _isLoadingTransactions;
  bool get isLoadingDva => _isLoadingDva;
  bool get isLoadingReferrals => _isLoadingReferrals;
  bool get hideBalance => _hideBalance;
  String? get errorMessage => _errorMessage;

  void toggleHideBalance() {
    _hideBalance = !_hideBalance;
    notifyListeners();
  }

  Future<void> fetchDashboardData() async {
    await Future.wait([
      fetchRecentTransactions(),
      fetchDvaAccounts(),
    ]);
  }

  Future<void> fetchRecentTransactions() async {
    _isLoadingTransactions = true;
    notifyListeners();

    try {
      final response = await _apiClient.get('/wallet/transactions');
      if (response.status && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final list = data['transactions'] as List<dynamic>?;
        if (list != null) {
          _recentTransactions = list
              .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load transactions.';
    } finally {
      _isLoadingTransactions = false;
      notifyListeners();
    }
  }

  Future<void> fetchDvaAccounts() async {
    _isLoadingDva = true;
    notifyListeners();

    try {
      final response = await _apiClient.get('/payments/dva-accounts');
      if (response.status && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final list = data['accounts'] as List<dynamic>?;
        if (list != null && list.isNotEmpty) {
          _dvaAccounts = list
              .map((item) => DvaAccountModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {
    } finally {
      _isLoadingDva = false;
      notifyListeners();
    }
  }

  Future<ApiResponse> generateDva(String bvn) async {
    _isLoadingDva = true;
    notifyListeners();

    try {
      final response = await _apiClient.post('/user/dva/generate', data: {
        'bvn': bvn.trim(),
      });

      if (response.status) {
        await fetchDvaAccounts();
      } else {
        _isLoadingDva = false;
        notifyListeners();
      }
      return response;
    } catch (_) {
      _isLoadingDva = false;
      notifyListeners();
      return ApiResponse(status: false, message: 'Failed to generate Virtual Bank Account.');
    }
  }

  Future<void> fetchReferralSummary() async {
    _isLoadingReferrals = true;
    notifyListeners();

    try {
      final response = await _apiClient.get('/referrals/summary');
      if (response.status && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          _referralSummary = response.data as Map<String, dynamic>;
        }
      }
    } catch (_) {
    } finally {
      _isLoadingReferrals = false;
      notifyListeners();
    }
  }

  Future<void> fetchReferralHistory() async {
    try {
      final response = await _apiClient.get('/referrals/history');
      if (response.status && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          final map = response.data as Map<String, dynamic>;
          final list = map['data'] ?? map['history'] ?? map['referrals'];
          if (list is List) {
            _referralHistory = list;
            notifyListeners();
          }
        } else if (response.data is List) {
          _referralHistory = response.data as List;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<ApiResponse> withdrawReferralEarnings() async {
    try {
      final response = await _apiClient.post('/referrals/withdraw');
      if (response.status) {
        await fetchReferralSummary();
        await fetchDashboardData();
      }
      return response;
    } catch (e) {
      return ApiResponse(status: false, message: 'Failed to withdraw referral earnings.');
    }
  }
}

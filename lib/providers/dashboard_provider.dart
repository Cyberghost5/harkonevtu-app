import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../models/transaction_model.dart';
import '../models/dva_account_model.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<TransactionModel> _recentTransactions = [];
  List<DvaAccountModel> _dvaAccounts = [];
  bool _isLoadingTransactions = false;
  bool _isLoadingDva = false;
  bool _hideBalance = false;
  String? _errorMessage;

  List<TransactionModel> get recentTransactions => _recentTransactions;
  List<DvaAccountModel> get dvaAccounts => _dvaAccounts;
  bool get isLoadingTransactions => _isLoadingTransactions;
  bool get isLoadingDva => _isLoadingDva;
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
}

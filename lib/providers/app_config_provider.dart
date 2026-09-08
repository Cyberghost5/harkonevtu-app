import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/app_config_model.dart';

import '../core/services/connectivity_service.dart';

class AppConfigProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storage = SecureStorageService();
  final ConnectivityService _connectivityService = ConnectivityService();

  AppConfigModel? _config;
  bool _isLoading = true;
  bool _isInitialized = false;
  bool _isOffline = false;
  String? _errorMessage;
  ThemeMode _themeMode = ThemeMode.system;

  AppConfigModel? get config => _config;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isOffline => _isOffline;
  String? get errorMessage => _errorMessage;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  AppConfigProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final mode = await _storage.getThemeMode();
    if (mode == 'light') {
      _themeMode = ThemeMode.light;
    } else if (mode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _storage.saveThemeMode(isDark ? 'dark' : 'light');
    notifyListeners();
  }

  String get appName => _config?.appName ?? '';
  String get themeColorHex => _config?.themeColor ?? '#45bae6';
  String get currencySymbol => _config?.currencySymbol ?? '₦';
  String get currency => _config?.currency ?? 'NGN';
  bool get isMaintenance => _config?.maintenanceMode ?? false;
  bool get isForceUpdate => _config?.forceUpdate ?? false;
  String get maintenanceMessage => _config?.maintenanceMessage ?? 'Platform under maintenance.';

  Future<void> fetchAppConfig() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // First check connectivity before making request
    final hasConnection = await _connectivityService.hasInternetConnection();
    if (!hasConnection) {
      _isOffline = true;
      _isLoading = false;
      _isInitialized = false;
      notifyListeners();
      return;
    }

    try {
      final response = await _apiClient.get('/app-config');

      if (response.status && response.data != null) {
        _config = AppConfigModel.fromJson(response.data as Map<String, dynamic>);
        _isInitialized = true;
        _isOffline = false;
      } else {
        _errorMessage = response.message.isNotEmpty ? response.message : 'Failed to fetch config.';
        _isOffline = true;
        _isInitialized = false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isOffline = true;
      _isInitialized = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}


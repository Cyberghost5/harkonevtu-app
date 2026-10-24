import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  String _installedVersion = '4.0.0';
  String _installedBuildNumber = '0';

  AppConfigModel? get config => _config;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isOffline => _isOffline;
  String? get errorMessage => _errorMessage;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get installedVersion => _installedVersion;
  String get installedBuildNumber => _installedBuildNumber;
  String get serverAppVersion => _config?.appVersion ?? _installedVersion;
  String get serverMinVersion => _config?.minVersion ?? '1.0.0';
  double get agentUpgradeFee => _config?.agentUpgradeFee ?? 2500.0;
  double get kycFee => _config?.kycFee ?? 0.0;

  AppConfigProvider() {
    _loadThemeMode();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) {
        _installedVersion = info.version;
        _installedBuildNumber = info.buildNumber;
        ApiClient.currentAppVersion = info.version;
        notifyListeners();
      }
    } catch (_) {}
  }

  static int compareVersions(String v1, String v2) {
    String clean1 = v1.trim().toLowerCase();
    if (clean1.startsWith('v')) clean1 = clean1.substring(1);
    clean1 = clean1.split('+').first.split('-').first.trim();

    String clean2 = v2.trim().toLowerCase();
    if (clean2.startsWith('v')) clean2 = clean2.substring(1);
    clean2 = clean2.split('+').first.split('-').first.trim();

    if (clean1.isEmpty && clean2.isEmpty) return 0;
    if (clean1.isEmpty) return -1;
    if (clean2.isEmpty) return 1;

    final parts1 = clean1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final parts2 = clean2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (int i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }
    return 0;
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

  /// Check whether an update is available (installed < server version)
  bool get isUpdateAvailable {
    if (_config == null) return false;
    return compareVersions(_installedVersion, _config!.appVersion) < 0;
  }

  /// Check whether force update is required.
  /// If installedVersion >= target version, force update is ALWAYS FALSE.
  bool get isForceUpdate {
    if (_config == null) return false;

    final targetVersion = _config!.appVersion.trim();
    final minVersion = _config!.minVersion.trim();

    // 1. If installed version is already >= targetVersion, NEVER force update!
    if (targetVersion.isNotEmpty && compareVersions(_installedVersion, targetVersion) >= 0) {
      return false;
    }

    // 2. If installed version is below minimum supported version, MUST update
    if (minVersion.isNotEmpty && compareVersions(_installedVersion, minVersion) < 0) {
      return true;
    }

    // 3. If admin set forceUpdate to true AND installed version is below target version
    if (_config!.forceUpdate && targetVersion.isNotEmpty && compareVersions(_installedVersion, targetVersion) < 0) {
      return true;
    }

    return false;
  }

  String get maintenanceMessage => _config?.maintenanceMessage ?? 'Platform under maintenance.';
  String? get updateUrl => _config?.updateUrl ?? _config?.playStoreUrl ?? _config?.appStoreUrl;
  String? get playStoreUrl => _config?.playStoreUrl;
  String? get appStoreUrl => _config?.appStoreUrl;
  bool get isGoogleAuthEnabled => _config?.googleAuthEnabled ?? true;
  String get googleClientId => _config?.googleClientId ?? '';
  double get agentUpgradeFee => _config?.agentUpgradeFee ?? 2500.0;
  SupportInfoModel? get support => _config?.support;
  String? get logo1Url => _config?.logo1Url;
  String? get logo2Url => _config?.logo2Url;

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
      await _loadPackageInfo();
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


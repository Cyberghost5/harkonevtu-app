import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/app_config_model.dart';

class AppConfigProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storage = SecureStorageService();

  AppConfigModel? _config;
  bool _isLoading = true;
  bool _isInitialized = false;
  String? _errorMessage;
  ThemeMode _themeMode = ThemeMode.system;

  AppConfigModel? get config => _config;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
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

    try {
      final response = await _apiClient.get('/app-config');

      if (response.status && response.data != null) {
        _config = AppConfigModel.fromJson(response.data as Map<String, dynamic>);
        _isInitialized = true;
      } else {
        _errorMessage = response.message.isNotEmpty ? response.message : 'Failed to fetch config.';
        _useFallbackConfig();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _useFallbackConfig();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _useFallbackConfig() {
    _config ??= AppConfigModel(
      appName: 'Harkone VTU',
      siteName: 'Harkone VTU',
      themeColor: '#45bae6',
      currency: 'NGN',
      currencySymbol: '₦',
      appVersion: '1.0.0',
      minVersion: '1.0.0',
      forceUpdate: false,
      maintenanceMode: false,
      maintenanceMessage: 'Platform is under routine maintenance. Please check back shortly.',
      services: AppServicesModel(),
      paymentGateways: PaymentGatewaysModel(
        activeGateway: 'paystack',
        paystackPublicKey: '',
        monnifyApiKey: '',
        monnifyContractNo: '',
      ),
      support: SupportInfoModel(
        phone: '',
        whatsapp: '',
        email: '',
        hours: '24/7',
        whatsappGroup: '',
        telegramChannel: '',
      ),
      onboardingSlides: [
        OnboardingSlideModel(
          id: 1,
          title: 'Instant Airtime & Cheap Data',
          description: 'Top up airtime and buy SME & Gifting data bundles instantly across MTN, Airtel, Glo, and 9mobile at wholesale prices.',
          sortOrder: 1,
        ),
        OnboardingSlideModel(
          id: 2,
          title: 'Pay Utilities & Cable TV',
          description: 'Pay electricity bills (Prepaid/Postpaid) and renew DSTV, GOtv, and StarTimes subscriptions with zero hassle.',
          sortOrder: 2,
        ),
        OnboardingSlideModel(
          id: 3,
          title: '24/7 Automated Wallet Funding',
          description: 'Get dedicated virtual bank accounts for instant automated wallet funding anytime, day or night.',
          sortOrder: 3,
        ),
      ],
    );
    _isInitialized = true;
  }
}

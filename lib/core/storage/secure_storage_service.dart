import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static const String _keyToken = 'sanctum_token';
  static const String _keyUser = 'user_data';
  static const String _keyPin = 'transaction_pin';
  static const String _keyBiometrics = 'biometrics_enabled';
  static const String _keyFirstTime = 'first_time_install';

  // Token Management
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  // User Data Management
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: _keyUser, value: jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: _keyUser);
    if (data != null) {
      try {
        return jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> deleteUserData() async {
    await _storage.delete(key: _keyUser);
  }

  // Transaction PIN Management
  Future<void> savePin(String pin) async {
    await _storage.write(key: _keyPin, value: pin);
  }

  Future<String?> getPin() async {
    return await _storage.read(key: _keyPin);
  }

  Future<bool> hasPin() async {
    final pin = await getPin();
    return pin != null && pin.isNotEmpty;
  }

  // Biometrics Preference
  static const String _keyBioLogin = 'biometric_login_credentials';

  Future<void> saveBiometricCredentials(String login, String password) async {
    await _storage.write(key: _keyBioLogin, value: jsonEncode({'login': login, 'password': password}));
  }

  Future<Map<String, String>?> getBiometricCredentials() async {
    final val = await _storage.read(key: _keyBioLogin);
    if (val != null) {
      try {
        final decoded = jsonDecode(val) as Map<String, dynamic>;
        return {'login': decoded['login'].toString(), 'password': decoded['password'].toString()};
      } catch (_) {}
    }
    return null;
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometrics, value: enabled.toString());
  }

  Future<bool> isBiometricsEnabled() async {
    final val = await _storage.read(key: _keyBiometrics);
    return val == 'true';
  }

  // Onboarding status
  Future<bool> isFirstTimeInstall() async {
    final val = await _storage.read(key: _keyFirstTime);
    return val == null;
  }

  Future<void> setFirstTimeCompleted() async {
    await _storage.write(key: _keyFirstTime, value: 'false');
  }

  // Theme Mode Storage
  static const String _keyThemeMode = 'app_theme_mode';

  Future<void> saveThemeMode(String mode) async {
    await _storage.write(key: _keyThemeMode, value: mode);
  }

  Future<String?> getThemeMode() async {
    return await _storage.read(key: _keyThemeMode);
  }

  // Clear Session
  Future<void> clearSession() async {
    await deleteToken();
    await deleteUserData();
    await _storage.delete(key: _keyPin);
    await _storage.delete(key: _keyBioLogin);
    await setBiometricsEnabled(false);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

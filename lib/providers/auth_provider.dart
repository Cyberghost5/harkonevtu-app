import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../core/api/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storage = SecureStorageService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isBiometricAvailable => _isBiometricAvailable;
  bool get isBiometricEnabled => _isBiometricEnabled;

  AuthProvider() {
    _initSession();
  }

  Future<void> _initSession() async {
    _token = await _storage.getToken();
    final userData = await _storage.getUserData();
    if (userData != null) {
      _user = UserModel.fromJson(userData);
    }
    await checkBiometricsAvailability();
    _isBiometricEnabled = await _storage.isBiometricsEnabled();

    if (_token != null && _token!.isNotEmpty) {
      await fetchProfile();
    }
    notifyListeners();
  }

  Future<void> checkBiometricsAvailability() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      _isBiometricAvailable = canAuthenticateWithBiometrics && isDeviceSupported;
    } catch (_) {
      _isBiometricAvailable = false;
    }
    notifyListeners();
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck && !isSupported) return false;

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        final creds = await _storage.getBiometricCredentials();
        if (creds != null && creds['login'] != null && creds['password'] != null) {
          return await login(creds['login']!, creds['password']!);
        }
      }
      return didAuthenticate;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleBiometrics(bool enable) async {
    _isBiometricEnabled = enable;
    await _storage.setBiometricsEnabled(enable);
    notifyListeners();
  }

  Future<bool> login(String loginInput, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/auth/login', data: {
        'login': loginInput,
        'password': password,
      });

      if (response.status) {
        if (response.data != null && response.data['token'] != null) {
          _token = response.data['token'].toString();
          await _storage.saveToken(_token!);
          await _storage.saveBiometricCredentials(loginInput, password);
          if (response.data['user'] != null) {
            _user = UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
            await _storage.saveUserData(_user!.toJson());
          }
        } _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message.isNotEmpty ? response.message : 'Login failed.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during login.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String username,
    required String email,
    required String phone,
    required String password,
    String? referralCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = {
        'name': name,
        'username': username,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
        if (referralCode != null && referralCode.isNotEmpty) 'referral_code': referralCode,
      };

      final response = await _apiClient.post('/auth/register', data: payload);

      if (response.status) {
        if (response.data != null && response.data['token'] != null) {
          _token = response.data['token'].toString();
          await _storage.saveToken(_token!);
          if (response.data['user'] != null) {
            _user = UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
            await _storage.saveUserData(_user!.toJson());
          }
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        if (response.errors != null && response.errors!.isNotEmpty) {
          final firstErr = response.errors!.values.first;
          if (firstErr is List && firstErr.isNotEmpty) {
            _errorMessage = firstErr.first.toString();
          } else {
            _errorMessage = firstErr.toString();
          }
        } else {
          _errorMessage = response.message.isNotEmpty ? response.message : 'Registration failed.';
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during registration.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/auth/verify-otp', data: {
        'email': email,
        'otp': otp,
      });

      if (response.status) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message.isNotEmpty ? response.message : 'Invalid OTP code.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to verify OTP.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendOtp(String email) async {
    try {
      final response = await _apiClient.post('/auth/resend-otp', data: {'email': email});
      if (!response.status) {
        _errorMessage = response.message;
      }
      return response.status;
    } catch (_) {
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/auth/forgot-password', data: {'email': email});
      if (response.status) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message.isNotEmpty ? response.message : 'Failed to send reset code.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (_) {
      _errorMessage = 'Error requesting password reset.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/auth/reset-password', data: {
        'email': email,
        'otp': otp,
        'password': newPassword,
        'password_confirmation': newPassword,
      });

      if (response.status) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message.isNotEmpty ? response.message : 'Failed to reset password.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (_) {
      _errorMessage = 'Error resetting password.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchProfile() async {
    try {
      final response = await _apiClient.get('/auth/me');
      if (response.status && response.data != null) {
        final userData = response.data as Map<String, dynamic>;
        _user = UserModel.fromJson(userData);
        await _storage.saveUserData(_user!.toJson());
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (_) {}
    _token = null;
    _user = null;
    await _storage.clearSession();
    notifyListeners();
  }
}

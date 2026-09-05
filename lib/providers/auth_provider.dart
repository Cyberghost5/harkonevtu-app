import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../core/api/api_client.dart';
import '../core/services/notification_service.dart';
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
          NotificationService().syncDeviceToken(_apiClient);
        }
        _isLoading = false;
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
          NotificationService().syncDeviceToken(_apiClient);
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

  Future<ApiResponse> updateProfile({required String name, required String phone}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final payload = {
        'name': name.trim(),
        'phone': phone.trim(),
      };

      var response = await _apiClient.post('/user/profile/update', data: payload);
      if (!response.status) {
        response = await _apiClient.post('/user/profile', data: payload);
      }
      if (!response.status) {
        response = await _apiClient.post('/auth/profile', data: payload);
      }

      if (response.status) {
        await fetchProfile();
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse(status: false, message: 'Failed to update profile.');
    }
  }

  Future<ApiResponse> updateAvatar(String avatarPathOrUrl) async {
    _isLoading = true;
    notifyListeners();

    try {
      // If it's a URL or base64
      var response = await _apiClient.post('/user/avatar', data: {'avatar': avatarPathOrUrl});
      if (!response.status) {
        response = await _apiClient.post('/user/profile/avatar', data: {'avatar': avatarPathOrUrl});
      }

      if (response.status) {
        await fetchProfile();
      } else if (_user != null) {
        // Fallback local update so UI reflects immediately
        _user = UserModel(
          id: _user!.id,
          name: _user!.name,
          username: _user!.username,
          email: _user!.email,
          phone: _user!.phone,
          userType: _user!.userType,
          isActive: _user!.isActive,
          referralCode: _user!.referralCode,
          kycStatus: _user!.kycStatus,
          avatar: avatarPathOrUrl,
          bankName: _user!.bankName,
          bankAccountNumber: _user!.bankAccountNumber,
          bankAccountName: _user!.bankAccountName,
          wallet: _user!.wallet,
        );
        await _storage.saveUserData(_user!.toJson());
        response = ApiResponse(status: true, message: 'Profile photo updated successfully!');
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse(status: false, message: 'Failed to upload photo.');
    }
  }

  Future<ApiResponse> updateBankDetails({
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final payload = {
        'bank_name': bankName.trim(),
        'bank_account_number': accountNumber.trim(),
        'bank_account_name': accountName.trim(),
      };

      // ApiClient get / post / put
      var response = await _apiClient.post('/user/bank', data: payload);
      if (!response.status) {
        response = await _apiClient.post('/user/account/bank', data: payload);
      }

      if (response.status) {
        await fetchProfile();
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse(status: false, message: 'Failed to update bank details.');
    }
  }

  Future<ApiResponse> upgradeToAgent({required String pin}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final payload = {
        'pin': pin.trim(),
      };

      final response = await _apiClient.post('/user/upgrade-agent', data: payload);

      if (response.status) {
        await fetchProfile();
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse(status: false, message: 'Failed to upgrade account to agent tier.');
    }
  }

  Future<ApiResponse> submitKyc({
    required String bvn,
    String? nin,
    String? dob,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        'bvn': bvn.trim(),
        if (nin != null && nin.isNotEmpty) 'nin': nin.trim(),
        if (dob != null && dob.isNotEmpty) 'dob': dob.trim(),
      };

      var response = await _apiClient.post('/user/kyc/submit', data: payload);
      if (!response.status) {
        response = await _apiClient.post('/user/kyc', data: payload);
      }
      if (!response.status) {
        response = await _apiClient.post('/user/dva/generate', data: {'bvn': bvn.trim()});
      }

      if (response.status) {
        await fetchProfile();
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse(status: false, message: 'KYC submission failed. Please check your BVN/NIN details.');
    }
  }

  Future<void> fetchProfile() async {
    try {
      var response = await _apiClient.get('/auth/me');
      if (!response.status || response.data == null) {
        response = await _apiClient.get('/user/profile');
      }
      if (response.status && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          final rawData = response.data as Map<String, dynamic>;
          _user = UserModel.fromJson(rawData);
          await _storage.saveUserData(_user!.toJson());
          NotificationService().syncDeviceToken(_apiClient);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  Future<ApiResponse> deleteAccount({required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      var response = await _apiClient.delete('/user/account', data: {'password': password});
      if (!response.status) {
        response = await _apiClient.post('/user/account/delete', data: {'password': password});
      }
      if (!response.status) {
        response = await _apiClient.post('/auth/delete-account', data: {'password': password});
      }

      if (response.status) {
        await logout();
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse(status: false, message: 'Failed to delete account. Please try again.');
    }
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

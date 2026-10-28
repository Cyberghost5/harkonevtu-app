import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:local_auth/local_auth.dart';
import '../core/api/api_client.dart';
import '../core/services/notification_service.dart';
import '../core/services/google_auth_service.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

class LoginResult {
  final bool success;
  final bool requiresVerification;
  final bool isNewUser;
  final String? email;
  final String message;

  LoginResult({
    required this.success,
    this.requiresVerification = false,
    this.isNewUser = false,
    this.email,
    required this.message,
  });
}

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
  bool get isProfileComplete => _user != null && _user!.isProfileComplete;
  bool get needsPhone => _user == null || _user!.needsPhone;
  bool get needsPin => _user == null || _user!.needsPin;

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

  /// Authenticate purely for authorizing a transaction with biometrics (no login side-effects).
  Future<bool> authenticateForTransaction({String reason = 'Authorize transaction with Biometrics'}) async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck && !isSupported) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> enableBiometricsWithVerification() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck && !isSupported) return false;

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to activate Biometric Quick Login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        _isBiometricEnabled = true;
        await _storage.setBiometricsEnabled(true);
        notifyListeners();
        return true;
      } else {
        _isBiometricEnabled = false;
        await _storage.setBiometricsEnabled(false);
        notifyListeners();
        return false;
      }
    } catch (_) {
      _isBiometricEnabled = false;
      await _storage.setBiometricsEnabled(false);
      notifyListeners();
      return false;
    }
  }

  Future<void> disableBiometrics() async {
    _isBiometricEnabled = false;
    await _storage.setBiometricsEnabled(false);
    await _storage.clearBiometricCredentials();
    notifyListeners();
  }

  Future<void> toggleBiometrics(bool enable) async {
    if (enable) {
      await enableBiometricsWithVerification();
    } else {
      await disableBiometrics();
    }
  }


  Future<LoginResult> loginDetailed(String loginInput, String password) async {
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
        return LoginResult(success: true, message: response.message);
      } else {
        _errorMessage = response.message.isNotEmpty ? response.message : 'Login failed.';
        
        final resData = response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : <String, dynamic>{};
        final errorsData = response.errors ?? <String, dynamic>{};
        final msgLower = response.message.toLowerCase();

        final isUnverified = resData['requires_verification'] == true ||
            resData['email_verified'] == false ||
            resData['is_verified'] == false ||
            errorsData['requires_verification'] == true ||
            errorsData['email_verified'] == false ||
            msgLower.contains('unverified') ||
            msgLower.contains('verify') ||
            msgLower.contains('verification') ||
            msgLower.contains('otp');

        if (isUnverified) {
          String? email = resData['email']?.toString();
          email ??= resData['user']?['email']?.toString();
          if (email == null || email.isEmpty) {
            if (loginInput.contains('@')) {
              email = loginInput;
            }
          }

          _isLoading = false;
          notifyListeners();
          return LoginResult(
            success: false,
            requiresVerification: true,
            email: email ?? loginInput,
            message: _errorMessage!,
          );
        }

        _isLoading = false;
        notifyListeners();
        return LoginResult(success: false, message: _errorMessage!);
      }
    } catch (e) {
      _errorMessage = 'An error occurred during login.';
      _isLoading = false;
      notifyListeners();
      return LoginResult(success: false, message: _errorMessage!);
    }
  }

  Future<bool> login(String loginInput, String password) async {
    final result = await loginDetailed(loginInput, password);
    return result.success;
  }

  /// Authenticate or register using Google Sign-In.
  Future<LoginResult> signInWithGoogle({String? serverClientId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final googleResult = await GoogleAuthService().signIn(serverClientId: serverClientId);

      if (googleResult == null) {
        _isLoading = false;
        notifyListeners();
        return LoginResult(
          success: false,
          message: 'Google Sign-In cancelled.',
        );
      }

      final payload = <String, dynamic>{
        'device_name': 'mobile_app',
        if (googleResult.idToken.isNotEmpty) 'id_token': googleResult.idToken,
        if (googleResult.accessToken != null && googleResult.accessToken!.isNotEmpty)
          'access_token': googleResult.accessToken,
        if (googleResult.email != null && googleResult.email!.isNotEmpty)
          'email': googleResult.email,
        if (googleResult.id != null && googleResult.id!.isNotEmpty)
          'google_id': googleResult.id,
        if (googleResult.displayName != null && googleResult.displayName!.isNotEmpty)
          'name': googleResult.displayName,
      };

      final response = await _apiClient.post('/auth/google', data: payload);

      if (response.status) {
        if (response.data != null && response.data is Map<String, dynamic>) {
          final resData = response.data as Map<String, dynamic>;
          final token = resData['token'] ?? resData['access_token'] ?? resData['user']?['token'];
          if (token != null && token.toString().isNotEmpty) {
            _token = token.toString();
            await _storage.saveToken(_token!);
          }

          if (resData['user'] != null && resData['user'] is Map<String, dynamic>) {
            final userMap = Map<String, dynamic>.from(resData['user'] as Map<String, dynamic>);
            if (resData.containsKey('is_pin_set')) {
              userMap['is_pin_set'] = resData['is_pin_set'];
            }
            if (resData.containsKey('is_phone_set')) {
              userMap['is_phone_set'] = resData['is_phone_set'];
            }
            if (resData.containsKey('requires_pin_setup')) {
              userMap['requires_pin_setup'] = resData['requires_pin_setup'];
            }
            _user = UserModel.fromJson(userMap);
            await _storage.saveUserData(_user!.toJson());
          }

          if (_token != null && _token!.isNotEmpty) {
            NotificationService().syncDeviceToken(_apiClient);
            await fetchProfile();
          }
        }

        final isNewUser = (resData['is_new_user'] == true);
        _isLoading = false;
        notifyListeners();
        return LoginResult(
          success: true,
          isNewUser: isNewUser,
          message: response.message.isNotEmpty
              ? response.message
              : 'Google authentication successful.',
        );
      } else {
        _errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Google authentication failed.';
        _isLoading = false;
        notifyListeners();
        return LoginResult(success: false, message: _errorMessage!);
      }
    } catch (e, stack) {
      debugPrint('[Google Sign-In Error] $e\n$stack');
      String msg = 'An error occurred during Google Sign-In.';

      if (e is PlatformException) {
        final code = e.code;
        final rawMsg = e.message ?? '';
        final details = e.details?.toString() ?? '';

        if (code == 'sign_in_failed' || rawMsg.contains('10') || details.contains('10')) {
          msg = 'Google Sign-In configuration error (ApiException: 10). Please verify that the app SHA-1 fingerprint is added in Firebase/Google Cloud Console.';
        } else if (code == 'network_error' || rawMsg.contains('7') || details.contains('7')) {
          msg = 'Network connection error during Google Sign-In. Please check your internet connection.';
        } else if (code == 'sign_in_canceled') {
          msg = 'Google Sign-In cancelled.';
        } else if (rawMsg.isNotEmpty) {
          msg = 'Google Sign-In failed: $rawMsg';
        } else {
          msg = 'Google Sign-In failed ($code).';
        }
      } else if (e.toString().isNotEmpty) {
        msg = e.toString().replaceFirst('Exception: ', '');
      }

      _errorMessage = msg;
      _isLoading = false;
      notifyListeners();
      return LoginResult(success: false, message: _errorMessage!);
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
        if (response.data != null && response.data is Map<String, dynamic>) {
          final resData = response.data as Map<String, dynamic>;
          final token = resData['token'] ?? resData['access_token'] ?? resData['user']?['token'];
          if (token != null && token.toString().isNotEmpty) {
            _token = token.toString();
            await _storage.saveToken(_token!);
          }
          if (resData['user'] != null && resData['user'] is Map<String, dynamic>) {
            _user = UserModel.fromJson(resData['user'] as Map<String, dynamic>);
            await _storage.saveUserData(_user!.toJson());
          }
          if (_token != null && _token!.isNotEmpty) {
            NotificationService().syncDeviceToken(_apiClient);
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
        if (response.data != null) {
          final resData = response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : <String, dynamic>{};
          final token = resData['token'] ?? resData['access_token'] ?? resData['user']?['token'];
          if (token != null && token.toString().isNotEmpty) {
            _token = token.toString();
            await _storage.saveToken(_token!);
          }
          if (resData['user'] != null && resData['user'] is Map<String, dynamic>) {
            _user = UserModel.fromJson(resData['user'] as Map<String, dynamic>);
            await _storage.saveUserData(_user!.toJson());
          }
        }

        if (_token == null || _token!.isEmpty) {
          _token = await _storage.getToken();
        }

        if (_token != null && _token!.isNotEmpty) {
          NotificationService().syncDeviceToken(_apiClient);
          await fetchProfile();
        }

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

  Future<ApiResponse> updateProfile({
    required String name,
    required String phone,
    String? email,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final payload = {
        'name': name.trim(),
        'email': (email ?? _user?.email ?? '').trim(),
        'phone': phone.trim(),
      };

      var response = await _apiClient.put('/user/profile', data: payload);
      if (!response.status) {
        response = await _apiClient.post('/user/profile', data: payload);
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

  Future<ApiResponse> completeProfile({
    String? phone,
    String? pin,
    String? confirmPin,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (pin != null && pin.trim().isNotEmpty) ...{
          'pin': pin.trim(),
          'pin_confirmation': (confirmPin ?? pin).trim(),
        },
      };

      // 1. Try unified /auth/complete-profile endpoint first
      var response = await _apiClient.post('/auth/complete-profile', data: payload);

      if (!response.status) {
        // Fallback: update phone then update PIN via user endpoints
        if (phone != null && phone.trim().isNotEmpty) {
          final profileRes = await updateProfile(
            name: _user?.name ?? '',
            phone: phone.trim(),
            email: _user?.email,
          );
          if (!profileRes.status) {
            _isLoading = false;
            _errorMessage = profileRes.message;
            notifyListeners();
            return profileRes;
          }
        }

        if (pin != null && pin.trim().isNotEmpty) {
          final pinRes = await updatePin(
            newPin: pin.trim(),
            confirmPin: (confirmPin ?? pin).trim(),
          );
          if (!pinRes.status) {
            _isLoading = false;
            _errorMessage = pinRes.message;
            notifyListeners();
            return pinRes;
          }
        }
      }

      if (pin != null && pin.trim().isNotEmpty) {
        await _storage.savePin(pin.trim());
      }

      await fetchProfile();
      _isLoading = false;
      notifyListeners();
      return ApiResponse(status: true, message: 'Profile completed successfully.');
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return ApiResponse(status: false, message: 'Failed to complete profile.');
    }
  }

  Future<ApiResponse> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final payload = {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      };

      var response = await _apiClient.put('/user/password', data: payload);
      if (!response.status) {
        response = await _apiClient.post('/user/password', data: payload);
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse(status: false, message: 'Failed to update password.');
    }
  }

  Future<ApiResponse> updatePin({
    String? currentPin,
    required String newPin,
    required String confirmPin,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final payload = {
        if (currentPin != null && currentPin.isNotEmpty) 'current_pin': currentPin,
        'pin': newPin,
        'pin_confirmation': confirmPin,
      };

      var response = await _apiClient.put('/user/pin', data: payload);
      if (!response.status) {
        response = await _apiClient.post('/user/pin', data: payload);
      }

      if (response.status) {
        await _storage.savePin(newPin);
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse(status: false, message: 'Failed to update transaction PIN.');
    }
  }

  Future<ApiResponse> verifyPin({required String pin}) async {
    try {
      final payload = {'pin': pin.trim()};
      final response = await _apiClient.post('/user/pin/verify', data: payload);
      return response;
    } catch (e) {
      return ApiResponse(status: false, message: 'PIN verification failed.');
    }
  }

  Future<ApiResponse> updateAvatar(String avatarPathOrUrl) async {
    _isLoading = true;
    notifyListeners();

    try {
      ApiResponse response;
      final isLocalFile = !avatarPathOrUrl.startsWith('http://') && !avatarPathOrUrl.startsWith('https://');

      if (isLocalFile) {
        final fileName = avatarPathOrUrl.split('/').last.split('\\').last;
        final formData = FormData.fromMap({
          'avatar': await MultipartFile.fromFile(
            avatarPathOrUrl,
            filename: fileName,
          ),
          if (_user?.name != null && _user!.name.isNotEmpty) 'name': _user!.name,
        });

        // POST /user/profile as specified in API documentation (curl -F "avatar=@file" -F "name=John")
        response = await _apiClient.post('/user/profile', data: formData);
        if (!response.status) {
          response = await _apiClient.post('/user/profile/update', data: formData);
        }
        if (!response.status) {
          response = await _apiClient.post('/user/avatar', data: formData);
        }
      } else {
        response = await _apiClient.post('/user/profile', data: {
          'avatar': avatarPathOrUrl,
          if (_user?.name != null && _user!.name.isNotEmpty) 'name': _user!.name,
        });
        if (!response.status) {
          response = await _apiClient.post('/user/avatar', data: {'avatar': avatarPathOrUrl});
        }
      }

      if (response.status) {
        String? newAvatarUrl;
        if (response.data != null) {
          if (response.data is String) {
            newAvatarUrl = response.data as String;
          } else if (response.data is Map<String, dynamic>) {
            final map = response.data as Map<String, dynamic>;
            final userMap = map['user'] is Map<String, dynamic>
                ? map['user'] as Map<String, dynamic>
                : (map['data'] is Map<String, dynamic> ? map['data'] as Map<String, dynamic> : map);

            newAvatarUrl = userMap['avatar']?.toString() ??
                userMap['avatar_url']?.toString() ??
                userMap['profile_photo_url']?.toString() ??
                userMap['profile_picture']?.toString();

            try {
              _user = UserModel.fromJson(userMap);
              await _storage.saveUserData(_user!.toJson());
            } catch (_) {}
          }
        }

        await fetchProfile();

        if (newAvatarUrl != null && newAvatarUrl.isNotEmpty && _user != null) {
          if (_user!.avatar == null || !_user!.avatar!.startsWith('http')) {
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
              avatar: newAvatarUrl,
              bankName: _user!.bankName,
              bankAccountNumber: _user!.bankAccountNumber,
              bankAccountName: _user!.bankAccountName,
              wallet: _user!.wallet,
            );
            await _storage.saveUserData(_user!.toJson());
          }
        }
      } else if (_user != null) {
        // Fallback local update if backend error occurs
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

      var response = await _apiClient.put('/user/bank', data: payload);
      if (!response.status) {
        response = await _apiClient.post('/user/bank', data: payload);
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
        'transaction_pin': pin.trim(),
        'confirm_upgrade': true,
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
    String idType = 'bvn',
    String idNumber = '',
    String? bvn,
    String? nin,
    String? dob,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final effectiveType = idNumber.isNotEmpty
          ? idType.trim().toLowerCase()
          : (bvn != null && bvn.trim().isNotEmpty ? 'bvn' : 'nin');
      final effectiveNumber = idNumber.isNotEmpty
          ? idNumber.trim()
          : (effectiveType == 'bvn' ? (bvn ?? '').trim() : (nin ?? '').trim());

      final payload = <String, dynamic>{
        'id_type': effectiveType,
        'id_number': effectiveNumber,
        if (effectiveType == 'bvn') 'bvn': effectiveNumber,
        if (effectiveType == 'nin') 'nin': effectiveNumber,
      };

      final response = await _apiClient.post('/kyc/submit', data: payload);

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

  Future<ApiResponse> fetchKycStatus() async {
    try {
      final response = await _apiClient.get('/kyc/status');
      if (response.status && response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['kyc_status'] != null && _user != null) {
          final userMap = _user!.toJson();
          userMap['kyc_status'] = data['kyc_status'];
          _user = UserModel.fromJson(userMap);
          await _storage.saveUserData(_user!.toJson());
          notifyListeners();
        }
      }
      return response;
    } catch (e) {
      return ApiResponse(status: false, message: 'Failed to fetch KYC status.');
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
    try {
      await GoogleAuthService().signOut();
    } catch (_) {}
    _token = null;
    _user = null;
    await _storage.clearSession();
    notifyListeners();
  }
}

import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../api/api_constants.dart';

class GoogleAuthResult {
  final String idToken;
  final String? accessToken;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? id;

  GoogleAuthResult({
    required this.idToken,
    this.accessToken,
    this.email,
    this.displayName,
    this.photoUrl,
    this.id,
  });
}

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  GoogleSignIn _buildGoogleSignIn({String? serverClientId}) {
    final effectiveServerClientId = (serverClientId != null && serverClientId.trim().isNotEmpty)
        ? serverClientId.trim()
        : (ApiConstants.googleServerClientId.trim().isNotEmpty ? ApiConstants.googleServerClientId.trim() : null);

    return GoogleSignIn(
      scopes: const <String>[
        'email',
        'profile',
      ],
      serverClientId: effectiveServerClientId,
    );
  }

  /// Performs Google Sign-In on the device.
  /// Returns [GoogleAuthResult] containing id_token and profile details,
  /// or null if the user cancels the sign-in modal.
  Future<GoogleAuthResult?> signIn({String? serverClientId}) async {
    final cleanServerClientId = (serverClientId != null && serverClientId.trim().isNotEmpty)
        ? serverClientId.trim()
        : (ApiConstants.googleServerClientId.trim().isNotEmpty ? ApiConstants.googleServerClientId.trim() : null);

    try {
      return await _performSignIn(serverClientId: cleanServerClientId);
    } on PlatformException catch (e) {
      developer.log('Google Sign-In PlatformException: code=${e.code}, msg=${e.message}, details=${e.details}');
      // If sign-in failed with a serverClientId configuration mismatch (e.g. ApiException 10 or sign_in_failed)
      // and a serverClientId was provided, retry gracefully without serverClientId so the user can still
      // select their Google account and authenticate.
      if (cleanServerClientId != null &&
          (e.code == 'sign_in_failed' ||
              (e.message != null && (e.message!.contains('10') || e.message!.contains('12500'))))) {
        developer.log('Retrying Google Sign-In with standard client fallback (without serverClientId)...');
        try {
          return await _performSignIn(serverClientId: null);
        } catch (fallbackError) {
          developer.log('Fallback Google Sign-In also failed: $fallbackError');
          rethrow;
        }
      }
      rethrow;
    } catch (e, stack) {
      developer.log('Google Sign-In error: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<GoogleAuthResult?> _performSignIn({String? serverClientId}) async {
    final GoogleSignIn googleSignIn = _buildGoogleSignIn(serverClientId: serverClientId);

    // Clear previous cached session if needed so the user can choose account
    try {
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (_) {}

    final GoogleSignInAccount? account = await googleSignIn.signIn();
    if (account == null) {
      developer.log('Google Sign-In was cancelled by the user.');
      return null;
    }

    GoogleSignInAuthentication? auth;
    try {
      auth = await account.authentication;
    } catch (authError) {
      developer.log('Google account.authentication notice: $authError');
    }

    return GoogleAuthResult(
      idToken: auth?.idToken ?? '',
      accessToken: auth?.accessToken,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
      id: account.id,
    );
  }

  /// Signs out from Google on the device.
  Future<void> signOut() async {
    try {
      final googleSignIn = _buildGoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}
  }
}

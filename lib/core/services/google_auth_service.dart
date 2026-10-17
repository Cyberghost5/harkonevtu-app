import 'dart:developer' as developer;
import 'package:google_sign_in/google_sign_in.dart';

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
    return GoogleSignIn(
      scopes: const <String>[
        'email',
        'profile',
      ],
      serverClientId: (serverClientId != null && serverClientId.trim().isNotEmpty)
          ? serverClientId.trim()
          : null,
    );
  }

  /// Performs Google Sign-In on the device.
  /// Returns [GoogleAuthResult] containing id_token and profile details,
  /// or null if the user cancels the sign-in modal.
  Future<GoogleAuthResult?> signIn({String? serverClientId}) async {
    try {
      final GoogleSignIn googleSignIn = _buildGoogleSignIn(serverClientId: serverClientId);

      // Clear previous cached session if needed so the user can choose account
      if (await googleSignIn.isSignedIn()) {
        try {
          await googleSignIn.signOut();
        } catch (_) {}
      }

      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        developer.log('Google Sign-In was cancelled by the user.');
        return null;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      return GoogleAuthResult(
        idToken: idToken ?? '',
        accessToken: auth.accessToken,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        id: account.id,
      );
    } catch (e, stack) {
      developer.log('Google Sign-In error: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Signs out from Google on the device.
  Future<void> signOut() async {
    try {
      final googleSignIn = _buildGoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}
  }
}

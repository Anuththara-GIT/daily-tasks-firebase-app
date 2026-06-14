import 'package:firebase_auth/firebase_auth.dart';

class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageForSignInError(error));
    } catch (error) {
      throw AuthServiceException(
        _fallbackErrorMessage(
          'Could not sign in right now. Please try again.',
          error,
        ),
      );
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final displayName = name.trim();
      if (displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
      }
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageForSignUpError(error));
    } catch (error) {
      throw AuthServiceException(
        _fallbackErrorMessage(
          'Could not create your account right now. Please try again.',
          error,
        ),
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        _readFirebaseMessage(
          error,
          fallback: 'Could not log out right now. Please try again.',
        ),
      );
    } catch (error) {
      throw AuthServiceException(
        _fallbackErrorMessage(
          'Could not log out right now. Please try again.',
          error,
        ),
      );
    }
  }

  String _messageForSignInError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'wrong-password':
        return 'Email or password is incorrect.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a bit and try again.';
      case 'network-request-failed':
        return 'Network issue detected. Check your internet connection.';
      case 'operation-not-allowed':
      case 'configuration-not-found':
        return 'Enable Email/Password sign-in in Firebase Authentication first.';
      case 'unauthorized-domain':
        return 'This domain is not authorized in Firebase Authentication. Add localhost or your app domain in Authorized domains.';
      default:
        return _readFirebaseMessage(
          error,
          fallback: 'Could not sign in right now.',
        );
    }
  }

  String _messageForSignUpError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'That email is already being used.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'weak-password':
        return 'Use a stronger password with at least 6 characters.';
      case 'operation-not-allowed':
      case 'configuration-not-found':
        return 'Enable Email/Password sign-in in Firebase Authentication.';
      case 'unauthorized-domain':
        return 'This domain is not authorized in Firebase Authentication. Add localhost or your app domain in Authorized domains.';
      case 'network-request-failed':
        return 'Network issue detected. Check your internet connection.';
      default:
        return _readFirebaseMessage(
          error,
          fallback: 'Could not create your account right now.',
        );
    }
  }

  String _readFirebaseMessage(
    FirebaseAuthException error, {
    required String fallback,
  }) {
    final message = error.message?.trim();
    if (message != null &&
        message.isNotEmpty &&
        message.toLowerCase() != 'error') {
      return message;
    }

    if (error.code.isNotEmpty) {
      return 'Firebase auth error: ${error.code}.';
    }

    return fallback;
  }

  String _fallbackErrorMessage(String fallback, Object error) {
    final raw = error.toString().trim();
    if (raw.isEmpty || raw == 'Error') {
      return fallback;
    }

    return '$fallback Details: $raw';
  }
}

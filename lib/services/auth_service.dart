import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn? _googleSignIn;

  AuthService() {
    // Google Sign-In nie działa dobrze na Web bez dodatkowej konfiguracji
    // Inicjalizujemy tylko dla platform mobilnych
    _googleSignIn = kIsWeb ? null : GoogleSignIn();
  }

  // Stream do śledzenia stanu zalogowania
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Aktualnie zalogowany użytkownik
  User? get currentUser => _auth.currentUser;

  // Logowanie email/hasło
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Rejestracja email/hasło
  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Logowanie przez Google
  Future<UserCredential?> signInWithGoogle() async {
    // Google Sign-In nie jest dostępny na Web bez dodatkowej konfiguracji
    if (kIsWeb || _googleSignIn == null) {
      throw 'Logowanie przez Google nie jest dostępne na tej platformie. Użyj email/hasło.';
    }

    try {
      // Rozpocznij proces logowania Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // Użytkownik anulował logowanie
        return null;
      }

      // Pobierz dane uwierzytelniające
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Stwórz credential dla Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Zaloguj do Firebase
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw 'Błąd logowania przez Google: $e';
    }
  }

  // Resetowanie hasła
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Wylogowanie
  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleSignIn != null) {
      await _googleSignIn.signOut();
    }
  }

  // Obsługa błędów Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Nie znaleziono użytkownika z podanym emailem.';
      case 'wrong-password':
        return 'Nieprawidłowe hasło.';
      case 'email-already-in-use':
        return 'Ten email jest już używany.';
      case 'weak-password':
        return 'Hasło jest zbyt słabe.';
      case 'invalid-email':
        return 'Nieprawidłowy adres email.';
      case 'user-disabled':
        return 'To konto zostało wyłączone.';
      case 'too-many-requests':
        return 'Zbyt wiele prób. Spróbuj ponownie później.';
      case 'operation-not-allowed':
        return 'Ta operacja nie jest dozwolona.';
      default:
        return 'Wystąpił błąd: ${e.message}';
    }
  }
}

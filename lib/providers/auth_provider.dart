import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/foundation.dart';

/// Provider untuk mengelola state autentikasi pengguna menggunakan Firebase Authentication.
class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<User?>? _authSubscription;

  AuthProvider({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    _user = _auth.currentUser;
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      _user = user;
      _errorMessage = null;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Masuk dengan email dan password.
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage =
          'Terjadi kesalahan tidak terduga saat masuk. Silakan coba lagi.';
      _setLoading(false);
      return false;
    }
  }

  /// Pendaftaran akun baru dengan email dan password.
  Future<bool> register(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage =
          'Terjadi kesalahan tidak terduga saat pendaftaran. Silakan coba lagi.';
      _setLoading(false);
      return false;
    }
  }

  /// Keluar dari sesi akun saat ini.
  Future<void> logout() async {
    _setLoading(true);
    notifyListeners();

    try {
      await _auth.signOut();
    } catch (e) {
      _errorMessage = 'Gagal keluar dari sesi. Silakan coba lagi.';
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }

  /// Memetakan error code Firebase ke pesan yang ramah pengguna.
  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Akun dengan email tersebut tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah. Periksa kembali password Anda.';
      case 'invalid-credential':
        return 'Email atau password tidak sesuai.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan masuk atau gunakan email lain.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan oleh administrator.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan gagal. Silakan tunggu beberapa saat.';
      case 'network-request-failed':
        return 'Koneksi jaringan bermasalah. Periksa koneksi internet Anda.';
      case 'operation-not-allowed':
        return 'Metode pendaftaran email/password belum diaktifkan di Firebase Console.';
      default:
        return e.message ??
            'Terjadi kesalahan pada layanan autentikasi (${e.code}).';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

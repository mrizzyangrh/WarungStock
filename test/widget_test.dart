import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:warung_stock/main.dart';
import 'package:warung_stock/providers/auth_provider.dart';
import 'package:warung_stock/screens/auth/login_screen.dart';
import 'package:warung_stock/screens/auth/register_screen.dart';
import 'package:warung_stock/screens/home_screen.dart';

/// Fake AuthProvider untuk keperluan testing tanpa ketergantungan Firebase sungguhan.
class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  User? _fakeUser;
  bool _fakeLoading = false;
  String? _fakeError;
  final StreamController<User?> _streamController =
      StreamController<User?>.broadcast();

  FakeAuthProvider({
    User? initialUser,
    bool isLoading = false,
    String? errorMessage,
  }) : _fakeUser = initialUser,
       _fakeLoading = isLoading,
       _fakeError = errorMessage;

  @override
  User? get user => _fakeUser;

  @override
  bool get isAuthenticated => _fakeUser != null;

  @override
  bool get isLoading => _fakeLoading;

  @override
  String? get errorMessage => _fakeError;

  @override
  Stream<User?> get authStateChanges => _streamController.stream;

  void setUser(User? user) {
    _fakeUser = user;
    _streamController.add(user);
    notifyListeners();
  }

  void setLoading(bool loading) {
    _fakeLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _fakeError = error;
    notifyListeners();
  }

  @override
  void clearError() {
    _fakeError = null;
    notifyListeners();
  }

  @override
  Future<bool> login(String email, String password) async {
    return true;
  }

  @override
  Future<bool> register(String email, String password) async {
    return true;
  }

  @override
  Future<void> logout() async {
    _fakeUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }
}

Widget createTestableWidget({
  required Widget child,
  required AuthProvider authProvider,
}) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: authProvider,
    child: MaterialApp(home: child),
  );
}

void main() {
  group('WarungStock Auth & Navigation Tests', () {
    testWidgets(
      'AuthGate menampilkan pesan error saat inisialisasi Firebase gagal',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const WarungStockApp(
            firebaseInitialized: false,
            initErrorMessage: 'Koneksi gagal',
          ),
        );

        expect(find.text('Inisialisasi Firebase Gagal'), findsOneWidget);
        expect(find.text('Koneksi gagal'), findsOneWidget);
      },
    );

    testWidgets(
      'AuthGate menampilkan LoginScreen ketika pengguna belum login',
      (WidgetTester tester) async {
        final fakeAuth = FakeAuthProvider(initialUser: null);

        await tester.pumpWidget(
          createTestableWidget(
            authProvider: fakeAuth,
            child: const AuthGate(firebaseInitialized: true),
          ),
        );

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text('WarungStock'), findsOneWidget);
        expect(find.text('Masuk ke Akun Inventaris Warung'), findsOneWidget);
      },
    );

    testWidgets(
      'AuthGate menampilkan HomeScreen ketika pengguna terautentikasi',
      (WidgetTester tester) async {
        final fakeAuth = FakeAuthProvider();
        fakeAuth.setUser(null);

        await tester.pumpWidget(
          createTestableWidget(
            authProvider: fakeAuth,
            child: const AuthGate(firebaseInitialized: true),
          ),
        );
        expect(find.byType(LoginScreen), findsOneWidget);

        // Ubah status ke terautentikasi
        fakeAuth.setUser(_createMockUser('warung@example.com'));
        await tester.pump();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('Dashboard Inventaris Warung'), findsOneWidget);
        expect(find.text('warung@example.com'), findsWidgets);
      },
    );

    testWidgets(
      'LoginScreen memvalidasi input kosong dan format email yang salah',
      (WidgetTester tester) async {
        final fakeAuth = FakeAuthProvider();

        await tester.pumpWidget(
          createTestableWidget(
            authProvider: fakeAuth,
            child: const LoginScreen(),
          ),
        );

        // Tekan tombol masuk tanpa mengisi form
        await tester.tap(find.byKey(const Key('login_submit_button')));
        await tester.pump();

        expect(find.text('Email tidak boleh kosong'), findsOneWidget);
        expect(find.text('Password tidak boleh kosong'), findsOneWidget);

        // Isi email format salah
        await tester.enterText(
          find.byKey(const Key('login_email_field')),
          'email_salah_format',
        );
        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          '123',
        );
        await tester.tap(find.byKey(const Key('login_submit_button')));
        await tester.pump();

        expect(find.text('Format email tidak valid'), findsOneWidget);
        expect(find.text('Password minimal 6 karakter'), findsOneWidget);
      },
    );

    testWidgets('RegisterScreen memvalidasi kecocokan konfirmasi password', (
      WidgetTester tester,
    ) async {
      final fakeAuth = FakeAuthProvider();

      await tester.pumpWidget(
        createTestableWidget(
          authProvider: fakeAuth,
          child: const RegisterScreen(),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('register_email_field')),
        'pemilik@warung.com',
      );
      await tester.enterText(
        find.byKey(const Key('register_password_field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('register_confirm_password_field')),
        'passwordBerbeda',
      );

      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pump();

      expect(find.text('Password konfirmasi tidak cocok'), findsOneWidget);
    });

    testWidgets('Tombol dinonaktifkan saat AuthProvider dalam state loading', (
      WidgetTester tester,
    ) async {
      final fakeAuth = FakeAuthProvider(isLoading: true);

      await tester.pumpWidget(
        createTestableWidget(
          authProvider: fakeAuth,
          child: const LoginScreen(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('login_submit_button')),
      );
      expect(button.onPressed, isNull);
    });
  });
}

/// Helper untuk membuat mock User minimal untuk UI test.
User _createMockUser(String email) {
  return _SimpleMockUser(email);
}

class _SimpleMockUser implements User {
  @override
  final String email;

  _SimpleMockUser(this.email);

  @override
  String get uid => 'mock_uid_123';

  @override
  String? get displayName => 'Owner Warung';

  @override
  bool get emailVerified => true;

  @override
  bool get isAnonymous => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

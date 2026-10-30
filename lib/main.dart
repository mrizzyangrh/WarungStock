import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/item_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInitialized = false;
  String? initErrorMessage;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
  } catch (e) {
    initErrorMessage =
        'Gagal menginisialisasi layanan Firebase. Periksa koneksi internet atau konfigurasi project Anda.';
  }

  runApp(
    WarungStockApp(
      firebaseInitialized: firebaseInitialized,
      initErrorMessage: initErrorMessage,
    ),
  );
}

class WarungStockApp extends StatelessWidget {
  final bool firebaseInitialized;
  final String? initErrorMessage;
  final AuthProvider? authProvider;
  final ItemProvider? itemProvider;

  const WarungStockApp({
    super.key,
    this.firebaseInitialized = true,
    this.initErrorMessage,
    this.authProvider,
    this.itemProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => authProvider ?? AuthProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ItemProvider>(
          create: (_) => itemProvider ?? ItemProvider(),
          update: (_, auth, item) {
            final provider = item ?? itemProvider ?? ItemProvider();
            // Menghubungkan sesi autentikasi pengguna ke isolasi inventaris Firestore
            provider.updateUser(auth.user?.uid);
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'WarungStock',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.light,
          ),
          cardTheme: const CardThemeData(elevation: 2),
        ),
        home: AuthGate(
          firebaseInitialized: firebaseInitialized,
          initErrorMessage: initErrorMessage,
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  final bool firebaseInitialized;
  final String? initErrorMessage;

  const AuthGate({
    super.key,
    required this.firebaseInitialized,
    this.initErrorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (!firebaseInitialized) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Inisialisasi Firebase Gagal',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        initErrorMessage ??
                            'Tidak dapat menghubungkan aplikasi ke Firebase. Silakan muat ulang halaman.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final authProvider = context.watch<AuthProvider>();

    // Memantau state autentikasi sebagai sumber kebenaran sesi
    if (authProvider.isAuthenticated) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}

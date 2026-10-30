import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:warung_stock/main.dart';
import 'package:warung_stock/models/item_model.dart';
import 'package:warung_stock/providers/auth_provider.dart';
import 'package:warung_stock/providers/item_provider.dart';
import 'package:warung_stock/providers/api_provider.dart';
import 'package:warung_stock/screens/auth/login_screen.dart';
import 'package:warung_stock/screens/auth/register_screen.dart';
import 'package:warung_stock/screens/home_screen.dart';
import 'package:warung_stock/screens/products/product_list_screen.dart';

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

/// Fake ItemProvider untuk keperluan testing inventaris tanpa backend Firestore sungguhan.
class FakeItemProvider extends ChangeNotifier implements ItemProvider {
  List<ItemModel> _fakeItems = [];
  ItemViewState _fakeState = ItemViewState.initial;
  String? _fakeErrorMessage;
  // ignore: prefer_final_fields
  bool _fakeActionLoading = false;

  FakeItemProvider({
    List<ItemModel>? initialItems,
    ItemViewState initialState = ItemViewState.initial,
    bool isActionLoading = false,
  }) : _fakeItems = initialItems ?? [],
       _fakeState = initialState,
       _fakeActionLoading = isActionLoading;

  @override
  List<ItemModel> get items => List.unmodifiable(_fakeItems);

  @override
  ItemViewState get state => _fakeState;

  @override
  String? get errorMessage => _fakeErrorMessage;

  @override
  bool get isActionLoading => _fakeActionLoading;

  @override
  bool get isLoading => _fakeState == ItemViewState.loading;

  @override
  bool get isEmpty => _fakeState == ItemViewState.empty;

  @override
  bool get isLoaded => _fakeState == ItemViewState.loaded;

  void setItems(List<ItemModel> items) {
    _fakeItems = items;
    _fakeState = items.isEmpty ? ItemViewState.empty : ItemViewState.loaded;
    notifyListeners();
  }

  void setState(ItemViewState state) {
    _fakeState = state;
    notifyListeners();
  }

  @override
  void updateUser(String? uid) {}

  @override
  void subscribeToItems([String? uid]) {}

  @override
  Future<bool> addItem({
    required String name,
    required int stock,
    required double price,
  }) async {
    _fakeItems.add(
      ItemModel(
        id: 'new_id_${_fakeItems.length + 1}',
        name: name,
        stock: stock,
        price: price,
      ),
    );
    _fakeState = ItemViewState.loaded;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> updateItem({
    required String itemId,
    required String name,
    required int stock,
    required double price,
  }) async {
    final index = _fakeItems.indexWhere((it) => it.id == itemId);
    if (index != -1) {
      _fakeItems[index] = ItemModel(
        id: itemId,
        name: name,
        stock: stock,
        price: price,
      );
      notifyListeners();
    }
    return true;
  }

  @override
  Future<bool> deleteItem(String itemId) async {
    _fakeItems.removeWhere((it) => it.id == itemId);
    if (_fakeItems.isEmpty) {
      _fakeState = ItemViewState.empty;
    }
    notifyListeners();
    return true;
  }

  @override
  void clearError() {
    _fakeErrorMessage = null;
    notifyListeners();
  }
}

Widget createTestableWidget({
  required Widget child,
  required AuthProvider authProvider,
  ItemProvider? itemProvider,
  ApiProvider? apiProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<ItemProvider>.value(
        value: itemProvider ?? FakeItemProvider(),
      ),
      ChangeNotifierProvider<ApiProvider>.value(
        value: apiProvider ?? ApiProvider(),
      ),
    ],
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
        expect(find.text('Inventaris Warung Aktif'), findsOneWidget);
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

  group('WarungStock Inventory (Firestore CRUD) Tests', () {
    test('ItemModel fromMap and toMap serialize correctly', () {
      final map = {'name': 'Gula Pasir 1kg', 'stock': 25, 'price': 17500.0};

      final item = ItemModel.fromMap(map, 'item_123');
      expect(item.id, 'item_123');
      expect(item.name, 'Gula Pasir 1kg');
      expect(item.stock, 25);
      expect(item.price, 17500.0);

      final exportedMap = item.toMap();
      expect(exportedMap['name'], 'Gula Pasir 1kg');
      expect(exportedMap['stock'], 25);
      expect(exportedMap['price'], 17500.0);
    });

    testWidgets('HomeScreen menampilkan empty state ketika inventaris kosong', (
      WidgetTester tester,
    ) async {
      final fakeAuth = FakeAuthProvider(
        initialUser: _createMockUser('warung@example.com'),
      );
      final fakeItem = FakeItemProvider(
        initialItems: [],
        initialState: ItemViewState.empty,
      );

      await tester.pumpWidget(
        createTestableWidget(
          authProvider: fakeAuth,
          itemProvider: fakeItem,
          child: const HomeScreen(),
        ),
      );

      expect(find.text('Inventaris Warung Masih Kosong'), findsOneWidget);
      expect(find.byKey(const Key('empty_add_item_button')), findsOneWidget);
    });

    testWidgets('HomeScreen menampilkan daftar barang saat loaded', (
      WidgetTester tester,
    ) async {
      final fakeAuth = FakeAuthProvider(
        initialUser: _createMockUser('warung@example.com'),
      );
      final fakeItem = FakeItemProvider(
        initialItems: [
          const ItemModel(
            id: 'item_1',
            name: 'Kopi Kapal Api',
            stock: 50,
            price: 3500.0,
          ),
          const ItemModel(
            id: 'item_2',
            name: 'Minyak Goreng 2L',
            stock: 12,
            price: 34000.0,
          ),
        ],
        initialState: ItemViewState.loaded,
      );

      await tester.pumpWidget(
        createTestableWidget(
          authProvider: fakeAuth,
          itemProvider: fakeItem,
          child: const HomeScreen(),
        ),
      );

      expect(find.text('Daftar Barang (2)'), findsOneWidget);
      expect(find.text('Kopi Kapal Api'), findsOneWidget);
      expect(find.text('Minyak Goreng 2L'), findsOneWidget);
      expect(find.text('Stok: 50 unit'), findsOneWidget);
      expect(find.text('Rp 3500'), findsOneWidget);
    });

    testWidgets('Dialog tambah barang melakukan validasi input wajib', (
      WidgetTester tester,
    ) async {
      final fakeAuth = FakeAuthProvider(
        initialUser: _createMockUser('warung@example.com'),
      );
      final fakeItem = FakeItemProvider(
        initialItems: [],
        initialState: ItemViewState.empty,
      );

      await tester.pumpWidget(
        createTestableWidget(
          authProvider: fakeAuth,
          itemProvider: fakeItem,
          child: const HomeScreen(),
        ),
      );

      // Buka dialog tambah barang via FAB
      await tester.tap(find.byKey(const Key('add_item_fab')));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Barang Baru'), findsOneWidget);

      // Tekan tombol simpan tanpa isi
      await tester.tap(find.byKey(const Key('item_save_button')));
      await tester.pumpAndSettle();

      expect(find.text('Nama barang tidak boleh kosong'), findsOneWidget);
      expect(find.text('Stok tidak boleh kosong'), findsOneWidget);
      expect(find.text('Harga tidak boleh kosong'), findsOneWidget);
    });

    testWidgets(
      'HomeScreen menampilkan akses katalog dan navigasi ke ProductListScreen berhasil',
      (WidgetTester tester) async {
        final fakeAuth = FakeAuthProvider(
          initialUser: _createMockUser('warung@example.com'),
        );
        final fakeItem = FakeItemProvider(
          initialItems: [],
          initialState: ItemViewState.empty,
        );

        await tester.pumpWidget(
          createTestableWidget(
            authProvider: fakeAuth,
            itemProvider: fakeItem,
            child: const HomeScreen(),
          ),
        );

        expect(find.text('Katalog Produk Grosir'), findsOneWidget);
        expect(find.byKey(const Key('home_catalog_button')), findsOneWidget);
        expect(find.byKey(const Key('appbar_catalog_button')), findsOneWidget);

        await tester.tap(find.byKey(const Key('home_catalog_button')));
        await tester.pumpAndSettle();

        expect(find.byType(ProductListScreen), findsOneWidget);
        expect(find.text('Katalog Produk Grosir'), findsOneWidget);
      },
    );
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

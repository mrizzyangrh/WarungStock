import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart';

/// State representasi data inventaris pada UI.
enum ItemViewState { initial, loading, loaded, empty, error }

/// Provider pengelola state inventaris warung berbasis Firestore.
class ItemProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  StreamSubscription<List<ItemModel>>? _itemsSubscription;

  List<ItemModel> _items = [];
  ItemViewState _state = ItemViewState.initial;
  String? _errorMessage;
  bool _isActionLoading = false;
  String? _currentUserId;

  ItemProvider({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  List<ItemModel> get items => List.unmodifiable(_items);
  ItemViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isActionLoading => _isActionLoading;
  bool get isLoading => _state == ItemViewState.loading;
  bool get isEmpty => _state == ItemViewState.empty;
  bool get isLoaded => _state == ItemViewState.loaded;

  /// Memperbarui pengguna aktif dan mengelola siklus subscription Firestore.
  /// Dipanggil saat inisialisasi atau ketika sesi autentikasi pengguna berubah.
  void updateUser(String? uid) {
    if (_currentUserId == uid) {
      return;
    }

    _currentUserId = uid;
    _cancelSubscription();

    if (uid == null || uid.isEmpty) {
      // User logout: bersihkan data inventaris secara aman
      _items = [];
      _state = ItemViewState.initial;
      _errorMessage = null;
      _isActionLoading = false;
      notifyListeners();
    } else {
      // User baru/login: mulai stream inventaris
      subscribeToItems(uid);
    }
  }

  /// Mulai berlangganan ke getItemsStream() Firestore.
  void subscribeToItems([String? uid]) {
    final targetUid = uid ?? _currentUserId;
    if (targetUid == null || targetUid.isEmpty) {
      _state = ItemViewState.error;
      _errorMessage = 'Sesi pengguna tidak valid.';
      notifyListeners();
      return;
    }

    _state = ItemViewState.loading;
    _errorMessage = null;
    notifyListeners();

    _cancelSubscription();

    try {
      _itemsSubscription = _firestoreService
          .getItemsStream(targetUid)
          .listen(
            (itemsList) {
              _items = itemsList;
              _state = itemsList.isEmpty
                  ? ItemViewState.empty
                  : ItemViewState.loaded;
              _errorMessage = null;
              notifyListeners();
            },
            onError: (error) {
              _state = ItemViewState.error;
              _errorMessage = error.toString().replaceFirst('Exception: ', '');
              notifyListeners();
            },
          );
    } catch (e) {
      _state = ItemViewState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Tambah barang baru ke inventaris Firestore.
  Future<bool> addItem({
    required String name,
    required int stock,
    required double price,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.addItem(
        name: name,
        stock: stock,
        price: price,
        uid: _currentUserId,
      );
      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Perbarui barang yang sudah ada di inventaris Firestore.
  Future<bool> updateItem({
    required String itemId,
    required String name,
    required int stock,
    required double price,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.updateItem(
        itemId: itemId,
        name: name,
        stock: stock,
        price: price,
        uid: _currentUserId,
      );
      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Hapus barang dari inventaris Firestore.
  Future<bool> deleteItem(String itemId) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.deleteItem(itemId, _currentUserId);
      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Bersihkan pesan error aktif.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _cancelSubscription() {
    _itemsSubscription?.cancel();
    _itemsSubscription = null;
  }

  @override
  void dispose() {
    _cancelSubscription();
    super.dispose();
  }
}

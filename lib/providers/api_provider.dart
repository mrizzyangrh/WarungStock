import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

/// State representasi status siklus hidup permintaan REST API.
enum ApiViewState { initial, loading, loaded, empty, error }

/// Provider pengelola state untuk integrasi REST API DummyJSON.
class ApiProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<ProductModel> _products = [];
  ProductModel? _selectedProduct;
  ApiViewState _state = ApiViewState.initial;
  ApiViewState _detailState = ApiViewState.initial;
  String? _errorMessage;
  String? _detailErrorMessage;

  ApiProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  // Getters
  List<ProductModel> get products => List.unmodifiable(_products);
  ProductModel? get selectedProduct => _selectedProduct;
  ApiViewState get state => _state;
  ApiViewState get detailState => _detailState;
  String? get errorMessage => _errorMessage;
  String? get detailErrorMessage => _detailErrorMessage;

  bool get isLoading => _state == ApiViewState.loading;
  bool get isLoaded => _state == ApiViewState.loaded;
  bool get isEmpty => _state == ApiViewState.empty;
  bool get isError => _state == ApiViewState.error;
  bool get isDetailLoading => _detailState == ApiViewState.loading;

  /// Mengambil daftar katalog produk dari API DummyJSON.
  /// Parameter [forceRefresh] digunakan jika ingin memaksa request ulang meskipun data sudah ada.
  Future<void> fetchProducts({bool forceRefresh = false}) async {
    // Hindari request berulang jika data sudah ada dan tidak dipaksa refresh
    if (!forceRefresh &&
        _state == ApiViewState.loaded &&
        _products.isNotEmpty) {
      return;
    }

    _state = ApiViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedProducts = await _apiService.getProducts();
      _products = fetchedProducts;
      _state = fetchedProducts.isEmpty
          ? ApiViewState.empty
          : ApiViewState.loaded;
      _errorMessage = null;
    } catch (e) {
      _state = ApiViewState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  /// Meminta ulang (retry) pengambilan katalog produk.
  Future<void> retryFetchProducts() async {
    await fetchProducts(forceRefresh: true);
  }

  /// Mengambil detail satu produk berdasarkan [id].
  /// Error pada detail tidak akan menghapus atau merusak daftar produk yang sudah dimuat.
  Future<ProductModel?> fetchProductDetail(
    int id, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _selectedProduct?.id == id &&
        _detailState == ApiViewState.loaded) {
      return _selectedProduct;
    }

    _detailState = ApiViewState.loading;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final product = await _apiService.getProductById(id);
      _selectedProduct = product;
      _detailState = ApiViewState.loaded;
      _detailErrorMessage = null;
      return product;
    } catch (e) {
      _detailState = ApiViewState.error;
      _detailErrorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      notifyListeners();
    }
  }

  /// Membersihkan data detail produk yang sedang dipilih.
  void clearSelectedProduct() {
    _selectedProduct = null;
    _detailState = ApiViewState.initial;
    _detailErrorMessage = null;
    notifyListeners();
  }

  /// Membersihkan pesan kesalahan aktif.
  void clearErrors() {
    _errorMessage = null;
    _detailErrorMessage = null;
    notifyListeners();
  }
}

import 'package:dio/dio.dart';
import '../models/product_model.dart';

/// Layanan komunikasi REST API ke DummyJSON menggunakan Dio.
/// Base URL: `https://dummyjson.com`
///
/// Katalog yang ditampilkan adalah produk kategori groceries (sembako).
/// Endpoint daftar: `GET /products/category/groceries`
/// Endpoint detail: `GET /products/{id}`
class ApiService {
  final Dio _dio;

  static const String defaultBaseUrl = 'https://dummyjson.com';

  /// Path kategori produk sembako/groceries.
  static const String groceriesCategoryPath = '/products/category/groceries';

  static const Duration defaultConnectTimeout = Duration(seconds: 10);
  static const Duration defaultReceiveTimeout = Duration(seconds: 10);

  ApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: defaultBaseUrl,
              connectTimeout: defaultConnectTimeout,
              receiveTimeout: defaultReceiveTimeout,
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          );

  /// Mengambil seluruh produk kategori sembako/groceries dari DummyJSON.
  /// Endpoint: `GET /products/category/groceries`
  ///
  /// Menggunakan `limit=0` untuk mengambil semua produk groceries sekaligus
  /// (total ±20 produk). Parameter [skip] tetap tersedia untuk fleksibilitas.
  Future<List<ProductModel>> getProducts({int limit = 0, int skip = 0}) async {
    try {
      final response = await _dio.get(
        groceriesCategoryPath,
        queryParameters: {'limit': limit, 'skip': skip},
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['products'] is List) {
        final List<dynamic> productsJson = data['products'] as List<dynamic>;
        return productsJson
            .whereType<Map<String, dynamic>>()
            .map((item) => ProductModel.fromJson(item))
            .toList();
      }

      throw Exception('Format respons katalog produk tidak valid.');
    } on DioException catch (e) {
      throw Exception(_mapDioException(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan tidak terduga: $e');
    }
  }

  /// Mengambil detail satu produk berdasarkan ID.
  /// Endpoint: `GET /products/{id}`
  Future<ProductModel> getProductById(int id) async {
    try {
      final response = await _dio.get('/products/$id');

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ProductModel.fromJson(data);
      }

      throw Exception('Format data detail produk tidak valid.');
    } on DioException catch (e) {
      throw Exception(_mapDioException(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan tidak terduga saat memuat detail: $e');
    }
  }

  /// Memetakan DioException menjadi pesan kesalahan yang ramah pengguna.
  String _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Waktu koneksi ke server habis. Periksa koneksi internet Anda.';
      case DioExceptionType.sendTimeout:
        return 'Waktu pengiriman data ke server habis.';
      case DioExceptionType.receiveTimeout:
        return 'Waktu respons dari server habis. Server lambat merespons.';
      case DioExceptionType.transformTimeout:
        return 'Waktu pemrosesan data respons server habis.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 404) {
          return 'Produk tidak ditemukan di server (404).';
        } else if (statusCode == 400) {
          return 'Permintaan data tidak valid (400).';
        } else if (statusCode != null && statusCode >= 500) {
          return 'Server sedang mengalami gangguan ($statusCode). Silakan coba lagi nanti.';
        }
        return 'Terjadi kesalahan respons dari server (${statusCode ?? "unknown"}).';
      case DioExceptionType.cancel:
        return 'Permintaan ke server dibatalkan.';
      case DioExceptionType.connectionError:
        return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
      case DioExceptionType.badCertificate:
        return 'Sertifikat keamanan server tidak valid.';
      case DioExceptionType.unknown:
        return 'Terjadi kesalahan jaringan atau koneksi tidak stabil.';
    }
  }
}

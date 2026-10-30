import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warung_stock/models/product_model.dart';
import 'package:warung_stock/providers/api_provider.dart';
import 'package:warung_stock/services/api_service.dart';

void main() {
  group('ProductModel Unit Tests', () {
    test('fromJson berhasil mem-parsing data lengkap dari DummyJSON', () {
      final json = {
        'id': 1,
        'title': 'Beras Premium 5kg',
        'description': 'Beras pulen kualitas super',
        'category': 'groceries',
        'price': 72500.50,
        'discountPercentage': 5.25,
        'rating': 4.85,
        'stock': 40,
        'brand': 'Slyp Super',
        'thumbnail': 'https://dummyjson.com/thumb.jpg',
        'images': [
          'https://dummyjson.com/img1.jpg',
          'https://dummyjson.com/img2.jpg',
        ],
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, 1);
      expect(product.title, 'Beras Premium 5kg');
      expect(product.description, 'Beras pulen kualitas super');
      expect(product.category, 'groceries');
      expect(product.price, 72500.50);
      expect(product.discountPercentage, 5.25);
      expect(product.rating, 4.85);
      expect(product.stock, 40);
      expect(product.brand, 'Slyp Super');
      expect(product.thumbnail, 'https://dummyjson.com/thumb.jpg');
      expect(product.images.length, 2);
      expect(product.images.first, 'https://dummyjson.com/img1.jpg');
    });

    test('fromJson menangani data null, kosong, atau tipe num dengan aman', () {
      final json = {
        'id': 99,
        'title': null,
        'description': null,
        'category': null,
        'price': 50000, // integer as price
        'discountPercentage': 10, // integer as discount
        'rating': 4, // integer as rating
        'stock': 15.0, // double as stock
        'brand': null,
        'thumbnail': null,
        'images': null,
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, 99);
      expect(product.title, '');
      expect(product.description, '');
      expect(product.category, '');
      expect(product.price, 50000.0);
      expect(product.discountPercentage, 10.0);
      expect(product.rating, 4.0);
      expect(product.stock, 15);
      expect(product.brand, '');
      expect(product.thumbnail, '');
      expect(product.images, isEmpty);
    });

    test('toJson menghasilkan Map dengan struktur yang sesuai', () {
      const product = ProductModel(
        id: 10,
        title: 'Minyak Goreng 2L',
        description: 'Minyak kelapa sawit murni',
        category: 'groceries',
        price: 34000.0,
        discountPercentage: 2.5,
        rating: 4.7,
        stock: 20,
        brand: 'Bimoli',
        thumbnail: 'https://dummyjson.com/oil.jpg',
        images: ['https://dummyjson.com/oil1.jpg'],
      );

      final map = product.toJson();

      expect(map['id'], 10);
      expect(map['title'], 'Minyak Goreng 2L');
      expect(map['price'], 34000.0);
      expect(map['stock'], 20);
      expect(map['brand'], 'Bimoli');
      expect(map['images'], contains('https://dummyjson.com/oil1.jpg'));
    });
  });

  group('ApiService Dio Mock Tests', () {
    test(
      'getProducts berhasil mem-parsing list produk dari respons 200',
      () async {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'products': [
                      {
                        'id': 1,
                        'title': 'Kopi Kapal Api',
                        'price': 3500.0,
                        'stock': 50,
                        'category': 'beverages',
                      },
                      {
                        'id': 2,
                        'title': 'Teh Celup',
                        'price': 6000.0,
                        'stock': 30,
                        'category': 'beverages',
                      },
                    ],
                    'total': 2,
                    'skip': 0,
                    'limit': 30,
                  },
                ),
              );
            },
          ),
        );

        final apiService = ApiService(dio: dio);
        final products = await apiService.getProducts();

        expect(products.length, 2);
        expect(products[0].id, 1);
        expect(products[0].title, 'Kopi Kapal Api');
        expect(products[1].id, 2);
        expect(products[1].title, 'Teh Celup');
      },
    );

    test('getProductById berhasil mengambil detail produk', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 42,
                  'title': 'Gula Pasir 1kg',
                  'price': 17500.0,
                  'stock': 25,
                  'brand': 'Gulaku',
                },
              ),
            );
          },
        ),
      );

      final apiService = ApiService(dio: dio);
      final product = await apiService.getProductById(42);

      expect(product.id, 42);
      expect(product.title, 'Gula Pasir 1kg');
      expect(product.brand, 'Gulaku');
    });

    test(
      'getProductById menangani error 404 dengan pesan yang sesuai',
      () async {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.badResponse,
                  response: Response(
                    requestOptions: options,
                    statusCode: 404,
                    statusMessage: 'Not Found',
                  ),
                ),
              );
            },
          ),
        );

        final apiService = ApiService(dio: dio);

        expect(
          () => apiService.getProductById(9999),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('404'),
            ),
          ),
        );
      },
    );

    test('getProducts menangani timeout error dengan pesan ramah', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionTimeout,
                message: 'Connection timed out',
              ),
            );
          },
        ),
      );

      final apiService = ApiService(dio: dio);

      expect(
        () => apiService.getProducts(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Waktu koneksi ke server habis'),
          ),
        ),
      );
    });
  });

  group('ApiProvider State Management Tests', () {
    test('Kondisi initial state ApiProvider benar', () {
      final provider = ApiProvider();

      expect(provider.state, ApiViewState.initial);
      expect(provider.detailState, ApiViewState.initial);
      expect(provider.products, isEmpty);
      expect(provider.selectedProduct, isNull);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('fetchProducts berhasil bertransisi loading -> loaded', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'products': [
                    {'id': 1, 'title': 'Susu UHT 1L', 'price': 18000.0},
                  ],
                },
              ),
            );
          },
        ),
      );

      final apiService = ApiService(dio: dio);
      final provider = ApiProvider(apiService: apiService);

      final future = provider.fetchProducts();
      // Saat future berjalan, loading seharusnya aktif atau state akan berubah
      await future;

      expect(provider.state, ApiViewState.loaded);
      expect(provider.isLoaded, isTrue);
      expect(provider.isLoading, isFalse);
      expect(provider.products.length, 1);
      expect(provider.products.first.title, 'Susu UHT 1L');
      expect(provider.errorMessage, isNull);
    });

    test('fetchProducts bertransisi ke empty jika katalog kosong', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'products': []},
              ),
            );
          },
        ),
      );

      final apiService = ApiService(dio: dio);
      final provider = ApiProvider(apiService: apiService);

      await provider.fetchProducts();

      expect(provider.state, ApiViewState.empty);
      expect(provider.isEmpty, isTrue);
      expect(provider.isLoading, isFalse);
      expect(provider.products, isEmpty);
    });

    test(
      'fetchProducts bertransisi ke error dan menyimpan pesan kesalahan',
      () async {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                  message: 'No internet connection',
                ),
              );
            },
          ),
        );

        final apiService = ApiService(dio: dio);
        final provider = ApiProvider(apiService: apiService);

        await provider.fetchProducts();

        expect(provider.state, ApiViewState.error);
        expect(provider.isError, isTrue);
        expect(provider.isLoading, isFalse);
        expect(provider.errorMessage, isNotNull);
        expect(provider.errorMessage, contains('Gagal terhubung ke server'));
      },
    );

    test('retryFetchProducts memaksa request ulang', () async {
      int requestCount = 0;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestCount++;
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'products': [
                    {'id': 1, 'title': 'Barang $requestCount'},
                  ],
                },
              ),
            );
          },
        ),
      );

      final apiService = ApiService(dio: dio);
      final provider = ApiProvider(apiService: apiService);

      await provider.fetchProducts();
      expect(requestCount, 1);

      // Pemanggilan biasa tanpa forceRefresh saat loaded tidak menambah request
      await provider.fetchProducts();
      expect(requestCount, 1);

      // retryFetchProducts memicu request ulang
      await provider.retryFetchProducts();
      expect(requestCount, 2);
    });

    test(
      'fetchProductDetail berhasil dan error detail tidak menghapus produk',
      () async {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.path == '/products') {
                return handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 200,
                    data: {
                      'products': [
                        {'id': 10, 'title': 'Biskuit Roma', 'price': 8500.0},
                      ],
                    },
                  ),
                );
              } else if (options.path == '/products/10') {
                return handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 200,
                    data: {
                      'id': 10,
                      'title': 'Biskuit Roma',
                      'price': 8500.0,
                      'description': 'Biskuit kelapa renyah',
                    },
                  ),
                );
              } else {
                return handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.badResponse,
                    response: Response(
                      requestOptions: options,
                      statusCode: 404,
                    ),
                  ),
                );
              }
            },
          ),
        );

        final apiService = ApiService(dio: dio);
        final provider = ApiProvider(apiService: apiService);

        // 1. Muat produk
        await provider.fetchProducts();
        expect(provider.products.length, 1);

        // 2. Muat detail produk id 10 berhasil
        final detail = await provider.fetchProductDetail(10);
        expect(detail, isNotNull);
        expect(provider.selectedProduct?.description, 'Biskuit kelapa renyah');
        expect(provider.detailState, ApiViewState.loaded);

        // 3. Muat detail produk id 999 gagal 404
        final failedDetail = await provider.fetchProductDetail(999);
        expect(failedDetail, isNull);
        expect(provider.detailState, ApiViewState.error);
        expect(provider.detailErrorMessage, isNotNull);

        // 4. PENTING: Daftar produk sebelumnya tetap utuh tidak terhapus
        expect(provider.products.length, 1);
        expect(provider.products.first.title, 'Biskuit Roma');
      },
    );
  });
}

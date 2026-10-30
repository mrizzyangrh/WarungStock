import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:warung_stock/providers/api_provider.dart';
import 'package:warung_stock/screens/products/product_detail_screen.dart';
import 'package:warung_stock/screens/products/product_list_screen.dart';
import 'package:warung_stock/services/api_service.dart';

Dio _createMockDio({
  Map<String, dynamic>? detailResponse,
  Map<String, dynamic>? productsResponse,
  DioException? detailError,
}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path == '/products/1') {
          if (detailError != null) {
            return handler.reject(detailError);
          }
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data:
                  detailResponse ??
                  {
                    'id': 1,
                    'title': 'Beras Premium Ramos 5kg',
                    'description':
                        'Beras pulen berkualitas super asli Cianjur.',
                    'category': 'groceries',
                    'price': 72000.0,
                    'discountPercentage': 10.0,
                    'rating': 4.8,
                    'stock': 35,
                    'brand': 'Ramos Jaya',
                    'thumbnail': 'https://dummyjson.com/thumb.jpg',
                    'images': [
                      'https://dummyjson.com/img1.jpg',
                      'https://dummyjson.com/img2.jpg',
                    ],
                  },
            ),
          );
        } else if (options.path == '/products') {
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data:
                  productsResponse ??
                  {
                    'products': [
                      {
                        'id': 1,
                        'title': 'Beras Premium Ramos 5kg',
                        'price': 72000.0,
                        'stock': 35,
                      },
                    ],
                  },
            ),
          );
        }
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: options, statusCode: 404),
          ),
        );
      },
    ),
  );
  return dio;
}

Widget _wrapWithProvider(ApiProvider provider, {required int productId}) {
  return MaterialApp(
    home: ChangeNotifierProvider<ApiProvider>.value(
      value: provider,
      child: ProductDetailScreen(productId: productId),
    ),
  );
}

void main() {
  group('ProductDetailScreen Widget Tests', () {
    testWidgets('Menampilkan AppBar dengan judul Detail Produk', (
      WidgetTester tester,
    ) async {
      final dio = _createMockDio();
      final provider = ApiProvider(apiService: ApiService(dio: dio));

      await tester.pumpWidget(_wrapWithProvider(provider, productId: 1));
      await tester.pumpAndSettle();

      expect(find.text('Detail Produk'), findsOneWidget);
      expect(find.byKey(const Key('refresh_detail_button')), findsOneWidget);
    });

    testWidgets('Menampilkan rincian informasi produk lengkap saat loaded', (
      WidgetTester tester,
    ) async {
      final dio = _createMockDio();
      final provider = ApiProvider(apiService: ApiService(dio: dio));

      await tester.pumpWidget(_wrapWithProvider(provider, productId: 1));
      await tester.pumpAndSettle();

      // Nama, Brand, Kategori
      expect(find.text('Beras Premium Ramos 5kg'), findsOneWidget);
      expect(find.text('Merek: Ramos Jaya'), findsOneWidget);
      expect(find.text('GROCERIES'), findsOneWidget);

      // Harga, Diskon, Rating, Stok
      expect(find.text('Rp 72000'), findsOneWidget);
      expect(find.text('-10%'), findsOneWidget);
      expect(find.text('4.8 / 5.0'), findsOneWidget);
      expect(find.text('Stok: 35 unit'), findsOneWidget);
      expect(find.text('ID: #1'), findsOneWidget);

      // Deskripsi
      expect(find.text('Deskripsi Produk'), findsOneWidget);
      expect(
        find.text('Beras pulen berkualitas super asli Cianjur.'),
        findsOneWidget,
      );

      // Galeri thumbnail tersedia
      expect(find.byKey(const Key('gallery_thumb_0')), findsOneWidget);
      expect(find.byKey(const Key('gallery_thumb_1')), findsOneWidget);
    });

    testWidgets('Mengubah foto galeri yang dipilih saat thumbnail ditekan', (
      WidgetTester tester,
    ) async {
      final dio = _createMockDio();
      final provider = ApiProvider(apiService: ApiService(dio: dio));

      await tester.pumpWidget(_wrapWithProvider(provider, productId: 1));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('gallery_thumb_1')));
      await tester.pump();
      // Pastikan tap tidak melempar error dan UI tetap ter-render
      expect(find.byKey(const Key('gallery_thumb_1')), findsOneWidget);
    });

    testWidgets(
      'Menampilkan error card dan tombol Coba Lagi saat request gagal',
      (WidgetTester tester) async {
        final dio = _createMockDio(
          detailError: DioException(
            requestOptions: RequestOptions(path: '/products/1'),
            type: DioExceptionType.connectionError,
            message: 'Gagal terhubung ke server',
          ),
        );
        final provider = ApiProvider(apiService: ApiService(dio: dio));

        await tester.pumpWidget(_wrapWithProvider(provider, productId: 1));
        await tester.pumpAndSettle();

        expect(find.text('Gagal Memuat Detail Produk'), findsOneWidget);
        expect(find.byKey(const Key('detail_retry_button')), findsOneWidget);
      },
    );

    testWidgets(
      'Navigasi default dari ProductListScreen membuka ProductDetailScreen',
      (WidgetTester tester) async {
        final dio = _createMockDio();
        final provider = ApiProvider(apiService: ApiService(dio: dio));

        await tester.pumpWidget(
          ChangeNotifierProvider<ApiProvider>.value(
            value: provider,
            child: const MaterialApp(home: ProductListScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Tekan kartu produk tanpa callback kustom
        await tester.tap(find.byKey(const Key('product_card_1')));
        await tester.pumpAndSettle();

        // Berhasil berpindah ke halaman ProductDetailScreen
        expect(find.byType(ProductDetailScreen), findsOneWidget);
        expect(find.text('Detail Produk'), findsOneWidget);
        expect(find.text('Beras Premium Ramos 5kg'), findsWidgets);
      },
    );
  });
}

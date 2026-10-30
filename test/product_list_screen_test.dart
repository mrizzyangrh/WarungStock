import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:warung_stock/models/product_model.dart';
import 'package:warung_stock/providers/api_provider.dart';
import 'package:warung_stock/screens/products/product_list_screen.dart';
import 'package:warung_stock/services/api_service.dart';
import 'package:warung_stock/widgets/product_card.dart';

Dio _createMockDio({
  Map<String, dynamic>? responseData,
  DioException? errorToThrow,
}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (errorToThrow != null) {
          return handler.reject(errorToThrow);
        }
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: responseData ?? {'products': []},
          ),
        );
      },
    ),
  );
  return dio;
}

Widget _wrapWithProvider(
  ApiProvider provider, {
  ValueChanged<ProductModel>? onProductTap,
}) {
  return MaterialApp(
    home: ChangeNotifierProvider<ApiProvider>.value(
      value: provider,
      child: ProductListScreen(onProductTap: onProductTap),
    ),
  );
}

void main() {
  group('ProductListScreen Widget Tests', () {
    testWidgets('Menampilkan AppBar dengan judul Katalog Produk Grosir', (
      WidgetTester tester,
    ) async {
      final dio = _createMockDio(responseData: {'products': []});
      final provider = ApiProvider(apiService: ApiService(dio: dio));

      await tester.pumpWidget(_wrapWithProvider(provider));
      await tester.pumpAndSettle();

      expect(find.text('Katalog Produk Grosir'), findsOneWidget);
      expect(find.byKey(const Key('refresh_catalog_button')), findsOneWidget);
    });

    testWidgets('Menampilkan empty state jika API mengembalikan list kosong', (
      WidgetTester tester,
    ) async {
      final dio = _createMockDio(responseData: {'products': []});
      final provider = ApiProvider(apiService: ApiService(dio: dio));

      await tester.pumpWidget(_wrapWithProvider(provider));
      // Biarkan postFrameCallback fetchProducts dieksekusi
      await tester.pumpAndSettle();

      expect(find.text('Katalog Produk Kosong'), findsOneWidget);
      expect(
        find.byKey(const Key('catalog_empty_refresh_button')),
        findsOneWidget,
      );
    });

    testWidgets('Menampilkan daftar produk saat state loaded', (
      WidgetTester tester,
    ) async {
      final dio = _createMockDio(
        responseData: {
          'products': [
            {
              'id': 1,
              'title': 'Beras Super 5kg',
              'category': 'groceries',
              'price': 68000.0,
              'discountPercentage': 5.0,
              'rating': 4.8,
              'stock': 30,
              'thumbnail': '',
            },
            {
              'id': 2,
              'title': 'Gula Pasir 1kg',
              'category': 'groceries',
              'price': 17500.0,
              'discountPercentage': 0.0,
              'rating': 4.9,
              'stock': 45,
              'thumbnail': '',
            },
          ],
        },
      );
      final provider = ApiProvider(apiService: ApiService(dio: dio));

      await tester.pumpWidget(_wrapWithProvider(provider));
      await tester.pumpAndSettle();

      expect(find.text('Daftar Produk (2 barang)'), findsOneWidget);
      expect(find.text('Beras Super 5kg'), findsOneWidget);
      expect(find.text('Gula Pasir 1kg'), findsOneWidget);
      expect(find.text('Rp 68000'), findsOneWidget);
      expect(find.text('Rp 17500'), findsOneWidget);
      expect(find.byType(ProductCard), findsNWidgets(2));
    });

    testWidgets(
      'Menampilkan error card dan tombol Coba Lagi saat request gagal',
      (WidgetTester tester) async {
        final dio = _createMockDio(
          errorToThrow: DioException(
            requestOptions: RequestOptions(path: '/products'),
            type: DioExceptionType.connectionError,
            message: 'Koneksi internet bermasalah',
          ),
        );
        final provider = ApiProvider(apiService: ApiService(dio: dio));

        await tester.pumpWidget(_wrapWithProvider(provider));
        await tester.pumpAndSettle();

        expect(find.text('Gagal Memuat Katalog Produk'), findsOneWidget);
        expect(find.byKey(const Key('catalog_retry_button')), findsOneWidget);
      },
    );

    testWidgets('Menjalankan callback onProductTap saat kartu produk diklik', (
      WidgetTester tester,
    ) async {
      ProductModel? tappedProduct;

      final dio = _createMockDio(
        responseData: {
          'products': [
            {
              'id': 7,
              'title': 'Kopi Arabika 250g',
              'category': 'beverages',
              'price': 35000.0,
              'discountPercentage': 10.0,
              'rating': 4.7,
              'stock': 12,
              'thumbnail': '',
            },
          ],
        },
      );
      final provider = ApiProvider(apiService: ApiService(dio: dio));

      await tester.pumpWidget(
        _wrapWithProvider(
          provider,
          onProductTap: (product) {
            tappedProduct = product;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('product_card_7')));
      await tester.pump();

      expect(tappedProduct, isNotNull);
      expect(tappedProduct?.id, 7);
      expect(tappedProduct?.title, 'Kopi Arabika 250g');
    });
  });
}

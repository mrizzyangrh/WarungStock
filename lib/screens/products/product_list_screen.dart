import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/api_provider.dart';
import '../../widgets/product_card.dart';
import 'product_detail_screen.dart';

/// Halaman katalog produk grosir eksternal dari DummyJSON.
class ProductListScreen extends StatefulWidget {
  final ValueChanged<ProductModel>? onProductTap;

  const ProductListScreen({super.key, this.onProductTap});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    // Meminta katalog produk hanya pada saat halaman pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ApiProvider>().fetchProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final apiProvider = context.watch<ApiProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.inventory_2_outlined),
            SizedBox(width: 8),
            Text(
              'Katalog Produk Grosir',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('refresh_catalog_button'),
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan Katalog',
            onPressed: () => context.read<ApiProvider>().retryFetchProducts(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: _buildBodyContent(context, apiProvider),
        ),
      ),
    );
  }

  Widget _buildBodyContent(BuildContext context, ApiProvider apiProvider) {
    final theme = Theme.of(context);

    // 1. Loading & Initial State
    if (apiProvider.isLoading || apiProvider.state == ApiViewState.initial) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Memuat katalog produk grosir...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // 2. Error State
    if (apiProvider.isError || apiProvider.state == ApiViewState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            color: theme.colorScheme.errorContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal Memuat Katalog Produk',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    apiProvider.errorMessage ??
                        'Terjadi kesalahan saat menghubungi server DummyJSON.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const Key('catalog_retry_button'),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    onPressed: () => apiProvider.retryFetchProducts(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 3. Empty State
    if (apiProvider.isEmpty || apiProvider.products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Katalog Produk Kosong',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tidak ada produk yang tersedia dari server DummyJSON saat ini.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                key: const Key('catalog_empty_refresh_button'),
                icon: const Icon(Icons.refresh),
                label: const Text('Muat Ulang'),
                onPressed: () => apiProvider.retryFetchProducts(),
              ),
            ],
          ),
        ),
      );
    }

    // 4. Loaded State: GridView produk responsif
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bar info jumlah produk dan sumber API
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Produk (${apiProvider.products.length} barang)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Sumber: DummyJSON API',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.teal.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Grid Produk
        Expanded(
          child: GridView.builder(
            key: const Key('product_grid_view'),
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.68,
            ),
            itemCount: apiProvider.products.length,
            itemBuilder: (context, index) {
              final product = apiProvider.products[index];
              return ProductCard(
                product: product,
                onProductTap:
                    widget.onProductTap ??
                    (tappedProduct) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProductDetailScreen(productId: tappedProduct.id),
                        ),
                      );
                    },
              );
            },
          ),
        ),
      ],
    );
  }
}

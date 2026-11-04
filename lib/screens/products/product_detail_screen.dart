import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/api_provider.dart';

/// Halaman detail produk sembako (groceries) dari DummyJSON.
class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ApiProvider>().fetchProductDetail(widget.productId);
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
            Icon(Icons.info_outline_rounded),
            SizedBox(width: 8),
            Text(
              'Detail Produk',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('refresh_detail_button'),
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan Detail',
            onPressed: () {
              apiProvider.fetchProductDetail(
                widget.productId,
                forceRefresh: true,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: _buildDetailContent(context, apiProvider),
        ),
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, ApiProvider apiProvider) {
    final theme = Theme.of(context);

    // 1. Loading & Initial State
    if (apiProvider.isDetailLoading ||
        apiProvider.detailState == ApiViewState.initial) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Memuat detail produk...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // 2. Error State
    if (apiProvider.detailState == ApiViewState.error) {
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
                    'Gagal Memuat Detail Produk',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    apiProvider.detailErrorMessage ??
                        'Terjadi kesalahan saat memuat data produk.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const Key('detail_retry_button'),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    onPressed: () {
                      apiProvider.fetchProductDetail(
                        widget.productId,
                        forceRefresh: true,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 3. Loaded State
    final product = apiProvider.selectedProduct;
    if (product == null) {
      return const Center(child: Text('Data produk tidak ditemukan.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 720;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: isWideScreen
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kolom Kiri: Galeri Gambar
                    Expanded(
                      flex: 5,
                      child: _buildImageSection(context, product),
                    ),
                    const SizedBox(width: 32),
                    // Kolom Kanan: Rincian Produk
                    Expanded(
                      flex: 6,
                      child: _buildInfoSection(context, product),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageSection(context, product),
                    const SizedBox(height: 24),
                    _buildInfoSection(context, product),
                  ],
                ),
        );
      },
    );
  }

  /// Bagian galeri gambar produk
  Widget _buildImageSection(BuildContext context, ProductModel product) {
    final theme = Theme.of(context);
    final allImages = product.images.isNotEmpty
        ? product.images
        : (product.thumbnail.isNotEmpty ? [product.thumbnail] : <String>[]);

    final currentImageUrl =
        allImages.isNotEmpty && _selectedImageIndex < allImages.length
        ? allImages[_selectedImageIndex]
        : product.thumbnail;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Gambar Utama
        Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Container(
            height: 320,
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            child: currentImageUrl.isNotEmpty
                ? Image.network(
                    currentImageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                      );
                    },
                  )
                : Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                  ),
          ),
        ),

        // Thumbnail Galeri (jika lebih dari 1 gambar)
        if (allImages.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: allImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == _selectedImageIndex;
                return InkWell(
                  key: Key('gallery_thumb_$index'),
                  onTap: () {
                    setState(() {
                      _selectedImageIndex = index;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      allImages[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image_outlined, size: 20),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  /// Bagian informasi rincian produk
  Widget _buildInfoSection(BuildContext context, ProductModel product) {
    final theme = Theme.of(context);
    final hasDiscount = product.discountPercentage > 0;

    // Perhitungan harga asli jika diskon tersedia
    final originalPrice = hasDiscount && product.discountPercentage < 100
        ? product.price / (1 - (product.discountPercentage / 100))
        : product.price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kategori & Brand
        Row(
          children: [
            if (product.category.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  product.category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSecondaryContainer,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            if (product.brand.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                'Merek: ${product.brand}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // Nama Produk
        Text(
          product.title.isNotEmpty ? product.title : 'Produk Tanpa Nama',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 12),

        // Rating dan Stok
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Rating
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 20, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${product.rating.toStringAsFixed(1)} / 5.0',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Stok
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Stok: ${product.stock} unit',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            // Indikator ID Produk
            Text(
              'ID: #${product.id}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),

        // Harga & Diskon
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.35,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harga Referensi (USD):',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '\$ ${product.price.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                    if (hasDiscount) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${product.discountPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '\$ ${originalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: theme.colorScheme.outline,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Deskripsi Produk
        Text(
          'Deskripsi Produk',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.description.isNotEmpty
              ? product.description
              : 'Tidak ada deskripsi yang tersedia untuk produk ini.',
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

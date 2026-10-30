/// Model representasi data produk dari REST API DummyJSON.
/// Endpoint: `https://dummyjson.com/products` dan `https://dummyjson.com/products/{id}`
class ProductModel {
  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String brand;
  final String thumbnail;
  final List<String> images;

  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.brand,
    required this.thumbnail,
    required this.images,
  });

  /// Factory untuk membuat ProductModel dari Map/JSON dengan penanganan tipe data yang aman.
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedImages = const [];
    if (json['images'] is List) {
      parsedImages = (json['images'] as List)
          .map((item) => item?.toString() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return ProductModel(
      id: (json['id'] is num) ? (json['id'] as num).toInt() : 0,
      title: (json['title'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      category: (json['category'] as String?)?.trim() ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      discountPercentage: (json['discountPercentage'] is num)
          ? (json['discountPercentage'] as num).toDouble()
          : 0.0,
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : 0.0,
      stock: (json['stock'] is num) ? (json['stock'] as num).toInt() : 0,
      brand: (json['brand'] as String?)?.trim() ?? '',
      thumbnail: (json['thumbnail'] as String?)?.trim() ?? '',
      images: parsedImages,
    );
  }

  /// Konversi instance ProductModel ke format Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'discountPercentage': discountPercentage,
      'rating': rating,
      'stock': stock,
      'brand': brand,
      'thumbnail': thumbnail,
      'images': images,
    };
  }

  /// Helper untuk menyalin model dengan nilai yang diperbarui.
  ProductModel copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    double? price,
    double? discountPercentage,
    double? rating,
    int? stock,
    String? brand,
    String? thumbnail,
    List<String>? images,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      rating: rating ?? this.rating,
      stock: stock ?? this.stock,
      brand: brand ?? this.brand,
      thumbnail: thumbnail ?? this.thumbnail,
      images: images ?? this.images,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ProductModel(id: $id, title: $title, price: $price, stock: $stock)';
  }
}

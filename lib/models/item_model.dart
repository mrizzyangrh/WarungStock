import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representasi data inventaris warung pada Firestore.
/// Path dokumen Firestore: `users/{uid}/items/{itemId}`
class ItemModel {
  final String id;
  final String name;
  final int stock;
  final double price;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ItemModel({
    required this.id,
    required this.name,
    required this.stock,
    required this.price,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory untuk membuat ItemModel dari data DocumentSnapshot Firestore.
  factory ItemModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ItemModel.fromMap(data, doc.id);
  }

  /// Factory untuk membuat ItemModel dari Map data dengan id dokumen eksplisit.
  factory ItemModel.fromMap(Map<String, dynamic> data, String id) {
    return ItemModel(
      id: id,
      name: (data['name'] as String?)?.trim() ?? '',
      stock: (data['stock'] is num) ? (data['stock'] as num).toInt() : 0,
      price: (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  /// Konversi data model ke Map untuk penyimpanan Firestore.
  /// createdAt dan updatedAt dapat menggunakan FieldValue.serverTimestamp() atau Timestamp saat pemanggilan service.
  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'stock': stock,
      'price': price,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  /// Helper untuk membuat salinan instance dengan beberapa properti yang diubah.
  ItemModel copyWith({
    String? id,
    String? name,
    int? stock,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      stock: stock ?? this.stock,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Konversi nilai Timestamp / DateTime / dynamic dengan aman.
  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is DateTime) {
      return value;
    } else if (value is String) {
      return DateTime.tryParse(value);
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}

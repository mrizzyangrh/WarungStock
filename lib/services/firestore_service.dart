import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';

/// Layanan untuk operasi CRUD inventaris warung pada Cloud Firestore.
/// Semua operasi terisolasi di path: `users/{uid}/items/{itemId}`
class FirestoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// Helper untuk mendapatkan UID pengguna aktif.
  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null || user.uid.isEmpty) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message:
            'Pengguna belum terautentikasi. Silakan masuk terlebih dahulu.',
      );
    }
    return user.uid;
  }

  /// Referensi CollectionReference untuk `users/{uid}/items`
  CollectionReference<Map<String, dynamic>> _itemsCollection([
    String? customUid,
  ]) {
    final uid = customUid ?? _currentUserId;
    return _firestore.collection('users').doc(uid).collection('items');
  }

  /// Menambahkan barang baru ke inventaris pengguna aktif.
  Future<String> addItem({
    required String name,
    required int stock,
    required double price,
    String? uid,
  }) async {
    try {
      final collection = _itemsCollection(uid);
      final now = FieldValue.serverTimestamp();
      final docRef = await collection.add({
        'name': name.trim(),
        'stock': stock,
        'price': price,
        'createdAt': now,
        'updatedAt': now,
      });
      return docRef.id;
    } on FirebaseException catch (e) {
      throw Exception('Gagal menambahkan barang: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception(
        'Terjadi kesalahan tidak terduga saat menambah barang: $e',
      );
    }
  }

  /// Mendengarkan perubahan data inventaris pengguna aktif secara real-time melalui Stream.
  /// Catatan: Pengurutan dilakukan di sisi aplikasi untuk menghindari kebutuhan composite index.
  Stream<List<ItemModel>> getItemsStream([String? customUid]) {
    try {
      final collection = _itemsCollection(customUid);
      return collection.snapshots().map((snapshot) {
        final items = snapshot.docs.map((doc) {
          return ItemModel.fromMap(doc.data(), doc.id);
        }).toList();

        // Pengurutan di sisi client (item terbaru berdasarkan createdAt atau updatedAt descending)
        items.sort((a, b) {
          final timeA =
              a.updatedAt ??
              a.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final timeB =
              b.updatedAt ??
              b.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return timeB.compareTo(timeA);
        });

        return items;
      });
    } on FirebaseException catch (e) {
      throw Exception('Gagal memuat stream inventaris: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception(
        'Terjadi kesalahan saat mendengarkan data inventaris: $e',
      );
    }
  }

  /// Mengambil data barang spesifik berdasarkan itemId.
  Future<ItemModel?> getItemById(String itemId, [String? customUid]) async {
    try {
      final doc = await _itemsCollection(customUid).doc(itemId).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return ItemModel.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw Exception('Gagal mengambil data barang: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mencari barang: $e');
    }
  }

  /// Memperbarui informasi barang yang sudah ada.
  Future<void> updateItem({
    required String itemId,
    required String name,
    required int stock,
    required double price,
    String? uid,
  }) async {
    try {
      final collection = _itemsCollection(uid);
      await collection.doc(itemId).update({
        'name': name.trim(),
        'stock': stock,
        'price': price,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Gagal memperbarui barang: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Terjadi kesalahan saat memperbarui barang: $e');
    }
  }

  /// Menghapus barang dari inventaris pengguna aktif.
  Future<void> deleteItem(String itemId, [String? uid]) async {
    try {
      final collection = _itemsCollection(uid);
      await collection.doc(itemId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Gagal menghapus barang: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Terjadi kesalahan saat menghapus barang: $e');
    }
  }
}

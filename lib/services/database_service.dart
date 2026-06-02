import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ====================================================================
  // 1. MANAJEMEN NOTIFIKASI SYSTEM (NOTIFICATION LOGIC)
  // ====================================================================

  /// Membuat dokumen pemberitahuan baru di Firestore
  Future<void> createNotification({
    required String
    receiverId, // UID penerima khusus, atau isi 'ALL' untuk notif global
    required String title,
    required String message,
  }) async {
    try {
      DocumentReference docRef = _db.collection('notifications').doc();
      await docRef.set({
        'id': docRef.id,
        'receiverId': receiverId,
        'title': title,
        'message': message,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Gagal membuat data notifikasi: $e");
    }
  }

  /// Membaca aliran real-time pesan notifikasi yang belum dibaca
  Stream<QuerySnapshot> getUnreadNotificationsStream(String userId) {
    return _db
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots();
  }

  // ====================================================================
  // 2. MANAJEMEN PRODUK KAMPUS (PRODUCT LOGIC)
  // ====================================================================

  /// Mengunggah gambar dagangan ke Firebase Storage dalam bentuk format byte
  Future<String> uploadProductImage(
    Uint8List imageBytes,
    String productId,
  ) async {
    try {
      Reference ref = _storage.ref().child('products').child('$productId.jpg');
      UploadTask uploadTask = ref.putData(imageBytes);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Gagal mengunggah foto produk: $e';
    }
  }

  /// Mengunggah item dagangan baru ke Firestore beserta trigger notifikasi global
  Future<void> uploadProduct({
    required String name,
    required String price,
    required String category,
    required String description,
    required String location,
    required String sellerId,
    required Uint8List? imageBytes,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    try {
      DocumentReference docRef = _db.collection('products').doc();
      String imageUrl = 'assets/images/profile_placeholder.png';

      if (imageBytes != null) {
        imageUrl = await uploadProductImage(imageBytes, docRef.id);
      }

      // Tarik info nama & foto profil asli uploader dari sistem login Auth
      final user = _auth.currentUser;
      String sellerName =
          user?.displayName ?? user?.email?.split('@')[0] ?? 'Mahasiswa UNESA';
      String sellerPhoto = user?.photoURL ?? '';

      await docRef.set({
        'id': docRef.id,
        'name': name,
        'price': price,
        'category': category.toUpperCase(),
        'description': description,
        'location': location,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'sellerPhoto': sellerPhoto,
        'imagePath': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // TRIGGER NOTIFIKASI: Kabari seluruh mahasiswa UNESA bahwa ada barang baru terunggah
      await createNotification(
        receiverId: 'ALL',
        title: 'Produk Baru Di-upload!',
        message:
            '$sellerName baru saja mengunggah barang "$name" di kategori $category.',
      );

      onSuccess();
    } catch (e) {
      onError('Gagal mengunggah barang: $e');
    }
  }

  /// Memperbarui rincian detail barang dagangan yang sudah ada di database
  Future<void> updateProduct({
    required String productId,
    required String name,
    required String price,
    required String category,
    required String description,
    required String location,
    required Uint8List? newImageBytes,
    required String existingImageUrl,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    try {
      String finalImageUrl = existingImageUrl;
      if (newImageBytes != null) {
        finalImageUrl = await uploadProductImage(newImageBytes, productId);
      }

      final user = _auth.currentUser;
      String sellerName =
          user?.displayName ?? user?.email?.split('@')[0] ?? 'Mahasiswa UNESA';
      String sellerPhoto = user?.photoURL ?? '';

      await _db.collection('products').doc(productId).update({
        'name': name,
        'price': price,
        'category': category.toUpperCase(),
        'description': description,
        'location': location,
        'imagePath': finalImageUrl,
        'sellerName': sellerName,
        'sellerPhoto': sellerPhoto,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      onSuccess();
    } catch (e) {
      onError('Gagal memperbarui barang: $e');
    }
  }

  /// Menghapus produk dari Firestore beserta file gambarnya di Firebase Storage
  Future<void> deleteProduct(String productId) async {
    try {
      await _db.collection('products').doc(productId).delete();
      await _storage.ref().child('products').child('$productId.jpg').delete();
    } catch (e) {
      print('Info: Foto di Storage tidak ada atau gagal dihapus: $e');
    }
  }

  /// Stream utama untuk memuat data beranda marketplace (Home Grid)
  Stream<QuerySnapshot> getProductsStream() {
    return _db
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ====================================================================
  // 3. MANAJEMEN ALUR TRANSAKSI MAHASISWA (ORDER LOGIC)
  // ====================================================================

  /// Membuat pesanan pembelian baru di Firestore & mengirim notifikasi personal ke penjual
  Future<void> placeOrder({
    required String name,
    required String price,
    required String category,
    required String description,
    required String location,
    required String imagePath,
    required String sellerId,
    required String sellerName,
    required String buyerId,
    required String buyerName,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    try {
      DocumentReference docRef = _db.collection('orders').doc();

      await docRef.set({
        'id': docRef.id,
        'name': name,
        'price': price,
        'category': category.toUpperCase(),
        'description': description,
        'location': location,
        'imagePath': imagePath,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'buyerId': buyerId,
        'buyerName': buyerName,
        'status': 'Processing', // Status mula-mula
        'createdAt': FieldValue.serverTimestamp(),
      });

      // TRIGGER NOTIFIKASI: Kirim pesan khusus ke halaman penjual bahwa barangnya terbeli
      await createNotification(
        receiverId: sellerId,
        title: 'Produk Anda Terjual! 🎉',
        message:
            '$buyerName telah membeli "$name" Anda seharga $price. Segera cek detail transaksi Anda!',
      );

      onSuccess();
    } catch (e) {
      onError('Gagal melakukan pembelian: $e');
    }
  }

  /// Aliran data memuat riwayat produk yang dibeli user (Past Buys Screen)
  Stream<QuerySnapshot> getPastBuysStream(String userId) {
    return _db
        .collection('orders')
        .where('buyerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Aliran data memuat riwayat produk jualan user yang dibeli orang lain (Past Sells Screen)
  Stream<QuerySnapshot> getPastSellsStream(String userId) {
    return _db
        .collection('orders') // PERBAIKAN: Mengganti 'orders" menjadi 'orders'
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Memperbarui status pesanan mahasiswa (Processing -> Completed / Cancelled)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Gagal memperbarui status transaksi: $e';
    }
  }
}

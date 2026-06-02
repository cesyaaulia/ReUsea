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

  /// Mengunggah satu gambar dagangan ke Firebase Storage dalam bentuk format byte
  Future<String> uploadProductImage(
    Uint8List imageBytes,
    String productId, {
    int index = 0,
  }) async {
    try {
      // Setiap foto diberi nama unik berdasarkan productId dan index
      Reference ref = _storage
          .ref()
          .child('products')
          .child('${productId}_$index.jpg');
      UploadTask uploadTask = ref.putData(imageBytes);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Gagal mengunggah foto produk: $e';
    }
  }

  /// Mengunggah multiple gambar produk dan mengembalikan list URL
  Future<List<String>> uploadProductImages(
    List<Uint8List> imageBytesList,
    String productId,
  ) async {
    List<String> urls = [];
    for (int i = 0; i < imageBytesList.length; i++) {
      String url = await uploadProductImage(
        imageBytesList[i],
        productId,
        index: i,
      );
      urls.add(url);
    }
    return urls;
  }

  /// Mengunggah item dagangan baru ke Firestore beserta trigger notifikasi global
  Future<void> uploadProduct({
    required String name,
    required String price,
    required String category,
    required String description,
    required String location,
    required String sellerId,
    required String condition,
    required List<Uint8List>? imageBytesList,
    // Legacy support: masih terima imageBytes tunggal
    Uint8List? imageBytes,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    try {
      DocumentReference docRef = _db.collection('products').doc();
      List<String> imageUrls = [];
      String mainImageUrl = 'assets/images/profile_placeholder.png';

      // Upload multi-foto jika ada
      if (imageBytesList != null && imageBytesList.isNotEmpty) {
        imageUrls = await uploadProductImages(imageBytesList, docRef.id);
        mainImageUrl = imageUrls.first;
      } else if (imageBytes != null) {
        // Fallback: single image (backward-compatible)
        mainImageUrl = await uploadProductImage(imageBytes, docRef.id);
        imageUrls = [mainImageUrl];
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
        'condition': condition,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'sellerPhoto': sellerPhoto,
        'imagePath': mainImageUrl, // Backward-compatible: foto utama
        'imageUrls': imageUrls, // Array semua foto produk
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
    required String condition,
    required List<Uint8List>? newImageBytesList,
    required List<String> existingImageUrls,
    // Legacy support
    Uint8List? newImageBytes,
    String? existingImageUrl,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    try {
      List<String> finalImageUrls = List<String>.from(existingImageUrls);

      // Upload foto baru (jika ada) dan append ke list
      if (newImageBytesList != null && newImageBytesList.isNotEmpty) {
        int startIndex = finalImageUrls.length;
        for (int i = 0; i < newImageBytesList.length; i++) {
          String url = await uploadProductImage(
            newImageBytesList[i],
            productId,
            index: startIndex + i,
          );
          finalImageUrls.add(url);
        }
      } else if (newImageBytes != null) {
        // Fallback: single image update
        String url = await uploadProductImage(newImageBytes, productId);
        finalImageUrls = [url];
      }

      String mainImageUrl = finalImageUrls.isNotEmpty
          ? finalImageUrls.first
          : (existingImageUrl ?? 'assets/images/profile_placeholder.png');

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
        'condition': condition,
        'imagePath': mainImageUrl,
        'imageUrls': finalImageUrls,
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
      // Coba hapus document dulu
      final doc = await _db.collection('products').doc(productId).get();
      final data = doc.data();

      await _db.collection('products').doc(productId).delete();

      // Hapus semua foto terkait di Storage
      if (data != null && data['imageUrls'] != null) {
        List<String> urls = List<String>.from(data['imageUrls']);
        for (int i = 0; i < urls.length; i++) {
          try {
            await _storage
                .ref()
                .child('products')
                .child('${productId}_$i.jpg')
                .delete();
          } catch (_) {
            // Lanjut jika foto tertentu gagal dihapus
          }
        }
      }
      // Fallback: hapus foto lama format single
      try {
        await _storage
            .ref()
            .child('products')
            .child('$productId.jpg')
            .delete();
      } catch (_) {
        // Tidak perlu error jika file tidak ditemukan
      }
    } catch (e) {
      print('Info: Gagal menghapus produk atau fotonya: $e');
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
        .collection('orders')
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

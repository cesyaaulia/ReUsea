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
  Future<void> createNotification({
    required String receiverId,
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

  Stream<QuerySnapshot> getUnreadNotificationsStream(String userId) {
    return _db
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots();
  }

  // ====================================================================
  // 2. MANAJEMEN PRODUK KAMPUS (PRODUCT LOGIC)
  // ====================================================================
  Future<String> uploadProductImage(
    Uint8List imageBytes,
    String productId, {
    int index = 0,
  }) async {
    try {
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

  Future<void> uploadProduct({
    required String name,
    required String price,
    required String category,
    required String description,
    required String location,
    required String sellerId,
    required String condition,
    required List<Uint8List>? imageBytesList,
    Uint8List? imageBytes,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    try {
      DocumentReference docRef = _db.collection('products').doc();
      List<String> imageUrls = [];
      String mainImageUrl = 'assets/images/profile_placeholder.png';

      if (imageBytesList != null && imageBytesList.isNotEmpty) {
        imageUrls = await uploadProductImages(imageBytesList, docRef.id);
        mainImageUrl = imageUrls.first;
      } else if (imageBytes != null) {
        mainImageUrl = await uploadProductImage(imageBytes, docRef.id);
        imageUrls = [mainImageUrl];
      }

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
        'imagePath': mainImageUrl,
        'imageUrls': imageUrls,
        'status': 'Available',
        'createdAt': FieldValue.serverTimestamp(),
      });

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
    Uint8List? newImageBytes,
    String? existingImageUrl,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    try {
      List<String> finalImageUrls = List<String>.from(existingImageUrls);

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

  Future<void> deleteProduct(String productId) async {
    try {
      final doc = await _db.collection('products').doc(productId).get();
      final data = doc.data();

      await _db.collection('products').doc(productId).delete();

      if (data != null && data['imageUrls'] != null) {
        List<String> urls = List<String>.from(data['imageUrls']);
        for (int i = 0; i < urls.length; i++) {
          try {
            await _storage
                .ref()
                .child('products')
                .child('${productId}_$i.jpg')
                .delete();
          } catch (_) {}
        }
      }
    } catch (e) {
      print('Info: Gagal menghapus produk atau fotonya: $e');
    }
  }

  Stream<QuerySnapshot> getProductsStream() {
    return _db
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ====================================================================
  // 3. MANAJEMEN ALUR TRANSAKSI MAHASISWA (ORDER LOGIC)
  // ====================================================================

  /// MERGE SUCCESS: Membuat order nota lengkap dengan data tracking maps delivery koordinat & set status barang 'Processing'
  Future<void> placeOrder({
    required String productId,
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
    String buyerAddress = '',
    double buyerLat = 0,
    double buyerLng = 0,
    String deliveryService = '',
    double deliveryFee = 0,
    double distanceKm = 0,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    try {
      DocumentReference docRef = _db.collection('orders').doc();

      await docRef.set({
        'id': docRef.id,
        'productId': productId,
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
        'buyerAddress': buyerAddress,
        'buyerLat': buyerLat,
        'buyerLng': buyerLng,
        'deliveryService': deliveryService,
        'deliveryFee': deliveryFee,
        'distanceKm': distanceKm,
        'status': 'Processing',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Sembunyikan produk sementara dari HomePage listing pasar
      await _db.collection('products').doc(productId).update({
        'status': 'Processing',
      });

      await createNotification(
        receiverId: sellerId,
        title: 'Produk Anda Terjual! 🎉',
        message:
            '$buyerName telah membeli "$name" Anda seharga $price. Pengiriman via $deliveryService. Segera cek detail transaksi Anda!',
      );

      onSuccess();
    } catch (e) {
      onError('Gagal melakukan pembelian: $e');
    }
  }

  Stream<QuerySnapshot> getPastBuysStream(String userId) {
    return _db
        .collection('orders')
        .where('buyerId', isEqualTo: userId)
        .snapshots();
  }

  Stream<QuerySnapshot> getPastSellsStream(String userId) {
    return _db
        .collection('orders')
        .where('sellerId', isEqualTo: userId)
        .snapshots();
  }

  /// MERGE SUCCESS: Manajemen aksi update (Completed -> Hapus listing permanen & naikkan angka profile / Cancelled -> Pajang kembali)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      DocumentSnapshot orderSnap = await _db
          .collection('orders')
          .doc(orderId)
          .get();
      if (!orderSnap.exists) throw 'Data transaksi tidak ditemukan!';

      var orderData = orderSnap.data() as Map<String, dynamic>;
      String productId = orderData['productId'] ?? '';
      String buyerId = orderData['buyerId'] ?? '';
      String sellerId = orderData['sellerId'] ?? '';

      await _db.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (newStatus == 'Completed') {
        // Hapus permanen dari koleksi products beranda
        if (productId.isNotEmpty) {
          await _db.collection('products').doc(productId).update({
            'status': 'Completed',
          });
        }
        // Naikkan stat bought pembeli
        if (buyerId.isNotEmpty) {
          await _db.collection('users').doc(buyerId).update({
            'bought': FieldValue.increment(1),
          });
        }
        // Naikkan stat solds penjual
        if (sellerId.isNotEmpty) {
          await _db.collection('users').doc(sellerId).update({
            'solds': FieldValue.increment(1),
          });
        }
      } else if (newStatus == 'Cancelled') {
        // Jika batal, kembalikan status produk menjadi Available agar mejeng lagi di Home
        if (productId.isNotEmpty) {
          await _db.collection('products').doc(productId).update({
            'status': 'Available',
          });
        }
      }
    } catch (e) {
      throw 'Gagal memperbarui status transaksi: $e';
    }
  }

  // ====================================================================
  // 4. MANAJEMEN CHAT REAL-TIME (CHAT LOGIC)
  // ====================================================================
  Future<String> getOrCreateChatRoom({
    required String buyerId,
    required String buyerName,
    required String buyerPhoto,
    required String sellerId,
    required String sellerName,
    required String sellerPhoto,
  }) async {
    String roomId = buyerId.compareTo(sellerId) < 0
        ? '${buyerId}_$sellerId'
        : '${sellerId}_$buyerId';

    DocumentReference roomRef = _db.collection('chat_rooms').doc(roomId);
    DocumentSnapshot doc = await roomRef.get();

    if (!doc.exists) {
      await roomRef.set({
        'id': roomId,
        'participants': [buyerId, sellerId],
        'participantNames': {buyerId: buyerName, sellerId: sellerName},
        'participantPhotos': {buyerId: buyerPhoto, sellerId: sellerPhoto},
        'lastMessage': '',
        'lastMessageSenderId': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {buyerId: 0, sellerId: 0},
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await roomRef.update({
        'participantNames.$buyerId': buyerName,
        'participantNames.$sellerId': sellerName,
        'participantPhotos.$buyerId': buyerPhoto,
        'participantPhotos.$sellerId': sellerPhoto,
      });
    }
    return roomId;
  }

  Future<String> uploadChatFile({
    required Uint8List fileBytes,
    required String roomId,
    required String fileName,
  }) async {
    try {
      Reference ref = _storage
          .ref()
          .child('chats')
          .child(roomId)
          .child(fileName);
      UploadTask uploadTask = ref.putData(fileBytes);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Gagal mengunggah file ke chat: $e';
    }
  }

  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
    String? imageUrl,
    String? videoUrl,
  }) async {
    if (text.trim().isEmpty && imageUrl == null && videoUrl == null) return;

    DocumentReference messageRef = _db
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .doc();

    await messageRef.set({
      'id': messageRef.id,
      'senderId': senderId,
      'senderName': senderName,
      'text': text.trim(),
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    DocumentReference roomRef = _db.collection('chat_rooms').doc(roomId);
    DocumentSnapshot roomSnapshot = await roomRef.get();
    if (roomSnapshot.exists) {
      Map<String, dynamic> data = roomSnapshot.data() as Map<String, dynamic>;
      List<dynamic> participants = data['participants'] ?? [];
      String receiverId = participants.firstWhere(
        (p) => p != senderId,
        orElse: () => '',
      );

      String previewText = text.trim();
      if (previewText.isEmpty) {
        if (imageUrl != null)
          previewText = '📷 Foto';
        else if (videoUrl != null)
          previewText = '🎥 Video';
      }

      Map<String, dynamic> updateData = {
        'lastMessage': previewText,
        'lastMessageSenderId': senderId,
        'lastMessageTime': FieldValue.serverTimestamp(),
      };

      if (receiverId.isNotEmpty) {
        updateData['unreadCount.$receiverId'] = FieldValue.increment(1);
      }

      await roomRef.update(updateData);
    }
  }

  Future<void> resetUnreadCount({
    required String roomId,
    required String userId,
  }) async {
    try {
      await _db.collection('chat_rooms').doc(roomId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      print('Gagal reset unread count: $e');
    }
  }

  Stream<QuerySnapshot> getChatRoomsStream(String userId) {
    return _db
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .snapshots();
  }

  Stream<QuerySnapshot> getMessagesStream(String roomId) {
    return _db
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}

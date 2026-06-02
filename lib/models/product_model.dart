import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String category;
  final String name;
  final String price;
  final String imagePath; // Foto utama (backward-compatible)
  final List<String> imageUrls; // Semua foto produk (multi-foto)
  final String time;
  final String description;
  final String location;
  final String sellerId;
  final String sellerName;
  final String sellerPhoto;
  final String condition; // Kondisi barang: "Baru" atau "Bekas"

  Product({
    required this.id,
    required this.category,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.imageUrls,
    required this.time,
    required this.description,
    required this.location,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhoto,
    required this.condition,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    Timestamp? createdAt = map['createdAt'] as Timestamp?;

    // Backward compatibility: ambil imageUrls dari Firestore,
    // jika tidak ada, fallback ke imagePath tunggal
    List<String> urls = [];
    if (map['imageUrls'] != null && map['imageUrls'] is List) {
      urls = List<String>.from(map['imageUrls']);
    }
    String mainImage = map['imagePath'] ?? '';
    // Jika imageUrls kosong tapi imagePath ada, pakai imagePath sebagai satu-satunya foto
    if (urls.isEmpty && mainImage.isNotEmpty) {
      urls = [mainImage];
    }

    return Product(
      id: map['id'] ?? '',
      category: map['category'] ?? 'LAINNYA',
      name: map['name'] ?? 'No Name',
      price: map['price'] ?? 'Rp 0',
      imagePath: mainImage,
      imageUrls: urls,
      time: _calculateTimeAgo(createdAt),
      description: map['description'] ?? 'Tidak ada deskripsi.',
      location: map['location'] ?? 'UNESA',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? 'Mahasiswa UNESA',
      sellerPhoto: map['sellerPhoto'] ?? '',
      condition: map['condition'] ?? 'Bekas', // Default "Bekas" untuk produk lama
    );
  }

  static String _calculateTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Baru saja';
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    if (difference.inDays >= 30) {
      return '${(difference.inDays / 30).floor()} bulan lalu';
    }
    if (difference.inDays >= 7) {
      return '${(difference.inDays / 7).floor()} minggu lalu';
    }
    if (difference.inDays > 0) return '${difference.inDays} hari lalu';
    if (difference.inHours > 0) return '${difference.inHours} jam lalu';
    if (difference.inMinutes > 0) return '${difference.inMinutes} menit lalu';
    return 'Baru saja';
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String category;
  final String name;
  final String price;
  final String imagePath;
  final String time;
  final String description;
  final String location;
  final String sellerId; // PERBAIKAN: Tambahkan variabel sellerId
  final String sellerName;
  final String sellerPhoto;

  Product({
    required this.id,
    required this.category,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.time,
    required this.description,
    required this.location,
    required this.sellerId, // PERBAIKAN: Tambahkan di constructor
    required this.sellerName,
    required this.sellerPhoto,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    Timestamp? createdAt = map['createdAt'] as Timestamp?;

    return Product(
      id: map['id'] ?? '',
      category: map['category'] ?? 'OTHER',
      name: map['name'] ?? 'No Name',
      price: map['price'] ?? 'Rp 0',
      imagePath: map['imagePath'] ?? '',
      time: _calculateTimeAgo(createdAt),
      description: map['description'] ?? 'Tidak ada deskripsi.',
      location: map['location'] ?? 'UNESA',
      sellerId:
          map['sellerId'] ??
          '', // PERBAIKAN: Ambil data sellerId dari Firestore
      sellerName: map['sellerName'] ?? 'Mahasiswa UNESA',
      sellerPhoto: map['sellerPhoto'] ?? '',
    );
  }

  static String _calculateTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Baru saja';
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    if (difference.inDays >= 30)
      return '${(difference.inDays / 30).floor()} bulan lalu';
    if (difference.inDays >= 7)
      return '${(difference.inDays / 7).floor()} minggu lalu';
    if (difference.inDays > 0) return '${difference.inDays} hari lalu';
    if (difference.inHours > 0) return '${difference.inHours} jam lalu';
    if (difference.inMinutes > 0) return '${difference.inMinutes} menit lalu';
    return 'Baru saja';
  }
}

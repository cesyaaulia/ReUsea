import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import 'detail_page.dart';
import 'notification_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedCategory = "All Items";
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4), // Warna krem background figma
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'ReUsea',
          style: TextStyle(
            color: Color(0xFFBC8E52),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          // ========================================================
          // LIVE NOTIFICATION BADGE STREAMING
          // ========================================================
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;

              if (snapshot.hasData) {
                // Filter lokal untuk menghitung notifikasi akun pribadi atau publik ('ALL')
                var filteredDocs = snapshot.data!.docs.where((doc) {
                  String receiverId = doc['receiverId'] ?? '';
                  return receiverId == currentUserId || receiverId == 'ALL';
                }).toList();

                unreadCount = filteredDocs.length;
              }

              return IconButton(
                icon: Badge(
                  label: Text(unreadCount.toString()),
                  isLabelVisible: unreadCount > 0,
                  backgroundColor: Colors.redAccent,
                  child: const Icon(
                    Icons.notifications_none_outlined,
                    color: Colors.black,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationPage(),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. BAR PENCARIAN (SEARCH BAR)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search preloved items...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // 2. HORIZONTAL FILTER CHIPS BAR
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip("All Items"),
                  _buildCategoryChip("Books"),
                  _buildCategoryChip("Electronics"),
                  _buildCategoryChip("Fashion"),
                ],
              ),
            ),
            const SizedBox(height: 25),

            const Text(
              'Fresh Listings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // 3. DAFTAR GRID PRODUK UTAMA
            _buildGrid(),
          ],
        ),
      ),
    );
  }

  // Widget Pembuat Item Filter Chip Kategori
  Widget _buildCategoryChip(String label) {
    bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        child: Chip(
          label: Text(label),
          backgroundColor: isSelected ? const Color(0xFFBC8E52) : Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  // Widget Loader Pengumpul Grid dari Server Firestore (Real-Time Stream)
  Widget _buildGrid() {
    double screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount = 2;
    double aspectRatio =
        0.60; // PERBAIKAN: Dilonggarkan dari 0.64 ke 0.60 untuk layar HP kecil agar teks aman

    // KALIBRASI RASIO RESPONSIVE AGAR AMAN DARI OVERFLOW DI SEMUA RESOLUSI
    if (screenWidth > 1200) {
      crossAxisCount = 5;
      aspectRatio =
          0.70; // Dioptimalkan dari 0.78 ke 0.70 (ruang teks web lebih lega)
    } else if (screenWidth > 800) {
      crossAxisCount = 4;
      aspectRatio = 0.68; // Dioptimalkan dari 0.75 ke 0.68
    } else if (screenWidth > 600) {
      crossAxisCount = 3;
      aspectRatio = 0.65; // Dioptimalkan dari 0.72 ke 0.65
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(color: Color(0xFFBC8E52)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text(
                "Belum ada barang jualan hari ini.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        var productsDocs = snapshot.data!.docs;

        if (_selectedCategory != "All Items") {
          productsDocs = productsDocs.where((doc) {
            return doc['category'].toString().toUpperCase() ==
                _selectedCategory.toUpperCase();
          }).toList();
        }

        if (_searchQuery.isNotEmpty) {
          productsDocs = productsDocs.where((doc) {
            return doc['name'].toString().toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
          }).toList();
        }

        if (productsDocs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text(
                "Barang jualan tidak ditemukan.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: productsDocs.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            var productData =
                productsDocs[index].data() as Map<String, dynamic>;
            Product product = Product.fromMap(productData);

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailPage(product: product),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                          child: product.imagePath.startsWith('http')
                              ? Image.network(
                                  product.imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                )
                              : Image.asset(
                                  product.imagePath.isNotEmpty
                                      ? product.imagePath
                                      : 'assets/images/profile_placeholder.png',
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),

                    // SEKTOR INFORMASI TEXT (DIBERI PADDING DAN UKURAN AMAN)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.category,
                            style: const TextStyle(
                              color: Color(0xFFBC8E52),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                product.price,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                product.time,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

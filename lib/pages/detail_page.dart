import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reusea/services/database_service.dart';
import 'package:reusea/utils/page_transitions.dart';
import '../models/product_model.dart';
import 'past_buys_page.dart';

class DetailPage extends StatefulWidget {
  final Product product;

  const DetailPage({super.key, required this.product});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isBuying = false;

  // =============================================
  // IMAGE CAROUSEL STATE
  // =============================================
  int _currentImageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // FUNGSI PROSES PEMBELIAN BARANG
  void _handleBuyItem() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Proteksi: Mencegah mahasiswa membeli barang dagangannya sendiri
    if (widget.product.sellerId == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Anda tidak bisa membeli barang jualan Anda sendiri!"),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // Tampilkan Dialog Konfirmasi Pembelian (Deal via COD)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Pembelian"),
        content: Text(
          "Apakah Anda yakin ingin membeli '${widget.product.name}'? Sistem akan mencatat pesanan Anda.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog

              setState(() => _isBuying = true);

              String buyerName =
                  currentUser.displayName ?? currentUser.email!.split('@')[0];

              // Eksekusi penulisan data ke Firestore 'orders'
              await _dbService.placeOrder(
                name: widget.product.name,
                price: widget.product.price,
                category: widget.product.category,
                description: widget.product.description,
                location: widget.product.location,
                imagePath: widget.product.imagePath,
                sellerId: widget.product.sellerId,
                sellerName: widget.product.sellerName,
                buyerId: currentUser.uid,
                buyerName: buyerName,
                onSuccess: () {
                  setState(() => _isBuying = false);

                  // Beri notifikasi sukses
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Pembelian berhasil! Menuju riwayat transaksi...",
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Tendang uploader langsung ke halaman PastBuysPage untuk melacak status pesanan
                  Navigator.pushReplacement(
                    context,
                    SlideFadeRightRoute(
                      page: const PastBuysPage(),
                    ),
                  );
                },
                onError: (errorMessage) {
                  setState(() => _isBuying = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                },
              );
            },
            child: const Text(
              "Beli Sekarang",
              style: TextStyle(
                color: Color(0xFFBC8E52),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ambil list semua foto produk
    final List<String> imageUrls = widget.product.imageUrls;
    final int totalImages = imageUrls.isNotEmpty ? imageUrls.length : 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Detail Barang",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isBuying
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFBC8E52)),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =============================================
                  // IMAGE CAROUSEL (Swipe ala Shopee)
                  // =============================================
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: imageUrls.isNotEmpty
                            ? PageView.builder(
                                controller: _pageController,
                                itemCount: totalImages,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentImageIndex = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  String url = imageUrls[index];
                                  return Container(
                                    color: const Color(0xFFF9F7F4),
                                    child: url.startsWith('http')
                                        ? Image.network(
                                            url,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) =>
                                                const Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                size: 50,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          )
                                        : Image.asset(
                                            'assets/images/profile_placeholder.png',
                                            fit: BoxFit.cover,
                                          ),
                                  );
                                },
                              )
                            : Container(
                                color: const Color(0xFFF9F7F4),
                                child: widget.product.imagePath
                                        .startsWith('http')
                                    ? Image.network(
                                        widget.product.imagePath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) =>
                                            const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    : Image.asset(
                                        'assets/images/profile_placeholder.png',
                                        fit: BoxFit.cover,
                                      ),
                              ),
                      ),
                      // Counter badge (1/3, 2/3, etc.)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${_currentImageIndex + 1}/$totalImages",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                      // Dot indicators
                      if (totalImages > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(totalImages, (index) {
                              bool isActive = index == _currentImageIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                width: isActive ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFFBC8E52)
                                      : Colors.white.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),

                  // =============================================
                  // DETAIL INFO
                  // =============================================
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Kategori + Kondisi
                            Row(
                              children: [
                                Text(
                                  widget.product.category,
                                  style: const TextStyle(
                                    color: Color(0xFFBC8E52),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Badge kondisi barang
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        widget.product.condition == 'Baru'
                                            ? const Color(0xFFE8F5E9)
                                            : const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.product.condition,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          widget.product.condition == 'Baru'
                                              ? const Color(0xFF2E7D32)
                                              : const Color(0xFFE65100),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "Uploaded ${widget.product.time}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.product.price,
                          style: const TextStyle(
                            fontSize: 22,
                            color: Color(0xFFBC8E52),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 40),

                        const Text(
                          "Deskripsi",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.product.description,
                          style: TextStyle(
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 30),

                        const Text(
                          "Lokasi Pengambilan",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F7F4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Color(0xFFFDEEDC),
                                child: Icon(
                                  Icons.location_on,
                                  color: Color(0xFFBC8E52),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.product.location,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      "Surabaya, East Java",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),
                        const Divider(height: 1),
                        const SizedBox(height: 30),

                        const Text(
                          "Informasi Penjual",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),

                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.product.sellerId)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: LinearProgressIndicator(
                                  color: Color(0xFFBC8E52),
                                ),
                              );
                            }

                            var userData =
                                snapshot.data?.data() as Map<String, dynamic>?;
                            String sellerName =
                                userData?['name'] ?? widget.product.sellerName;
                            String sellerPhoto =
                                userData?['photoUrl'] ??
                                widget.product.sellerPhoto;

                            return Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: const Color(0xFFF0F0F0),
                                  backgroundImage: sellerPhoto.isNotEmpty
                                      ? NetworkImage(sellerPhoto)
                                      : null,
                                  child: sellerPhoto.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.grey,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sellerName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.verified,
                                            color: Colors.green,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            "Verified UNESA Student",
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chat_outlined),
                label: const Text("Chat"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFBC8E52),
                  side: const BorderSide(color: Color(0xFFBC8E52)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton(
                onPressed: _handleBuyItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBC8E52),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Beli Sekarang",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reusea/services/database_service.dart';
import 'package:reusea/utils/page_transitions.dart';
import '../models/product_model.dart';
import 'chat_detail_page.dart';
import 'checkout_page.dart';

class DetailPage extends StatefulWidget {
  final Product product;

  const DetailPage({super.key, required this.product});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;


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

  // FUNGSI NAVIGASI KE CHAT DETAIL (P2P CHAT)
  void _navigateToChat({List<String>? initialSuggestions}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Silakan login terlebih dahulu untuk chat dengan penjual."),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // Proteksi: Mencegah chat ke diri sendiri
    if (widget.product.sellerId == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Anda tidak bisa chat dengan diri sendiri!"),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // Tampilkan loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1A2235),
        ),
      ),
    );

    try {
      String buyerName = currentUser.displayName ?? currentUser.email!.split('@')[0];
      String buyerPhoto = currentUser.photoURL ?? '';

      // Buat atau ambil room chat
      String roomId = await _dbService.getOrCreateChatRoom(
        buyerId: currentUser.uid,
        buyerName: buyerName,
        buyerPhoto: buyerPhoto,
        sellerId: widget.product.sellerId,
        sellerName: widget.product.sellerName,
        sellerPhoto: widget.product.sellerPhoto,
      );

      // Tutup loading
      if (mounted) Navigator.pop(context);

      // Arahkan ke halaman detail chat
      if (mounted) {
        Navigator.push(
          context,
          SlideFadeRightRoute(
            page: ChatDetailPage(
              roomId: roomId,
              peerId: widget.product.sellerId,
              peerName: widget.product.sellerName,
              peerPhoto: widget.product.sellerPhoto,
              product: widget.product,
              initialSuggestions: initialSuggestions,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal membuka chat: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.black),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            tooltip: "Kembali ke Beranda",
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 700) {
                  // Desktop/Web side-by-side layout (scrolling together)
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Side: Image Carousel
                      Expanded(
                        flex: 5,
                        child: _buildImageCarousel(imageUrls, totalImages),
                      ),
                      const SizedBox(width: 24),
                      // Right Side: Details Info
                      Expanded(
                        flex: 6,
                        child: _buildProductDetailsInfo(),
                      ),
                    ],
                  );
                } else {
                  // Mobile stacked layout
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageCarousel(imageUrls, totalImages),
                      _buildProductDetailsInfo(),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _navigateToChat(
                          initialSuggestions: [
                            "Barangnya masih ada nggak kak?",
                            "Kondisi barangnya gimana kak?",
                            "Boleh nego nggak kak?",
                            "Bisa COD di sekitar UNESA Lidah Wetan?",
                            "Bisa COD di sekitar UNESA Ketintang?",
                            "Ada minus lain yang belum ditulis di deskripsi?",
                            "Harga pasnya berapa ya kak?",
                          ],
                        );
                      },
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text("Tanya Penjual"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A2235),
                        side: const BorderSide(color: Color(0xFF1A2235)),
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
                      onPressed: () {
                        final currentUser = _auth.currentUser;
                        if (currentUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Silakan login terlebih dahulu."),
                              backgroundColor: Colors.orangeAccent,
                            ),
                          );
                          return;
                        }
                        if (widget.product.sellerId == currentUser.uid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Anda tidak bisa membeli barang sendiri!"),
                              backgroundColor: Colors.orangeAccent,
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          SlideUpRoute(
                            page: CheckoutPage(product: widget.product),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A2235),
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
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> imageUrls, int totalImages) {
    return Stack(
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
                      color: const Color(0xFFF2F1EE),
                      child: url.startsWith('http')
                          ? Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : Image.asset(
                              url.isNotEmpty ? url : 'assets/images/profile_placeholder.png',
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                    );
                  },
                )
              : Container(
                  color: const Color(0xFFF2F1EE),
                  child: widget.product.imagePath.startsWith('http')
                      ? Image.network(
                          widget.product.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Image.asset(
                          widget.product.imagePath.isNotEmpty ? widget.product.imagePath : 'assets/images/profile_placeholder.png',
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
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
              style: const TextStyle(color: Colors.white, fontSize: 12),
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
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF1A2235)
                        : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildProductDetailsInfo() {
    return Padding(
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
                      color: Color(0xFF1A2235),
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
                      color: widget.product.condition == 'Baru'
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.product.condition,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: widget.product.condition == 'Baru'
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
              color: Color(0xFF1A2235),
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
              color: const Color(0xFFF2F1EE),
              borderRadius: BorderRadius.circular(15),
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

          widget.product.sellerId.isEmpty
              ? _buildSellerRow(widget.product.sellerName, widget.product.sellerPhoto)
              : FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.product.sellerId)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
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
                        userData?['photoUrl'] ?? widget.product.sellerPhoto;

                    return _buildSellerRow(sellerName, sellerPhoto);
                  },
                ),
          const SizedBox(height: 30),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.home, color: Color(0xFF1A2235)),
              label: const Text(
                "Kembali ke Beranda",
                style: TextStyle(
                  color: Color(0xFF1A2235),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                backgroundColor: const Color(0xFFF2F1EE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerRow(String sellerName, String sellerPhoto) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
  }
}

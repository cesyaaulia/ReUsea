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

  // LOGIKA MULTI-FOTO: Menyimpan indeks halaman carousel saat ini
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

  void _navigateToChat({List<String>? initialSuggestions}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Silakan login terlebih dahulu untuk chat dengan penjual.",
          ),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    if (widget.product.sellerId == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Anda tidak bisa chat dengan diri sendiri!"),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A2235)),
      ),
    );

    try {
      String buyerName =
          currentUser.displayName ?? currentUser.email!.split('@')[0];
      String buyerPhoto = currentUser.photoURL ?? '';

      String roomId = await _dbService.getOrCreateChatRoom(
        buyerId: currentUser.uid,
        buyerName: buyerName,
        buyerPhoto: buyerPhoto,
        sellerId: widget.product.sellerId,
        sellerName: widget.product.sellerName,
        sellerPhoto: widget.product.sellerPhoto,
      );

      if (mounted) Navigator.pop(context);

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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product.id)
          .snapshots(),
      builder: (context, productSnapshot) {
        String currentStatus = 'Available';

        // Memuat daftar fallback data awal dari memory data model lokal
        List<String> imageUrls = widget.product.imageUrls;
        String mainImagePath = widget.product.imagePath;
        String productName = widget.product.name;
        String productPrice = widget.product.price;
        String productCategory = widget.product.category;
        String productCondition = widget.product.condition;
        String productDescription = widget.product.description;
        String productLocation = widget.product.location;
        String productTime = widget.product.time;

        if (productSnapshot.hasData && productSnapshot.data!.exists) {
          var data = productSnapshot.data!.data() as Map<String, dynamic>;
          if (data.containsKey('status')) {
            currentStatus = data['status'];
          }
          if (data.containsKey('imageUrls') && data['imageUrls'] != null) {
            imageUrls = List<String>.from(data['imageUrls']);
          }
          mainImagePath = data['imagePath'] ?? mainImagePath;
          productName = data['name'] ?? productName;
          productPrice = data['price'] ?? productPrice;
          productCategory = data['category'] ?? productCategory;
          productCondition = data['condition'] ?? productCondition;
          productDescription = data['description'] ?? productDescription;
          productLocation = data['location'] ?? productLocation;
        }

        final int totalImages = imageUrls.isNotEmpty ? imageUrls.length : 1;
        bool isProductProcessing = currentStatus == 'Processing';

        // FUNGSI PEMBENTUK CAROUSEL MULTI-FOTO
        Widget buildImageCarousel() {
          return Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  color: const Color(0xFFF9F7F4),
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
                            return url.startsWith('http')
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
                                    'assets/images/profile_placeholder.png',
                                    fit: BoxFit.cover,
                                  );
                          },
                        )
                      : Container(
                          child: mainImagePath.startsWith('http')
                              ? Image.network(
                                  mainImagePath,
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
                                  'assets/images/profile_placeholder.png',
                                  fit: BoxFit.cover,
                                ),
                        ),
                ),
              ),
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
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF1A2235)
                              : Colors.white70,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          );
        }

        // FUNGSI PEMBENTUK DETAIL RINCIAN INFORMASI TEXT
        Widget buildProductDetailsInfo() {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      productCategory,
                      style: const TextStyle(
                        color: Color(0xFF1A2235),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Uploaded $productTime",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  productPrice,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Color(0xFF1A2235),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 40),
                const Text(
                  "Deskripsi",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  productDescription,
                  style: TextStyle(color: Colors.grey[700], height: 1.5),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Lokasi Pengambilan",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF1A2235)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productLocation,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
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
                  "Informasi Seller",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.product.sellerId)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: LinearProgressIndicator(
                          color: Color(0xFF1A2235),
                        ),
                      );
                    }
                    var userData =
                        snapshot.data?.data() as Map<String, dynamic>?;
                    String sName =
                        userData?['name'] ?? widget.product.sellerName;
                    String sPhoto =
                        userData?['photoUrl'] ?? widget.product.sellerPhoto;

                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xFFF0F0F0),
                          backgroundImage: sPhoto.isNotEmpty
                              ? NetworkImage(sPhoto)
                              : null,
                          child: sPhoto.isEmpty
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sName,
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
          );
        }

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
              "Item Detail",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [buildImageCarousel(), buildProductDetailsInfo()],
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
                    onPressed: isProductProcessing
                        ? null
                        : () {
                            _navigateToChat(
                              initialSuggestions: [
                                "Barangnya masih ada nggak kak?",
                                "Kondisi barangnya gimana kak?",
                                "Boleh nego nggak kak?",
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
                    onPressed: isProductProcessing
                        ? null
                        : () {
                            final currentUser = _auth.currentUser;
                            if (currentUser == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Silakan login terlebih dahulu.",
                                  ),
                                  backgroundColor: Colors.grey,
                                ),
                              );
                              return;
                            }
                            if (widget.product.sellerId == currentUser.uid) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Anda tidak bisa membeli barang sendiri!",
                                  ),
                                  backgroundColor: Colors.grey,
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
                      backgroundColor: isProductProcessing
                          ? Colors.grey
                          : const Color(0xFF1A2235),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isProductProcessing ? "On Processing" : "Beli Sekarang",
                      style: const TextStyle(
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
      },
    );
  }
}

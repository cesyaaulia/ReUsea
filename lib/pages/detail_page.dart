import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reusea/services/database_service.dart';
import 'package:reusea/utils/page_transitions.dart';
import 'package:reusea/utils/theme.dart';
import '../models/product_model.dart';
import 'chat_detail_page.dart';
import 'checkout_page.dart';
import 'seller_profile_page.dart';

class DetailPage extends StatefulWidget {
  final Product product;

  const DetailPage({super.key, required this.product});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
          content: Text("Silakan login terlebih dahulu untuk chat dengan penjual."),
          backgroundColor: AppTheme.secondaryBlue,
        ),
      );
      return;
    }

    if (widget.product.sellerId == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Anda tidak bisa chat dengan diri sendiri!"),
          backgroundColor: AppTheme.secondaryBlue,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
      ),
    );

    try {
      String buyerName = currentUser.displayName ?? currentUser.email!.split('@')[0];
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
            backgroundColor: AppTheme.coralPeach,
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

        // CAROUSEL MULTI-FOTO DENGAN RADIUS LEMBUT & INDIKATOR MODEREN
        Widget buildImageCarousel() {
          return Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.05,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F4F8),
                  ),
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
                                ? Image.network(url, fit: BoxFit.cover)
                                : Image.asset(
                                    url.isNotEmpty ? url : 'assets/images/profile_placeholder.png',
                                    fit: BoxFit.cover,
                                  );
                          },
                        )
                      : mainImagePath.startsWith('http')
                          ? Image.network(mainImagePath, fit: BoxFit.cover)
                          : Image.asset(
                              mainImagePath.isNotEmpty ? mainImagePath : 'assets/images/profile_placeholder.png',
                              fit: BoxFit.cover,
                            ),
                ),
              ),
              // Back Button overlay
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 20,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white70,
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.darkNavy, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
              // Index Indicator Pill
              Positioned(
                bottom: 24,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.darkNavy.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${_currentImageIndex + 1}/$totalImages",
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // Bubbly dots indicator
              if (totalImages > 1)
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(totalImages, (index) {
                      bool isActive = index == _currentImageIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 20 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.primaryBlue : Colors.white70,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.bgLight,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildImageCarousel(),
                // Product Detail Sheet (32px top radius)
                Transform.translate(
                  offset: const Offset(0, -16),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category & Time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                productCategory.toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Text(
                              "Diunggah $productTime",
                              style: TextStyle(
                                color: AppTheme.secondaryBlue.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Product Name
                        Text(
                          productName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.darkNavy,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Price & Condition
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              productPrice,
                              style: const TextStyle(
                                fontSize: 26,
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: productCondition == 'Baru' ? AppTheme.ecoTeal.withValues(alpha: 0.1) : AppTheme.sunsetOrange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                productCondition,
                                style: TextStyle(
                                  color: productCondition == 'Baru' ? AppTheme.ecoTeal : AppTheme.sunsetOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 48, thickness: 1, color: Color(0xFFF0F4F8)),
                        
                        // Description Section
                        const Text(
                          "Deskripsi",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          productDescription,
                          style: TextStyle(
                            color: AppTheme.secondaryBlue.withValues(alpha: 0.85),
                            fontSize: 14,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Location Section
                        const Text(
                          "Lokasi Pengambilan",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.bgLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.04),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Colors.white,
                                child: Icon(Icons.location_on_rounded, color: AppTheme.primaryBlue),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      productLocation,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppTheme.darkNavy,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Surabaya, East Java",
                                      style: TextStyle(
                                        color: AppTheme.secondaryBlue.withValues(alpha: 0.7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Seller Info
                        const Text(
                          "Informasi Seller",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
                        ),
                        const SizedBox(height: 14),
                        FutureBuilder<DocumentSnapshot?>(
                          future: widget.product.sellerId.isNotEmpty
                              ? FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.product.sellerId)
                                  .get()
                              : Future<DocumentSnapshot?>.value(null),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: LinearProgressIndicator(color: AppTheme.primaryBlue),
                              );
                            }
                            var userData = snapshot.data != null && snapshot.data!.exists
                                ? snapshot.data!.data() as Map<String, dynamic>?
                                : null;
                            String sName = userData?['name'] ?? widget.product.sellerName;
                            String sPhoto = userData?['photoUrl'] ?? widget.product.sellerPhoto;
                            int solds = userData?['solds'] ?? 0;
                            double averageRating = (userData?['averageRating'] ?? 0.0).toDouble();
                            int reviewsCount = userData?['reviewsCount'] ?? 0;

                            // Badge reputasi penjual
                            Widget badgeWidget = const SizedBox.shrink();
                            LinearGradient badgeGradient = const LinearGradient(colors: [Colors.grey, Colors.grey]);
                            String badgeText = '';

                            if (reviewsCount > 0) {
                              if (averageRating >= 4.8) {
                                badgeText = "🏆 Penjual Terpercaya";
                                badgeGradient = const LinearGradient(
                                  colors: [Color(0xFFFECA57), Color(0xFFFF9F43)], // Gold Gradient
                                );
                              } else if (averageRating >= 4.0) {
                                badgeText = "✅ Penjual Andal";
                                badgeGradient = const LinearGradient(
                                  colors: [Color(0xFF54A0FF), Color(0xFF2E86DE)], // Blue Gradient
                                );
                              } else if (averageRating >= 3.0) {
                                badgeText = "⚠️ Penjual Biasa";
                                badgeGradient = const LinearGradient(
                                  colors: [Color(0xFFFF9F43), Color(0xFFEE5253)], // Orange Gradient
                                );
                              } else {
                                badgeText = "🚨 Rating Rendah";
                                badgeGradient = const LinearGradient(
                                  colors: [Color(0xFFEE5253), Color(0xFFD32F2F)], // Red Gradient
                                );
                              }

                              badgeWidget = Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: badgeGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  badgeText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            } else {
                              badgeWidget = Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  "🆕 Penjual Baru",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                                  width: 1.5,
                                ),
                                boxShadow: AppTheme.softShadow(color: AppTheme.primaryBlue),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: AppTheme.bgLight,
                                        backgroundImage: sPhoto.isNotEmpty ? NetworkImage(sPhoto) : null,
                                        child: sPhoto.isEmpty ? const Icon(Icons.person_rounded, color: AppTheme.secondaryBlue) : null,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                                color: AppTheme.darkNavy,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  averageRating > 0 ? Icons.star_rounded : Icons.star_outline_rounded,
                                                  color: AppTheme.sunYellow,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  averageRating > 0 
                                                      ? "${averageRating.toStringAsFixed(1)} ($reviewsCount Ulasan)"
                                                      : "Belum ada ulasan",
                                                  style: const TextStyle(
                                                    color: AppTheme.secondaryBlue,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "$solds Barang Terjual",
                                            style: TextStyle(
                                              color: AppTheme.secondaryBlue.withValues(alpha: 0.8),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "Bergabung: ${userData?['joinedAt'] ?? 'Januari 2026'}",
                                            style: TextStyle(
                                              color: AppTheme.secondaryBlue.withValues(alpha: 0.6),
                                              fontSize: 10,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          badgeWidget,
                                        ],
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          if (widget.product.sellerId.isEmpty) return;
                                          Navigator.push(
                                            context,
                                            SlideFadeRightRoute(
                                              page: SellerProfilePage(
                                                sellerId: widget.product.sellerId,
                                                fallbackName: widget.product.sellerName,
                                                fallbackPhoto: widget.product.sellerPhoto,
                                              ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.06),
                                          foregroundColor: AppTheme.primaryBlue,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text(
                                          "Lihat Profil Penjual",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          "Produk Terkait",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
                        ),
                        const SizedBox(height: 14),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('products')
                              .where('category', isEqualTo: productCategory)
                              .limit(4)
                              .snapshots(),
                          builder: (context, relSnapshot) {
                            if (!relSnapshot.hasData) {
                              return const SizedBox.shrink();
                            }
                            var docs = relSnapshot.data!.docs.where((d) => d.id != widget.product.id).toList();
                            if (docs.isEmpty) {
                              return const Text(
                                "Tidak ada produk terkait lainnya.",
                                style: TextStyle(color: AppTheme.secondaryBlue, fontSize: 12),
                              );
                            }
                            return SizedBox(
                              height: 170,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  var docData = docs[index].data() as Map<String, dynamic>;
                                  Product prod = Product.fromMap(docData);
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        HeroFadeRoute(page: DetailPage(product: prod)),
                                      );
                                    },
                                    child: Container(
                                      width: 130,
                                      margin: const EdgeInsets.only(right: 14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                              child: prod.imagePath.startsWith('http')
                                                  ? Image.network(prod.imagePath, fit: BoxFit.cover, width: double.infinity)
                                                  : Image.asset(
                                                      prod.imagePath.isNotEmpty ? prod.imagePath : 'assets/images/profile_placeholder.png',
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                    ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  prod.name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.darkNavy),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  prod.price,
                                                  style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF0F4F8))),
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
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: const Text("Tanya Penjual"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: GestureDetector(
                    onTap: isProductProcessing
                        ? null
                        : () {
                            final currentUser = _auth.currentUser;
                            if (currentUser == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Silakan login terlebih dahulu."),
                                  backgroundColor: AppTheme.secondaryBlue,
                                ),
                              );
                              return;
                            }
                            if (widget.product.sellerId == currentUser.uid) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Anda tidak bisa membeli barang sendiri!"),
                                  backgroundColor: AppTheme.secondaryBlue,
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
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: isProductProcessing ? null : AppTheme.primaryGradient,
                        color: isProductProcessing ? Colors.grey : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isProductProcessing ? null : AppTheme.glowShadow(color: AppTheme.primaryBlue),
                      ),
                      child: Text(
                        isProductProcessing ? "Diproses" : "Beli Sekarang",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
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

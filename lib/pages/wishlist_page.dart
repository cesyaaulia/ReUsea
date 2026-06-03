import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reusea/models/product_model.dart';
import 'package:reusea/services/database_service.dart';
import 'package:reusea/utils/page_transitions.dart';
import 'package:reusea/utils/theme.dart';
import 'detail_page.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final String currentUserId = _auth.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Wishlist",
          style: GoogleFonts.lexend(
            color: AppTheme.darkNavy,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            boxShadow: AppTheme.softShadow(),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.darkNavy, size: 16),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: OceanGradientBackground(
        child: SafeArea(
          child: currentUserId.isEmpty
              ? _buildEmptyState()
              : StreamBuilder<QuerySnapshot>(
                  stream: _dbService.getWishlistStream(currentUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final productData = doc.data() as Map<String, dynamic>;
                        final product = Product.fromMap(productData);

                        return _buildWishlistCard(product, currentUserId);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildWishlistCard(Product product, String userId) {
    final bool isDonation = product.productType == "Donasi";
    final conditionColor = product.condition == 'Baru' ? AppTheme.ecoTeal : AppTheme.sunsetOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow(),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image Block
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: product.imagePath.startsWith('http')
                      ? Image.network(product.imagePath, fit: BoxFit.cover)
                      : Image.asset(
                          product.imagePath.isNotEmpty ? product.imagePath : 'assets/images/profile_placeholder.png',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              if (isDonation)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.ecoTeal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "🎁 Donasi",
                      style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Details Block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.category,
                        style: GoogleFonts.lexend(
                          color: AppTheme.primaryBlue,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _dbService.toggleWishlist(userId, product),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  product.name,
                  style: GoogleFonts.lexend(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.darkNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      product.price,
                      style: GoogleFonts.lexend(
                        color: isDonation ? AppTheme.ecoTeal : AppTheme.primaryBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "•  Penjual: ${product.sellerName}",
                      style: GoogleFonts.lexend(
                        color: AppTheme.secondaryBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Quick View Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            HeroFadeRoute(page: DetailPage(product: product)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.05),
                          foregroundColor: AppTheme.primaryBlue,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Quick View",
                          style: GoogleFonts.lexend(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Move to Cart Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _dbService.moveWishlistToCart(userId, product);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Berhasil dipindahkan ke keranjang!",
                                  style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: AppTheme.ecoTeal,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.shopping_cart_outlined, size: 12, color: Colors.white),
                        label: Text(
                          "Ke Keranjang",
                          style: GoogleFonts.lexend(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "💖",
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 24),
            Text(
              "Belum ada produk favorit.",
              style: GoogleFonts.lexend(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Simpan barang yang kamu suka untuk dilihat nanti.",
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 14,
                color: AppTheme.secondaryBlue,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

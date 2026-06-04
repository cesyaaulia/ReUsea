import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reusea/models/product_model.dart';
import 'package:reusea/services/auth_service.dart';
import 'package:reusea/services/database_service.dart';
import 'package:reusea/utils/page_transitions.dart';
import 'package:reusea/pages/edit_items_page.dart';
import 'package:reusea/utils/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyItemsPage extends StatefulWidget {
  const MyItemsPage({super.key});

  @override
  State<MyItemsPage> createState() => _MyItemsPageState();
}

class _MyItemsPageState extends State<MyItemsPage> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  // FUNGSI HAPUS BARANG
  void _confirmDelete(String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Hapus Barang?",
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
        ),
        content: Text(
          "Barang yang dihapus tidak bisa dikembalikan.",
          style: GoogleFonts.lexend(color: AppTheme.secondaryBlue),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Batal",
              style: GoogleFonts.lexend(color: AppTheme.secondaryBlue, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.coralPeach,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _dbService.deleteProduct(productId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Barang berhasil dihapus",
                        style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: AppTheme.ecoTeal,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal menghapus: $e"),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(
              "Hapus",
              style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = _authService.currentUser?.uid ?? "";

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: OceanGradientBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Items',
                        style: GoogleFonts.lexend(
                          color: AppTheme.darkNavy,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kelola barang jualanmu di kampus dengan mudah',
                        style: GoogleFonts.lexend(
                          color: AppTheme.secondaryBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Custom Tabs (Segmented control style)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.softShadow(),
                    ),
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 13),
                      unselectedLabelStyle: GoogleFonts.lexend(fontWeight: FontWeight.w600, fontSize: 13),
                      tabs: const [
                        Tab(text: "Active"),
                        Tab(text: "Sold"),
                        Tab(text: "Draft"),
                      ],
                    ),
                  ),
                ),

                // 3. TabBar View containing product streams
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _dbService.getProductsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                        );
                      }

                      var allProducts = snapshot.data?.docs ?? [];
                      // Filter by current user
                      var myProducts = allProducts.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        return (data['sellerId'] ?? '') == currentUserId;
                      }).toList();

                      // Categorize products based on status
                      var activeItems = myProducts.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        String status = data['status'] ?? 'Available';
                        return status == 'Available' || status == 'Processing';
                      }).toList();

                      var soldItems = myProducts.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        String status = data['status'] ?? 'Available';
                        return status == 'Completed' || status == 'Sold';
                      }).toList();

                      var draftItems = myProducts.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        String status = data['status'] ?? 'Available';
                        return status == 'Draft';
                      }).toList();

                      return TabBarView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildTabContent(activeItems, "Active"),
                          _buildTabContent(soldItems, "Sold"),
                          _buildTabContent(draftItems, "Draft"),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(List<QueryDocumentSnapshot> docs, String tabName) {
    if (docs.isEmpty) {
      return _buildEmptyState(tabName);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), // Bottom padding for floating nav
      itemCount: docs.length,
      itemBuilder: (context, index) {
        var doc = docs[index];
        var productData = doc.data() as Map<String, dynamic>;
        Product product = Product.fromMap(productData);

        // Slide-in and fade-in entry animation
        return TweenAnimationBuilder(
          duration: Duration(milliseconds: 300 + math.min(index, 5) * 80),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1.0 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: _buildItemCard(product, doc.id),
        );
      },
    );
  }

  Widget _buildItemCard(Product product, String productId) {
    final conditionColor = product.condition == 'Baru' ? AppTheme.ecoTeal : AppTheme.sunsetOrange;
    
    // Status Badge styling
    Color statusBg = Colors.blue.withValues(alpha: 0.1);
    Color statusText = Colors.blue;
    if (product.status == 'Completed' || product.status == 'Sold') {
      statusBg = Colors.grey.withValues(alpha: 0.1);
      statusText = Colors.grey.shade700;
    } else if (product.status == 'Draft') {
      statusBg = Colors.purple.withValues(alpha: 0.1);
      statusText = Colors.purple;
    } else if (product.status == 'Processing') {
      statusBg = Colors.orange.withValues(alpha: 0.1);
      statusText = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow(),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.03), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
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
                      ? CachedNetworkImage(
                          imageUrl: product.imagePath,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme.bgLight,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                        )
                      : Image.asset(
                          product.imagePath.isNotEmpty ? product.imagePath : 'assets/images/profile_placeholder.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, color: AppTheme.secondaryBlue),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tags row: Category, Condition, Status
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: conditionColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.condition,
                            style: GoogleFonts.lexend(
                              color: conditionColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.status,
                            style: GoogleFonts.lexend(
                              color: statusText,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.name,
                      style: GoogleFonts.lexend(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.darkNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.price,
                      style: GoogleFonts.lexend(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.bgLight, thickness: 1.5),
          const SizedBox(height: 12),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.push(
                        context,
                        SlideUpRoute(
                          page: EditItemPage(
                            product: product,
                            productId: productId,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit_rounded, size: 16, color: AppTheme.primaryBlue),
                          const SizedBox(width: 6),
                          Text(
                            "Edit",
                            style: GoogleFonts.lexend(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _confirmDelete(productId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.coralPeach.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.coralPeach.withValues(alpha: 0.1), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_rounded, size: 16, color: AppTheme.coralPeach),
                          const SizedBox(width: 6),
                          Text(
                            "Hapus",
                            style: GoogleFonts.lexend(
                              color: AppTheme.coralPeach,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String tabName) {
    String emoji = "🐢";
    String title = "Belum ada barang";
    String subtitle = "Mulai jual barangmu sekarang untuk memberikan kehidupan kedua!";

    if (tabName == "Sold") {
      emoji = "💰";
      title = "Belum ada penjualan";
      subtitle = "Barang jualanmu yang sudah laku akan muncul di tab ini.";
    } else if (tabName == "Draft") {
      emoji = "📝";
      title = "Tidak ada draf";
      subtitle = "Kamu bisa menyimpan draf barang jualan untuk diunggah nanti.";
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 600),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, double val, child) {
                return Opacity(
                  opacity: val,
                  child: Transform.scale(
                    scale: 0.8 + 0.2 * val,
                    child: child,
                  ),
                );
              },
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 64),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.lexend(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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

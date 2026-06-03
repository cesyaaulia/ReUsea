import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reusea/utils/page_transitions.dart';
import 'package:reusea/services/database_service.dart';
import 'package:reusea/utils/theme.dart';
import '../models/product_model.dart';
import 'detail_page.dart';
import 'notification_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedCategory = "Semua";
  String _searchQuery = "";
  final Set<String> _wishlistedIds = {};
  bool _searchHasFocus = false;

  // Mock list of category icons and colors
  final Map<String, Map<String, dynamic>> _categoryMeta = {
    "Semua": {"icon": "🌊", "color": AppTheme.primaryBlue},
    "Buku": {"icon": "📚", "color": Colors.orangeAccent},
    "Elektronik": {"icon": "💻", "color": Colors.purpleAccent},
    "Fashion": {"icon": "👕", "color": Colors.teal},
    "Peralatan": {"icon": "🛠", "color": Colors.pinkAccent},
    "Olahraga": {"icon": "⚽", "color": Colors.blueAccent},
    "Kendaraan": {"icon": "🏍", "color": Colors.redAccent},
    "Makanan": {"icon": "🍔", "color": Colors.amber},
    "Kesehatan": {"icon": "💊", "color": Colors.green},
    "Hobi": {"icon": "🎨", "color": Colors.indigoAccent},
    "Lainnya": {"icon": "📦", "color": Colors.grey},
  };

  @override
  void initState() {
    super.initState();
    _checkAndSeedData();
  }

  void _checkAndSeedData() async {
    try {
      final productsRef = FirebaseFirestore.instance.collection('products');
      final snapshot = await productsRef.limit(1).get();
      if (snapshot.docs.isEmpty) {
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        if (currentUserId.isNotEmpty) {
          await DatabaseService().seedDummyProducts(currentUserId);
        }
      }
    } catch (e) {
      // Silent error
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final String currentDisplayName = FirebaseAuth.instance.currentUser?.displayName ?? 'Cesya';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TOP HERO SECTION WITH GREETINGS & IMPACT CARD
            _buildHeroSection(currentDisplayName),

            // 2. SEARCH BAR (Floating Glass Effect)
            _buildSearchBar(),

            // 3. CATEGORIES ROW (Horizontal Scroll)
            _buildCategoriesSection(),

            // 4. FEATURED SECTION (Carousel Banner)
            _buildFeaturedCarousel(),

            // Stream Builder for fetching all products to distribute across sections
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                    ),
                  );
                }

                var allDocs = snapshot.data?.docs ?? [];
                
                // Hide non-available items
                var availableDocs = allDocs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String status = data['status'] ?? 'Available';
                  return status != 'Processing' && status != 'Completed';
                }).toList();

                if (availableDocs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                      child: Text(
                        "Belum ada barang jualan hari ini.",
                        style: TextStyle(color: AppTheme.secondaryBlue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }

                // Filter by category
                var filteredDocs = availableDocs;
                if (_selectedCategory != "Semua") {
                  filteredDocs = availableDocs.where((doc) {
                    return doc['category'].toString().toUpperCase() ==
                        _selectedCategory.toUpperCase();
                  }).toList();
                }

                // Filter by search
                if (_searchQuery.isNotEmpty) {
                  filteredDocs = filteredDocs.where((doc) {
                    return doc['name'].toString().toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    );
                  }).toList();
                }

                // Map to Product objects
                List<Product> allProducts = availableDocs.map((d) => Product.fromMap(d.data() as Map<String, dynamic>)).toList();
                List<Product> filteredProducts = filteredDocs.map((d) => Product.fromMap(d.data() as Map<String, dynamic>)).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 5. RECOMMENDED FOR YOU (Horizontal List)
                    if (_selectedCategory == "Semua" && _searchQuery.isEmpty)
                      _buildHorizontalProductRow("Recommended For You", allProducts.take(4).toList()),

                    // 6. TRENDING NEAR CAMPUS (Horizontal List)
                    if (_selectedCategory == "Semua" && _searchQuery.isEmpty)
                      _buildHorizontalProductRow("Trending Near Campus", allProducts.skip(2).take(4).toList()),

                    // 7. RECENTLY VIEWED (Horizontal List)
                    if (_selectedCategory == "Semua" && _searchQuery.isEmpty)
                      _buildHorizontalProductRow("Recently Viewed", allProducts.reversed.take(3).toList()),

                    // 8. NEWEST PRODUCTS (Masonry Grid)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text(
                        _selectedCategory == "Semua" ? "Newest Products" : "Kategori $_selectedCategory",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.darkNavy,
                        ),
                      ),
                    ),
                    
                    if (filteredProducts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30.0),
                        child: Center(
                          child: Text(
                            "Barang jualan tidak ditemukan.",
                            style: TextStyle(color: AppTheme.secondaryBlue, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredProducts.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemBuilder: (context, index) {
                            return _buildMasonryProductCard(filteredProducts[index]);
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET 1: HERO SECTION DENGAN GREETING & IMPACT CARD
  Widget _buildHeroSection(String name) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Profile Avatar Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Hello, $name 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Sustainability Mascot badge 🐢
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Text("🐢", style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Text(
                              "Eco Buddy",
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Let's give items a second life today",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Profile Avatar
              Container(
                padding: const EdgeInsets.all(2.0),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.sunsetGradient,
                ),
                child: const CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_rounded, color: AppTheme.primaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // IMPACT CARD (Glassmorphism)
          GlassContainer(
            radius: 24,
            blur: 15,
            opacity: 0.25,
            border: Border.all(color: Colors.white24, width: 1.5),
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildImpactItem("♻", "12 items", "reused"),
                _buildImpactDivider(),
                _buildImpactItem("🌱", "24kg carbon", "saved"),
                _buildImpactDivider(),
                _buildImpactItem("💰", "Rp 1.2M", "saved"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactItem(String emoji, String val, String sub) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          val,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
        ),
        Text(
          sub,
          style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildImpactDivider() {
    return Container(
      height: 30,
      width: 1.5,
      color: Colors.white24,
    );
  }

  // WIDGET 2: FLOATING SEARCH BAR (Glass Effect)
  Widget _buildSearchBar() {
    return Transform.translate(
      offset: const Offset(0, -16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Focus(
          onFocusChange: (hasFocus) {
            setState(() {
              _searchHasFocus = hasFocus;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: _searchHasFocus 
                  ? AppTheme.glowShadow(color: AppTheme.primaryBlue) 
                  : AppTheme.softShadow(),
              border: Border.all(
                color: _searchHasFocus ? AppTheme.primaryBlue : Colors.white,
                width: 1.5,
              ),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.darkNavy),
              decoration: InputDecoration(
                hintText: 'Search preloved items...',
                hintStyle: TextStyle(
                  color: AppTheme.secondaryBlue.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.secondaryBlue),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET 3: CATEGORIES Horizontal List
  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: _categoryMeta.keys.map((catName) {
            bool isSelected = _selectedCategory == catName;
            final meta = _categoryMeta[catName]!;
            final Color color = meta['color'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = catName;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isSelected
                      ? AppTheme.glowShadow(color: color)
                      : AppTheme.softShadow(),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : AppTheme.secondaryBlue.withValues(alpha: 0.08),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Text(meta['icon'], style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      catName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.darkNavy,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // WIDGET 4: FEATURED BANNER SECTION
  Widget _buildFeaturedCarousel() {
    if (_selectedCategory != "Semua" || _searchQuery.isNotEmpty) {
      return const SizedBox.shrink();
    }

    final PageController bannerController = PageController(viewportFraction: 0.9);
    final List<Map<String, dynamic>> banners = [
      {
        "title": "Green Campus Campaign 🌍",
        "desc": "Help UNESA reduce waste by reusing campus books & tools.",
        "gradient": AppTheme.primaryGradient,
      },
      {
        "title": "Save Carbon, Save Earth 🌱",
        "desc": "Buying preloved saves 80% carbon emissions compared to new.",
        "gradient": AppTheme.ecoGradient,
      },
      {
        "title": "Preloved Festival Kampus 🎪",
        "desc": "Find items up to 70% discount from seniors near your dorm.",
        "gradient": AppTheme.sunsetGradient,
      }
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            "Featured Campaign",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
          ),
        ),
        SizedBox(
          height: 125,
          child: PageView.builder(
            controller: bannerController,
            physics: const BouncingScrollPhysics(),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: banner['gradient'],
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.softShadow(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      banner['title'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      banner['desc'],
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  // WIDGET 5, 6, 7: HORIZONTAL SCROLL PRODUCT ROW
  Widget _buildHorizontalProductRow(String title, List<Product> products) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.darkNavy,
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: AppTheme.secondaryBlue, size: 18),
            ],
          ),
        ),
        SizedBox(
          height: 205,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final prod = products[index];
              return Container(
                width: 145,
                margin: const EdgeInsets.only(right: 14, bottom: 8),
                child: _buildMasonryProductCard(prod),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // WIDGET 8: MASONRY/GRID CARD PRODUCT
  Widget _buildMasonryProductCard(Product product) {
    final bool isWishlisted = _wishlistedIds.contains(product.id);
    final conditionColor = product.condition == 'Baru' ? AppTheme.ecoTeal : AppTheme.sunsetOrange;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow(),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image block
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: product.imagePath.startsWith('http')
                        ? Image.network(product.imagePath, fit: BoxFit.cover)
                        : Image.asset(
                            product.imagePath.isNotEmpty ? product.imagePath : 'assets/images/profile_placeholder.png',
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                // Wishlist Floating Button 🤍
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isWishlisted) {
                          _wishlistedIds.remove(product.id);
                        } else {
                          _wishlistedIds.add(product.id);
                        }
                      });
                    },
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.white.withValues(alpha: 0.85),
                      child: Icon(
                        isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isWishlisted ? Colors.redAccent : AppTheme.secondaryBlue,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                // Condition Badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: conditionColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      product.condition,
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Detail block
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category + Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.category,
                        style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 8, fontWeight: FontWeight.w800),
                      ),
                    ),
                    // Seller rating ⭐
                    const Row(
                      children: [
                        Icon(Icons.star_rounded, color: AppTheme.sunYellow, size: 11),
                        SizedBox(width: 2),
                        Text(
                          "4.8",
                          style: TextStyle(color: AppTheme.darkNavy, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Product Name
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      HeroFadeRoute(page: DetailPage(product: product)),
                    );
                  },
                  child: Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.darkNavy),
                  ),
                ),
                const SizedBox(height: 4),
                // Price & Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.price,
                      style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(
                      product.time,
                      style: TextStyle(color: AppTheme.secondaryBlue.withValues(alpha: 0.5), fontSize: 8),
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
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reusea/services/database_service.dart';
import 'package:reusea/utils/page_transitions.dart';
import 'package:reusea/utils/theme.dart';
import 'sale_detail_page.dart';

class PastSellsPage extends StatefulWidget {
  const PastSellsPage({super.key});

  @override
  State<PastSellsPage> createState() => _PastSellsPageState();
}

class _PastSellsPageState extends State<PastSellsPage> with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final String currentUserId = user?.uid ?? '';

    return Scaffold(
      body: OceanGradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.softShadow(),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: AppTheme.darkNavy,
                          size: 18,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Riwayat Penjualan',
                      style: GoogleFonts.lexend(
                        color: AppTheme.darkNavy,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              // TabBar section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.secondaryBlue,
                    labelStyle: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 11),
                    unselectedLabelStyle: GoogleFonts.lexend(fontWeight: FontWeight.w500, fontSize: 11),
                    tabs: const [
                      Tab(text: "Semua"),
                      Tab(text: "Diproses"),
                      Tab(text: "Selesai"),
                      Tab(text: "Batal"),
                    ],
                  ),
                ),
              ),

              // Expanded tab views
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _dbService.getPastSellsStream(currentUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                      );
                    }

                    List<Map<String, dynamic>> allItems = [];
                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        var data = doc.data() as Map<String, dynamic>;
                        data['id'] = doc.id;
                        data['isMock'] = false;
                        allItems.add(data);
                      }
                    }

                    // Sort in memory by createdAt descending
                    allItems.sort((a, b) {
                      Timestamp? aTime = a['createdAt'] as Timestamp?;
                      Timestamp? bTime = b['createdAt'] as Timestamp?;
                      if (aTime == null && bTime == null) return 0;
                      if (aTime == null) return 1;
                      if (bTime == null) return -1;
                      return bTime.compareTo(aTime);
                    });

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSaleList(context, allItems),
                        _buildSaleList(context, allItems.where((i) => i['status'] == 'Processing').toList()),
                        _buildSaleList(context, allItems.where((i) => i['status'] == 'Completed').toList()),
                        _buildSaleList(context, allItems.where((i) => i['status'] == 'Cancelled').toList()),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaleList(BuildContext context, List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🏷️", style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              "Belum ada barang jualan terjual.",
              style: GoogleFonts.lexend(
                color: AppTheme.secondaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Upload barang preloved Anda dan dapatkan pembeli!",
              style: GoogleFonts.lexend(
                color: AppTheme.lightBlueGrey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildSaleCard(context, items[index]);
      },
    );
  }

  Widget _buildSaleCard(BuildContext context, Map<String, dynamic> item) {
    final String status = item['status'] ?? 'Processing';

    Color badgeColor;
    String statusIndo;
    if (status == 'Completed') {
      badgeColor = AppTheme.ecoTeal;
      statusIndo = "Selesai";
    } else if (status == 'Cancelled') {
      badgeColor = AppTheme.coralPeach;
      statusIndo = "Batal";
    } else {
      badgeColor = AppTheme.sunsetOrange;
      statusIndo = "Diproses";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow(),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.03), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            SlideFadeRightRoute(
              page: SaleDetailPage(saleData: item),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Product Image with soft rounded corners
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: item['imagePath'] != null && item['imagePath'].startsWith('http')
                      ? Image.network(item['imagePath'], fit: BoxFit.cover)
                      : Image.asset(
                          item['imagePath'] != null && item['imagePath'].isNotEmpty
                              ? item['imagePath']
                              : 'assets/images/profile_placeholder.png',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            statusIndo,
                            style: GoogleFonts.lexend(
                              color: badgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          item['time'] ?? '',
                          style: GoogleFonts.lexend(
                            color: AppTheme.lightBlueGrey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['name'] ?? '',
                      style: GoogleFonts.lexend(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['price'] ?? '',
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 12, color: AppTheme.secondaryBlue),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Pembeli: ${item['buyerName'] ?? 'Mahasiswa UNESA'}',
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              color: AppTheme.secondaryBlue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.lightBlueGrey,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

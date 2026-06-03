import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reusea/services/database_service.dart';
import 'package:reusea/services/delivery_service.dart';
import 'package:reusea/utils/theme.dart';
import 'package:reusea/utils/page_transitions.dart';
import '../models/product_model.dart';
import 'chat_detail_page.dart';

class SaleDetailPage extends StatefulWidget {
  final Map<String, dynamic> saleData;

  const SaleDetailPage({super.key, required this.saleData});

  @override
  State<SaleDetailPage> createState() => _SaleDetailPageState();
}

class _SaleDetailPageState extends State<SaleDetailPage> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.saleData['status'] ?? 'Processing';
  }

  void _cancelSale() async {
    setState(() => _isLoading = true);
    final String orderId = widget.saleData['id'] ?? '';

    try {
      await _dbService.updateOrderStatus(orderId, 'Cancelled');
      setState(() {
        _currentStatus = 'Cancelled';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Penjualan berhasil dibatalkan.", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal membatalkan penjualan: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _completeSale() async {
    setState(() => _isLoading = true);
    final String orderId = widget.saleData['id'] ?? '';

    try {
      await _dbService.updateOrderStatus(orderId, 'Completed');
      setState(() {
        _currentStatus = 'Completed';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Penjualan berhasil diselesaikan! 🥳", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.ecoTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menyelesaikan penjualan: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToChat(Map<String, dynamic> item) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final String buyerId = item['buyerId'] ?? '';
    if (buyerId.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
      ),
    );

    try {
      String sellerName = currentUser.displayName ?? currentUser.email!.split('@')[0];
      String sellerPhoto = currentUser.photoURL ?? '';

      String roomId = await _dbService.getOrCreateChatRoom(
        buyerId: buyerId,
        buyerName: item['buyerName'] ?? 'Pembeli UNESA',
        buyerPhoto: item['buyerPhoto'] ?? '',
        sellerId: currentUser.uid,
        sellerName: sellerName,
        sellerPhoto: sellerPhoto,
      );

      if (mounted) Navigator.pop(context);

      Product dummyProd = Product(
        id: item['productId'] ?? '',
        sellerId: currentUser.uid,
        sellerName: sellerName,
        sellerPhoto: sellerPhoto,
        name: item['name'] ?? '',
        price: item['price'] ?? '',
        imagePath: item['imagePath'] ?? '',
        imageUrls: item['imagePath'] != null ? [item['imagePath']] : [],
        category: '',
        condition: '',
        description: '',
        location: item['location'] ?? '',
        time: '',
        status: item['status'] ?? 'Available',
      );

      if (mounted) {
        Navigator.push(
          context,
          SlideFadeRightRoute(
            page: ChatDetailPage(
              roomId: roomId,
              peerId: buyerId,
              peerName: item['buyerName'] ?? 'Pembeli UNESA',
              peerPhoto: item['buyerPhoto'] ?? '',
              product: dummyProd,
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

  Widget _buildTimeline(String status) {
    int currentStep = 0;
    if (status == 'Completed' || status == 'Cancelled') {
      currentStep = 2;
    } else if (status == 'Processing') {
      currentStep = 1;
    }

    Color stepColor(int step) {
      if (status == 'Cancelled' && step == 2) return AppTheme.coralPeach;
      return step <= currentStep ? AppTheme.ecoTeal : AppTheme.lightBlueGrey;
    }

    String stepLabel(int step) {
      if (step == 0) return "Dipesan";
      if (step == 1) return "Diproses COD";
      if (step == 2) {
        return status == 'Cancelled' ? "Batal" : "Selesai";
      }
      return "";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow(),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.03), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Timeline Transaksi",
            style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              return Expanded(
                child: Row(
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: stepColor(index),
                          child: Icon(
                            index <= currentStep
                                ? (status == 'Cancelled' && index == 2
                                    ? Icons.close_rounded
                                    : Icons.check_rounded)
                                : Icons.circle_rounded,
                            color: Colors.white,
                            size: index <= currentStep ? 16 : 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stepLabel(index),
                          style: GoogleFonts.lexend(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: stepColor(index),
                          ),
                        ),
                      ],
                    ),
                    if (index < 2)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Container(
                            height: 3,
                            color: index < currentStep
                                ? AppTheme.ecoTeal
                                : AppTheme.lightBlueGrey.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.saleData['id'])
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic> item = widget.saleData;
        if (snapshot.hasData && snapshot.data!.exists) {
          item = snapshot.data!.data() as Map<String, dynamic>;
          item['id'] = snapshot.data!.id;
          _currentStatus = item['status'] ?? _currentStatus;
        }

        final String deliveryService = item['deliveryService'] ?? '';

        Color badgeColor;
        String statusIndo;
        if (_currentStatus == 'Completed') {
          badgeColor = AppTheme.ecoTeal;
          statusIndo = "Selesai";
        } else if (_currentStatus == 'Cancelled') {
          badgeColor = AppTheme.coralPeach;
          statusIndo = "Batal";
        } else {
          badgeColor = AppTheme.sunsetOrange;
          statusIndo = "Diproses";
        }

        return Scaffold(
          body: OceanGradientBackground(
            child: SafeArea(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
                  : Column(
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
                                'Detail Penjualan',
                                style: GoogleFonts.lexend(
                                  color: AppTheme.darkNavy,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. TIMELINE STATUS
                                _buildTimeline(_currentStatus),
                                const SizedBox(height: 20),

                                // 2. PRODUCT DETAIL CARD
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: AppTheme.softShadow(),
                                    border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.03), width: 1.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Product Image Container
                                      Container(
                                        width: double.infinity,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          color: AppTheme.bgLight,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
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
                                      const SizedBox(height: 18),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: badgeColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              statusIndo,
                                              style: GoogleFonts.lexend(
                                                color: badgeColor,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            item['time'] ?? '',
                                            style: GoogleFonts.lexend(color: AppTheme.secondaryBlue, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        item['name'] ?? '',
                                        style: GoogleFonts.lexend(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.darkNavy,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item['price'] ?? '',
                                        style: GoogleFonts.lexend(
                                          fontSize: 20,
                                          color: AppTheme.primaryBlue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // 3. BUYER CARD
                                Text(
                                  "Informasi Pembeli",
                                  style: GoogleFonts.lexend(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
                                ),
                                const SizedBox(height: 10),
                                 FutureBuilder<DocumentSnapshot?>(
                                   future: item['buyerId'] != null && (item['buyerId'] as String).isNotEmpty
                                       ? FirebaseFirestore.instance.collection('users').doc(item['buyerId']).get()
                                       : Future<DocumentSnapshot?>.value(null),
                                   builder: (context, buyerSnap) {
                                    var userData = buyerSnap.data != null && buyerSnap.data!.exists
                                        ? buyerSnap.data!.data() as Map<String, dynamic>?
                                        : null;

                                    String bName = userData?['name'] ?? item['buyerName'] ?? 'Pembeli UNESA';
                                    String bPhoto = userData?['photoUrl'] ?? item['buyerPhoto'] ?? '';
                                    String bFaculty = userData?['faculty'] ?? 'Mahasiswa UNESA';

                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: AppTheme.softShadow(),
                                        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.03), width: 1.5),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 26,
                                            backgroundColor: AppTheme.bgLight,
                                            backgroundImage: bPhoto.isNotEmpty ? NetworkImage(bPhoto) : null,
                                            child: bPhoto.isEmpty ? const Icon(Icons.person_rounded, color: AppTheme.secondaryBlue) : null,
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  bName,
                                                  style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  bFaculty,
                                                  style: GoogleFonts.lexend(color: AppTheme.secondaryBlue, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => _navigateToChat(item),
                                            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primaryBlue),
                                            style: IconButton.styleFrom(
                                              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.08),
                                              padding: const EdgeInsets.all(12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),

                                // 4. PICKUP LOCATION CARD
                                Text(
                                  "Lokasi Pengambilan COD",
                                  style: GoogleFonts.lexend(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: AppTheme.softShadow(),
                                    border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.03), width: 1.5),
                                  ),
                                  child: Row(
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: AppTheme.bgLight,
                                        child: Icon(Icons.location_on_rounded, color: AppTheme.primaryBlue),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['location'] ?? 'UNESA Lidah Wetan',
                                              style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkNavy),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Surabaya, East Java",
                                              style: GoogleFonts.lexend(color: AppTheme.secondaryBlue, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // 5. DELIVERY INFO CARD (IF APPLICABLE)
                                if (deliveryService.isNotEmpty) ...[
                                  Text(
                                    "Detail Pengiriman",
                                    style: GoogleFonts.lexend(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: AppTheme.softShadow(),
                                      border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.03), width: 1.5),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              deliveryService == 'GoSend'
                                                  ? Icons.two_wheeler_rounded
                                                  : (deliveryService == 'Grab Express'
                                                      ? Icons.delivery_dining_rounded
                                                      : Icons.people_outline_rounded),
                                              color: AppTheme.ecoTeal,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    deliveryService,
                                                    style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkNavy),
                                                  ),
                                                  if (item['distanceKm'] != null && !deliveryService.contains('COD'))
                                                    Text(
                                                      'Jarak: ${(item['distanceKm'] as num).toStringAsFixed(1)} km',
                                                      style: GoogleFonts.lexend(color: AppTheme.secondaryBlue, fontSize: 11),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            if (item['deliveryFee'] != null)
                                              Text(
                                                deliveryService.contains('COD')
                                                    ? 'Gratis'
                                                    : DeliveryService.formatRupiah((item['deliveryFee'] as num).toDouble()),
                                                style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkNavy),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                ],

                                // 6. ACTION BUTTONS
                                if (_currentStatus == 'Processing')
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 52,
                                          child: TextButton.icon(
                                            onPressed: _cancelSale,
                                            icon: const Icon(Icons.cancel_outlined, color: Colors.white),
                                            label: Text(
                                              'Batalkan',
                                              style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            style: TextButton.styleFrom(
                                              backgroundColor: AppTheme.coralPeach,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: SizedBox(
                                          height: 52,
                                          child: TextButton.icon(
                                            onPressed: _completeSale,
                                            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                                            label: Text(
                                              'Selesaikan',
                                              style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            style: TextButton.styleFrom(
                                              backgroundColor: AppTheme.ecoTeal,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

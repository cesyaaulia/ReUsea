import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reusea/services/database_service.dart';
import 'package:reusea/utils/page_transitions.dart';
import 'sale_detail_page.dart';

class PastSellsPage extends StatefulWidget {
  const PastSellsPage({super.key});

  @override
  State<PastSellsPage> createState() => _PastSellsPageState();
}

class _PastSellsPageState extends State<PastSellsPage> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final String currentUserId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Past Sells',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.withValues(alpha: 0.1),
            height: 1,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getPastSellsStream(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFBC8E52)),
            );
          }

          // Jika data penjualan di Firestore masih kosong
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada riwayat penjualan.",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          List<Map<String, dynamic>> items = [];
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            data['isMock'] = false;
            items.add(data);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildSaleCard(context, item);
            },
          );
        },
      ),
    );
  }

  Widget _buildSaleCard(BuildContext context, Map<String, dynamic> item) {
    final String status = item['status'] ?? 'Processing';

    Color statusBgColor;
    Color statusTextColor;
    switch (status) {
      case 'Completed':
        statusBgColor = const Color(0xFFE8F5E9);
        statusTextColor = const Color(0xFF2E7D32);
        break;
      case 'Cancelled':
        statusBgColor = const Color(0xFFFFEBEE);
        statusTextColor = const Color(0xFFC62828);
        break;
      case 'Processing':
      default:
        statusBgColor = const Color(0xFFE3F2FD);
        statusTextColor = const Color(0xFF1565C0);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            SlideFadeRightRoute(
              page: SaleDetailPage(saleData: item),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F7F4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        item['imagePath'] != null &&
                            item['imagePath'].startsWith('http')
                        ? Image.network(
                            item['imagePath'],
                            fit: BoxFit.cover,
                            width: 90,
                            height: 90,
                          )
                        : const Icon(
                            Icons.shopping_bag_outlined,
                            color: Color(0xFFBC8E52),
                            size: 36,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['price'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFFBC8E52),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Buyer: ${item['buyerName'] ?? 'Mahasiswa UNESA'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E1),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:reusea/models/product_model.dart';
import 'package:reusea/services/auth_service.dart';
import 'package:reusea/services/database_service.dart';
import 'package:reusea/utils/page_transitions.dart';
import 'package:reusea/pages/edit_items_page.dart';

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
        title: const Text("Hapus Barang?"),
        content: const Text("Barang yang dihapus tidak bisa dikembalikan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _dbService.deleteProduct(productId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Barang berhasil dihapus"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal menghapus: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = _authService.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Items',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var myProductsDocs =
              snapshot.data?.docs
                  .where((doc) => doc['sellerId'] == currentUserId)
                  .toList() ??
              [];

          if (myProductsDocs.isEmpty) {
            return const Center(
              child: Text("Belum ada barang yang Anda unggah."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myProductsDocs.length,
            itemBuilder: (context, index) {
              var doc = myProductsDocs[index];
              var productData = doc.data() as Map<String, dynamic>;
              Product product = Product.fromMap(productData);

              return _buildItemCard(
                product,
                doc.id,
              ); // Kita kirim doc.id untuk dihapus
            },
          );
        },
      ),
    );
  }

  Widget _buildItemCard(Product product, String productId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: product.imagePath.startsWith('http')
                      ? Image.network(product.imagePath, fit: BoxFit.cover)
                      : const Icon(Icons.image),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          product.category,
                          style: const TextStyle(
                            color: Color(0xFFBC8E52),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: product.condition == 'Baru'
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            product.condition,
                            style: TextStyle(
                              color: product.condition == 'Baru'
                                  ? Colors.green
                                  : Colors.orange,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.price,
                      style: const TextStyle(
                        color: Color(0xFFBC8E52),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  // --- UBAH BAGIAN INI ---
                  onTap: () {
                    // Navigasi ke EditItemPage dengan membawa data produk dan ID
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
                  // ----------------------
                  child: _buildActionButton(
                    icon: Icons.edit,
                    label: "Edit",
                    color: Colors.blue.shade50,
                    textColor: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () =>
                      _confirmDelete(productId), // Panggil fungsi hapus
                  child: _buildActionButton(
                    icon: Icons.delete,
                    label: "Delete",
                    color: Colors.red.shade50,
                    textColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

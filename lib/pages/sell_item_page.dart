import 'package:flutter/material.dart';

class SellItemPage extends StatelessWidget {
  const SellItemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Sell Item", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        // Menambahkan tombol back agar bisa kembali ke halaman sebelumnya
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Product Photos", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPhotoSlot("MAIN", true),
                const SizedBox(width: 10),
                _buildPhotoSlot("+", false),
                const SizedBox(width: 10),
                _buildPhotoSlot("+", false),
              ],
            ),
            const SizedBox(height: 25),
            _buildInputLabel("Product Name"),
            _buildTextField("e.g. Almamater UNESA Size L"),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel("Price"),
                      _buildTextField("Rp 0"),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel("Category"),
                      _buildTextField("Books"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildInputLabel("Description"),
            _buildTextField("Describe your item (condition, usage time, etc.)", maxLines: 4),
            const SizedBox(height: 15),
            _buildInputLabel("Pickup Location"),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(12)
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_on, color: Color(0xFFBC8E52)),
                  SizedBox(width: 10),
                  Text("UNESA Lidah Wetan, Surabaya", style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // Tambahkan logika upload di sini
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBC8E52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Upload Item", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget untuk Label Input
  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  // Helper Widget untuk TextField
  Widget _buildTextField(String hint, {int maxLines = 1}) {
    return TextField(
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: BorderSide.none
        ),
      ),
    );
  }

  // Helper Widget untuk Slot Foto
  Widget _buildPhotoSlot(String label, bool isMain) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isMain ? Border.all(color: const Color(0xFFBC8E52), width: 2) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isMain ? Icons.camera_alt_outlined : Icons.add, color: const Color(0xFFBC8E52)),
          const SizedBox(height: 4),
          Text(label, 
            style: const TextStyle(fontSize: 10, color: Color(0xFFBC8E52), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

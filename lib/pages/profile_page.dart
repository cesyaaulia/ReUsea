import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined, color: Colors.black))],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 30),
              width: double.infinity,
              child: Column(
                children: [
                  const CircleAvatar(radius: 50, backgroundColor: Color(0xFFE9E2D7), child: Icon(Icons.person, size: 50, color: Colors.grey)),
                  const SizedBox(height: 15),
                  const Text("Budi Santoso", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text("budi.21001@mhs.unesa.ac.id", style: TextStyle(color: Color(0xFFBC8E52))),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat("12", "Solds"),
                      Container(width: 1, height: 30, color: Colors.grey[300]),
                      _buildStat("8", "Bought"),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("TRANSACTION HISTORY"),
            _buildMenuTile(Icons.shopping_bag_outlined, "Past Buys", "History of items you purchased"),
            _buildMenuTile(Icons.sell_outlined, "Past Sells", "Track items you have sold"),
            const SizedBox(height: 20),
            _buildSectionTitle("MANAGE DATA"),
            _buildMenuTile(Icons.person_outline, "Edit Profile Info", null),
            _buildMenuTile(Icons.logout, "Log Out", null, isLogout: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFBC8E52))),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String? sub, {bool isLogout = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: isLogout ? Colors.red : const Color(0xFFBC8E52)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isLogout ? Colors.red : Colors.black)),
        subtitle: sub != null ? Text(sub, style: const TextStyle(fontSize: 12)) : null,
        trailing: isLogout ? null : const Icon(Icons.chevron_right),
      ),
    );
  }
}
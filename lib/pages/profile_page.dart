import 'package:flutter/material.dart';
import 'settings_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Warna Background Krem (Sesuai Homepage & Figma)
      backgroundColor: const Color(0xFFF9F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Bagian Atas (Foto & Nama) dengan Background Putih
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 30, top: 10),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 55,
                    backgroundColor: Color(0xFFF0F0F0),
                    backgroundImage: AssetImage('assets/images/profile_placeholder.png'), // Sesuaikan jika ada foto
                    child: Icon(Icons.person, size: 50, color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Budi Santoso',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const Text(
                    'budi.21001@mhs.unesa.ac.id',
                    style: TextStyle(color: Color(0xFFBC8E52), fontSize: 13),
                  ),
                  const SizedBox(height: 25),
                  // Statistik Solds & Bought
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('12', 'Solds'),
                      Container(height: 30, width: 1, color: Colors.grey[200]),
                      _buildStatColumn('8', 'Bought'),
                    ],
                  ),
                ],
              ),
            ),
            
            // 2. Transaction History & Manage Data
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TRANSACTION HISTORY',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuTile(Icons.shopping_bag_outlined, 'Past Buys', 'History of items you purchased'),
                  const SizedBox(height: 10),
                  _buildMenuTile(Icons.sell_outlined, 'Past Sells', 'Track items you have sold'),
                  
                  const SizedBox(height: 25),
                  const Text(
                    'MANAGE DATA',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuTile(Icons.manage_accounts_outlined, 'Edit Profile Info', '', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilePage()));
                  }),
                  const SizedBox(height: 10),
                  _buildLogoutTile(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFBC8E52)),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFFBC8E52)),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(fontSize: 11)) : null,
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      ),
    );
  }

  Widget _buildLogoutTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const ListTile(
        leading: Icon(Icons.logout, color: Colors.redAccent),
        title: Text('Log Out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.redAccent)),
      ),
    );
  }
}
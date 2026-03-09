import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar Profile dengan Edit Icon
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2ECC71), width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey,
                      backgroundImage: NetworkImage('https://via.placeholder.com/150'), // Ganti dengan image asset kamu
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2ECC71),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 20, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Nama dan Email
            const Text(
              'Budi Santoso',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'budi.21001@mhs.unesa.ac.id',
              style: TextStyle(color: Color(0xFF2ECC71), fontSize: 14),
            ),
            const SizedBox(height: 30),
            
            // Statistik Solds & Bought
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('12', 'Solds'),
                Container(width: 1, height: 40, color: Colors.white24),
                _buildStatItem('8', 'Bought'),
              ],
            ),
            const SizedBox(height: 40),

            // Section Transaction History
            _buildSectionTitle('TRANSACTION HISTORY'),
            _buildMenuTile(
              icon: Icons.shopping_bag_outlined,
              title: 'Past Buys',
              subtitle: 'History of items you purchased',
              iconBgColor: const Color(0xFF1B3D2F),
              iconColor: const Color(0xFF2ECC71),
            ),
            _buildMenuTile(
              icon: Icons.local_offer_outlined,
              title: 'Past Sells',
              subtitle: 'Track items you have sold',
              iconBgColor: const Color(0xFF1B3D2F),
              iconColor: const Color(0xFF2ECC71),
            ),

            const SizedBox(height: 24),

            // Section Manage Data
            _buildSectionTitle('MANAGE DATA'),
            _buildMenuTile(
              icon: Icons.person_outline,
              title: 'Edit Profile Info',
              iconColor: Colors.grey,
            ),
            _buildMenuTile(
              icon: Icons.logout,
              title: 'Log Out',
              iconColor: Colors.redAccent,
              textColor: Colors.redAccent,
              showChevron: false,
            ),
            const SizedBox(height: 100), // Memberi ruang agar tidak tertutup Navbar
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2ECC71),
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconBgColor,
    required Color iconColor,
    Color textColor = Colors.white,
    bool showChevron = true,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF14261D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor ?? Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12))
            : null,
        trailing: showChevron ? const Icon(Icons.chevron_right, color: Colors.grey) : null,
        onTap: () {},
      ),
    );
  }
}
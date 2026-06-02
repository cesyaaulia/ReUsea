import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Wajib import Firestore untuk menghitung data
import 'package:reusea/services/auth_service.dart';
import 'package:reusea/utils/page_transitions.dart';
import 'settings_page.dart';
import 'edit_profile_page.dart';
import 'login_page.dart';
import 'past_buys_page.dart';
import 'past_sells_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    // FUNGSI DIALOG LOGOUT
    void handleLogout() async {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Log Out"),
          content: const Text(
            "Apakah Anda yakin ingin keluar dari akun ReUsea?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await authService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    ElegantFadeRoute(page: const LoginPage()),
                    (route) => false,
                  );
                }
              },
              child: const Text("Keluar", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }

    return Scaffold(
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
            onPressed: () => Navigator.push(
              context,
              FadeScaleRoute(page: const SettingsPage()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, snapshot) {
          final currentUser = snapshot.data;

          String userEmail = currentUser?.email ?? "budi.21001@mhs.unesa.ac.id";
          String userName = currentUser?.displayName ?? userEmail.split('@')[0];
          String? photoUrl = currentUser?.photoURL;
          String currentUserId = currentUser?.uid ?? '';

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 30, top: 10),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: const Color(0xFFF0F0F0),
                        backgroundImage: photoUrl != null
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          color: Color(0xFFBC8E52),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // =========================================================
                      // BAGIAN STATISTIK (Solds & Bought Berhasil Di-Sync Live)
                      // =========================================================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSoldsStat(
                            currentUserId,
                          ), // Panggil fungsi Stream Solds
                          Container(
                            height: 30,
                            width: 1,
                            color: Colors.grey[200],
                          ),
                          _buildBoughtStat(
                            currentUserId,
                          ), // Panggil fungsi Stream Bought
                        ],
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TRANSACTION HISTORY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildMenuTile(
                        Icons.shopping_bag_outlined,
                        'Past Buys',
                        'History of items you purchased',
                        onTap: () {
                          Navigator.push(
                            context,
                            SlideRightRoute(
                              page: const PastBuysPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      _buildMenuTile(
                        Icons.sell_outlined,
                        'Past Sells',
                        'Track items you have sold',
                        onTap: () {
                          Navigator.push(
                            context,
                            SlideRightRoute(
                              page: const PastSellsPage(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 25),
                      const Text(
                        'MANAGE DATA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuTile(
                        Icons.manage_accounts_outlined,
                        'Edit Profile Info',
                        '',
                        onTap: () {
                          Navigator.push(
                            context,
                            SlideUpRoute(
                              page: const EditProfilePage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildLogoutTile(onTap: handleLogout),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // WIDGET STREAM UNTUK MENGHITUNG JUMLAH BARANG TERJUAL (SOLDS)
  // =========================================================
  Widget _buildSoldsStat(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('sellerId', isEqualTo: uid)
          .where('status', isEqualTo: 'Completed')
          .snapshots(),
      builder: (context, snapshot) {
        String count = '0';
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length.toString();
        }
        return _buildStatColumn(count, 'Solds');
      },
    );
  }

  // =========================================================
  // WIDGET STREAM UNTUK MENGHITUNG JUMLAH BARANG TERBELI (BOUGHT)
  // =========================================================
  Widget _buildBoughtStat(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: uid)
          .where('status', isEqualTo: 'Completed')
          .snapshots(),
      builder: (context, snapshot) {
        String count = '0';
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length.toString();
        }
        return _buildStatColumn(count, 'Bought');
      },
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFBC8E52),
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildMenuTile(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFFBC8E52)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle, style: const TextStyle(fontSize: 11))
            : null,
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      ),
    );
  }

  Widget _buildLogoutTile({required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.logout, color: Colors.redAccent),
        title: const Text(
          'Log Out',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.redAccent,
          ),
        ),
      ),
    );
  }
}

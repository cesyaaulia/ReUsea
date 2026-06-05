import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reusea/services/auth_service.dart';
import 'package:reusea/utils/page_transitions.dart';
import 'package:reusea/utils/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'settings_page.dart';
import 'edit_profile_page.dart';
import 'login_page.dart';
import 'past_buys_page.dart';
import 'past_sells_page.dart';
import 'wishlist_page.dart';
import 'incoming_orders_page.dart';
import '../models/achievement_model.dart';
import '../services/database_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    void handleLogout() async {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Log Out",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Apakah Anda yakin ingin keluar dari akun ReUsea?",
            style: TextStyle(color: AppTheme.secondaryBlue),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.coralPeach,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Keluar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OceanGradientBackground(
        child: SafeArea(
          bottom: false,
          child: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.userChanges(),
            builder: (context, snapshot) {
              final currentUser = snapshot.data;

              String userEmail = currentUser?.email ?? "student@mhs.unesa.ac.id";
              String userName = currentUser?.displayName ?? userEmail.split('@')[0];
              String? photoUrl = currentUser?.photoURL;
              String currentUserId = currentUser?.uid ?? '';

              if (currentUserId.isNotEmpty) {
                DatabaseService().updateAchievements(currentUserId);
              }

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Custom App Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Profile',
                            style: TextStyle(
                              color: AppTheme.darkNavy,
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: AppTheme.softShadow(),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.settings_outlined, color: AppTheme.darkNavy),
                              onPressed: () => Navigator.push(
                                context,
                                FadeScaleRoute(page: SettingsPage()),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Profile Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: AppTheme.softShadow(),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Photo Profile
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppTheme.oceanWaveGradient,
                              ),
                              child: CircleAvatar(
                                radius: 52,
                                backgroundColor: AppTheme.bgLight,
                                backgroundImage: photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
                                child: photoUrl == null
                                    ? const Icon(Icons.person_rounded, size: 52, color: AppTheme.secondaryBlue)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // User Name
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.darkNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // User Email
                            Text(
                              userEmail,
                              style: TextStyle(
                                color: AppTheme.secondaryBlue.withValues(alpha: 0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(height: 40, thickness: 1, color: Color(0xFFF0F4F8)),

                            // Statistics Cards
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(child: _buildSoldsStat(currentUserId)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildBoughtStat(currentUserId)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Menu Option List
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 12),
                          child: Text(
                            'TRANSACTION HISTORY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.secondaryBlue,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        _buildMenuTile(
                          Icons.shopping_bag_outlined,
                          'Past Buys',
                          'History of items you purchased',
                          onTap: () {
                            Navigator.push(
                              context,
                              SlideRightRoute(page: const PastBuysPage()),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuTile(
                          Icons.sell_outlined,
                          'Past Sells',
                          'Track items you have sold',
                          onTap: () {
                            Navigator.push(
                              context,
                              SlideRightRoute(page: const PastSellsPage()),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuTile(
                          Icons.inbox_outlined,
                          'Pesanan Masuk',
                          'Manage your incoming orders',
                          onTap: () {
                            Navigator.push(
                              context,
                              SlideRightRoute(page: const IncomingOrdersPage()),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 30),
                        const Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 12),
                          child: Text(
                            'MY COLLECTION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.secondaryBlue,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        _buildMenuTile(
                          Icons.favorite_border_rounded,
                          'Wishlist',
                          'Produk yang kamu simpan',
                          onTap: () {
                            Navigator.push(
                              context,
                              SlideRightRoute(page: const WishlistPage()),
                            );
                          },
                        ),

                        const SizedBox(height: 30),
                        // SUSTAINABILITY IMPACT DASHBOARD
                        const Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 12),
                          child: Text(
                            'DAMPAK KEBERLANJUTAN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.secondaryBlue,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        _buildSustainabilityCard(currentUserId),

                        const SizedBox(height: 30),
                        // ACHIEVEMENT SAYA
                        const Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 12),
                          child: Text(
                            'ACHIEVEMENT SAYA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.secondaryBlue,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        _buildAchievementsCard(currentUserId),

                        const SizedBox(height: 30),
                        const Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 12),
                          child: Text(
                            'MANAGE DATA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.secondaryBlue,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        _buildMenuTile(
                          Icons.manage_accounts_outlined,
                          'Edit Profile Info',
                          'Manage username, photo, and details',
                          onTap: () {
                            Navigator.push(
                              context,
                              SlideUpRoute(page: const EditProfilePage()),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildLogoutTile(onTap: handleLogout),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

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
        return _buildStatBox(count, 'Solds', AppTheme.oceanWaveGradient);
      },
    );
  }

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
        return _buildStatBox(count, 'Bought', AppTheme.sunsetGradient);
      },
    );
  }

  Widget _buildStatBox(String value, String label, LinearGradient gradient) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => gradient.createShader(bounds),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white, // fallback color
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppTheme.secondaryBlue, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSustainabilityCard(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: uid)
          .where('status', isEqualTo: 'Completed')
          .snapshots(),
      builder: (context, snapshot) {
        int itemsReused = 0;
        if (snapshot.hasData) {
          itemsReused = snapshot.data!.docs.length;
        }
        double carbonSaved = itemsReused * 2.0; // ~2kg CO2 per reused item
        double moneySaved = itemsReused * 50000.0; // ~50k avg savings

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.ecoGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.softShadow(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text("🌍", style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text(
                    "Dampak Positifmu",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildImpactStat("♻", "$itemsReused", "Barang\nReused"),
                  _buildImpactStat("🌱", "${carbonSaved.toStringAsFixed(0)} Kg", "Limbah\nBerkurang"),
                  _buildImpactStat("💰", "Rp ${(moneySaved / 1000).toStringAsFixed(0)}K", "Hemat\nMahasiswa"),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementsCard(String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        List<dynamic> unlockedAchievements = [];
        int solds = 0;
        int bought = 0;
        
        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          unlockedAchievements = userData['achievements'] ?? [];
          solds = userData['solds'] ?? 0;
          bought = userData['bought'] ?? 0;
        }

        int totalTransactions = solds + bought;
        int limbahBerkurang = bought * 2;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.softShadow(),
            border: Border.all(
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: achievementsList.length,
                separatorBuilder: (context, index) => const Divider(height: 20, thickness: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final ach = achievementsList[index];
                  bool isUnlocked = unlockedAchievements.contains(ach.id);
                  
                  // Hitung kemajuan
                  String progressText = "";
                  double progressPct = 0.0;
                  if (ach.id == 'eco_beginner') {
                    progressText = "$totalTransactions / 1";
                    progressPct = (totalTransactions / 1.0).clamp(0.0, 1.0);
                  } else if (ach.id == 'eco_contributor') {
                    progressText = "$totalTransactions / 5";
                    progressPct = (totalTransactions / 5.0).clamp(0.0, 1.0);
                  } else if (ach.id == 'eco_champion') {
                    progressText = "$totalTransactions / 20";
                    progressPct = (totalTransactions / 20.0).clamp(0.0, 1.0);
                  } else if (ach.id == 'sustainability_hero') {
                    progressText = "$limbahBerkurang / 20 Kg";
                    progressPct = (limbahBerkurang / 20.0).clamp(0.0, 1.0);
                  } else if (ach.id == 'campus_seller') {
                    progressText = "$solds / 10";
                    progressPct = (solds / 10.0).clamp(0.0, 1.0);
                  }

                  return Opacity(
                    opacity: isUnlocked ? 1.0 : 0.5,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isUnlocked 
                                ? AppTheme.primaryBlue.withValues(alpha: 0.08) 
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            ach.emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    ach.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isUnlocked ? AppTheme.darkNavy : Colors.grey.shade700,
                                    ),
                                  ),
                                  if (!isUnlocked)
                                    Text(
                                      progressText,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                ach.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isUnlocked ? AppTheme.secondaryBlue : Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (!isUnlocked) ...[
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progressPct,
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImpactStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow(),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.darkNavy),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: AppTheme.secondaryBlue.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
              )
            : null,
        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.secondaryBlue),
      ),
    );
  }

  Widget _buildLogoutTile({required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow(),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
        ),
        title: const Text(
          'Log Out',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.redAccent,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.redAccent),
      ),
    );
  }
}

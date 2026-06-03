import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reusea/services/auth_service.dart';
import 'package:reusea/utils/page_transitions.dart';
import 'package:reusea/utils/theme.dart';
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
                                FadeScaleRoute(page: const SettingsPage()),
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
                                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
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

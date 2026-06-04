import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reusea/services/auth_service.dart';
import 'package:reusea/services/database_service.dart';
import 'package:reusea/utils/theme.dart';
import 'package:reusea/utils/page_transitions.dart';

// Import New Pages
import 'edit_profile_page.dart';
import 'contact_us_page.dart';
import 'feedback_page.dart';
import 'past_buys_page.dart';
import 'past_sells_page.dart';
import 'landing_page.dart';
import 'incoming_orders_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.eco_rounded,
                size: 50,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "ReUsea v1.0.0",
              style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.darkNavy),
            ),
            const SizedBox(height: 10),
            Text(
              "Platform marketplace preloved ramah lingkungan khusus Civitas Akademika Universitas Negeri Surabaya (UNESA). Mendukung program Green Campus dan Circular Economy.",
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                color: AppTheme.secondaryBlue,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const Divider(height: 30, color: AppTheme.bgLight),
            Text(
              "Dikembangkan oleh Tim Kelompok 3 Mobile",
              style: GoogleFonts.lexend(
                color: AppTheme.lightBlueGrey,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Tutup",
                  style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSeedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Seed Data Dummy",
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
        ),
        content: Text(
          "Apakah Anda yakin ingin menambahkan 10 produk dummy (satu untuk setiap kategori) dari berbagai penjual?",
          style: GoogleFonts.lexend(fontSize: 14, color: AppTheme.secondaryBlue),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Batal", style: GoogleFonts.lexend(color: AppTheme.secondaryBlue, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                ),
              );

              try {
                final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                await DatabaseService().seedDummyProducts(currentUserId);
                if (context.mounted) {
                  Navigator.pop(context); // Tutup loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Berhasil memasukkan data produk dummy!", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
                      backgroundColor: AppTheme.ecoTeal,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Tutup loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal memasukkan data: $e"),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text("Ya, Seed", style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Kebijakan Privasi",
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
        ),
        content: SingleChildScrollView(
          child: Text(
            "ReUsea berkomitmen menjaga kerahasiaan data pribadi mahasiswa UNESA. Data seperti Nama, Email Mahasiswa, dan Nomor WhatsApp hanya digunakan untuk keperluan transaksi COD di lingkungan kampus dan tidak akan disebarluaskan kepada pihak ketiga tanpa izin.",
            style: GoogleFonts.lexend(fontSize: 13, color: AppTheme.secondaryBlue, height: 1.5),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text("Tutup", style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showTermsAndConditions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Syarat & Ketentuan",
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
        ),
        content: SingleChildScrollView(
          child: Text(
            "1. Transaksi hanya diperbolehkan bagi Civitas Akademika UNESA.\n2. Pertemuan transaksi (COD) wajib dilakukan di area publik kampus demi keamanan.\n3. Barang yang dijual harus halal, legal, dan sesuai deskripsi kondisi asli.\n4. ReUsea tidak bertanggung jawab atas kerugian transaksi langsung antar pengguna.",
            style: GoogleFonts.lexend(fontSize: 13, color: AppTheme.secondaryBlue, height: 1.5),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text("Tutup", style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showFAQ(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "FAQ / Pertanyaan Umum",
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Q: Bagaimana sistem pembayarannya?",
                style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.darkNavy),
              ),
              const SizedBox(height: 4),
              Text(
                "A: Pembayaran dilakukan secara Cash on Delivery (COD) langsung saat bertemu penjual di kampus.",
                style: GoogleFonts.lexend(fontSize: 11, color: AppTheme.secondaryBlue),
              ),
              const SizedBox(height: 12),
              Text(
                "Q: Dimana lokasi COD yang aman?",
                style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.darkNavy),
              ),
              const SizedBox(height: 4),
              Text(
                "A: Di tempat ramai seperti Rektorat, Perpustakaan, Gazebo Fakultas, atau Kantin Kampus.",
                style: GoogleFonts.lexend(fontSize: 11, color: AppTheme.secondaryBlue),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text("Mengerti", style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _reportIssue(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Laporkan Masalah",
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
        ),
        content: Text(
          "Apakah Anda menemukan kendala teknis atau pengguna yang melanggar aturan? Silakan hubungi admin ReUsea melalui menu Hubungi Kami.",
          style: GoogleFonts.lexend(fontSize: 13, color: AppTheme.secondaryBlue, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: GoogleFonts.lexend(color: AppTheme.secondaryBlue)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                SlideFadeRightRoute(page: const ContactUsPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text("Hubungi", style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _logoutUser(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Keluar Akun",
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
        ),
        content: Text(
          "Apakah Anda yakin ingin keluar dari aplikasi ReUsea?",
          style: GoogleFonts.lexend(fontSize: 14, color: AppTheme.secondaryBlue),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: GoogleFonts.lexend(color: AppTheme.secondaryBlue, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LandingPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text("Keluar", style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String email = user?.email ?? 'student@mhs.unesa.ac.id';
    final String displayName = user?.displayName ?? email.split('@')[0];

    return Scaffold(
      body: OceanGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button & Title Row
                  Row(
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
                        'Pengaturan',
                        style: GoogleFonts.lexend(
                          color: AppTheme.darkNavy,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Profile/Account Summary Card at top
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppTheme.glowShadow(color: AppTheme.primaryBlue),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: AppTheme.bgLight,
                            child: Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
                              style: GoogleFonts.lexend(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: GoogleFonts.lexend(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: GoogleFonts.lexend(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "Mahasiswa UNESA",
                                  style: GoogleFonts.lexend(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // =================== SECTION: AKUN ===================
                  _buildSectionHeader("AKUN"),
                  _buildSettingsGroup([
                    _buildSettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Edit Profil',
                      bgIconColor: Colors.purple.withValues(alpha: 0.1),
                      iconColor: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          SlideFadeRightRoute(page: const EditProfilePage()),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Riwayat Pembelian',
                      bgIconColor: Colors.green.withValues(alpha: 0.1),
                      iconColor: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          SlideFadeRightRoute(page: const PastBuysPage()),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.sell_outlined,
                      title: 'Riwayat Penjualan',
                      bgIconColor: Colors.orange.withValues(alpha: 0.1),
                      iconColor: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          SlideFadeRightRoute(page: const PastSellsPage()),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.inbox_outlined,
                      title: 'Pesanan Masuk',
                      bgIconColor: Colors.teal.withValues(alpha: 0.1),
                      iconColor: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          SlideFadeRightRoute(page: const IncomingOrdersPage()),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifikasi',
                      bgIconColor: Colors.blue.withValues(alpha: 0.1),
                      iconColor: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          SlideFadeRightRoute(page: const NotificationSettingsPage()),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.verified_user_outlined,
                      title: 'Keamanan & Kata Sandi',
                      bgIconColor: AppTheme.sunsetOrange.withValues(alpha: 0.1),
                      iconColor: AppTheme.sunsetOrange,
                      onTap: () {
                        Navigator.push(
                          context,
                          SlideFadeRightRoute(page: const SecuritySettingsPage()),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // =================== SECTION: DUKUNGAN ===================
                  _buildSectionHeader("DUKUNGAN"),
                  _buildSettingsGroup([
                    _buildSettingsTile(
                      icon: Icons.contact_support_outlined,
                      title: 'Hubungi Kami',
                      bgIconColor: Colors.teal.withValues(alpha: 0.1),
                      iconColor: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          SlideFadeRightRoute(page: const ContactUsPage()),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.rate_review_outlined,
                      title: 'Kritik & Saran',
                      bgIconColor: Colors.amber.withValues(alpha: 0.1),
                      iconColor: Colors.amber,
                      onTap: () {
                        Navigator.push(
                          context,
                          SlideFadeRightRoute(page: const FeedbackPage()),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.report_problem_outlined,
                      title: 'Laporkan Masalah',
                      bgIconColor: Colors.redAccent.withValues(alpha: 0.1),
                      iconColor: Colors.redAccent,
                      onTap: () => _reportIssue(context),
                    ),
                    _buildSettingsTile(
                      icon: Icons.question_answer_outlined,
                      title: 'FAQ',
                      bgIconColor: Colors.indigo.withValues(alpha: 0.1),
                      iconColor: Colors.indigo,
                      onTap: () => _showFAQ(context),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // =================== SECTION: APLIKASI ===================
                  _buildSectionHeader("APLIKASI"),
                  _buildSettingsGroup([
                    _buildSettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: 'Tentang ReUsea',
                      bgIconColor: AppTheme.secondaryBlue.withValues(alpha: 0.1),
                      iconColor: AppTheme.secondaryBlue,
                      onTap: () => _showAboutAppDialog(context),
                    ),
                    _buildSettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Kebijakan Privasi',
                      bgIconColor: Colors.blueGrey.withValues(alpha: 0.1),
                      iconColor: Colors.blueGrey,
                      onTap: () => _showPrivacyPolicy(context),
                    ),
                    _buildSettingsTile(
                      icon: Icons.gavel_outlined,
                      title: 'Syarat & Ketentuan',
                      bgIconColor: Colors.brown.withValues(alpha: 0.1),
                      iconColor: Colors.brown,
                      onTap: () => _showTermsAndConditions(context),
                    ),
                    _buildSettingsTile(
                      icon: Icons.cloud_upload_outlined,
                      title: 'Seed Dummy Products',
                      bgIconColor: AppTheme.ecoTeal.withValues(alpha: 0.1),
                      iconColor: AppTheme.ecoTeal,
                      onTap: () => _showSeedDialog(context),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // =================== SECTION: AKSI AKUN ===================
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                    ),
                    child: TextButton.icon(
                      onPressed: () => _logoutUser(context),
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                      label: Text(
                        'Keluar Akun',
                        style: GoogleFonts.lexend(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.lexend(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppTheme.secondaryBlue,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    List<Widget> items = [];
    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(const Divider(height: 1, color: AppTheme.bgLight, indent: 64));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow(),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.03), width: 1.5),
      ),
      child: Column(children: items),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required Color bgIconColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgIconColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.lexend(
          fontWeight: FontWeight.bold,
          color: AppTheme.darkNavy,
          fontSize: 14,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.lightBlueGrey,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}

// ====================================================================
// NOTIFICATION SETTINGS PAGE REDESIGN
// ====================================================================
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _chatNotif = true;
  bool _orderNotif = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OceanGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button and title
                  Row(
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
                        'Notifications',
                        style: GoogleFonts.lexend(
                          color: AppTheme.darkNavy,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Push Notifications toggle list cards
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppTheme.softShadow(),
                      border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.03), width: 1.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        _buildToggleTile(
                          icon: Icons.chat_bubble_outline_rounded,
                          iconColor: AppTheme.primaryBlue,
                          bgIconColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          title: "Notifikasi Chat",
                          subtitle: "Terima pemberitahuan saat ada pesan masuk dari pembeli/penjual",
                          value: _chatNotif,
                          onChanged: (val) => setState(() => _chatNotif = val),
                        ),
                        const Divider(height: 1, color: AppTheme.bgLight, indent: 64),
                        _buildToggleTile(
                          icon: Icons.handshake_outlined,
                          iconColor: AppTheme.ecoTeal,
                          bgIconColor: AppTheme.ecoTeal.withValues(alpha: 0.1),
                          title: "Update Transaksi",
                          subtitle: "Terima pemberitahuan status COD (Processing, Completed, Cancelled)",
                          value: _orderNotif,
                          onChanged: (val) => setState(() => _orderNotif = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required Color bgIconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgIconColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkNavy,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.lexend(
                    color: AppTheme.secondaryBlue,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: AppTheme.primaryBlue,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppTheme.lightBlueGrey.withValues(alpha: 0.4),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// SECURITY & PASSWORD PAGE REDESIGN
// ====================================================================
class SecuritySettingsPage extends StatelessWidget {
  const SecuritySettingsPage({super.key});

  void _sendResetPasswordEmail(BuildContext context, String email) async {
    try {
      await AuthService().resetPassword(email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Link reset password berhasil dikirim! Silakan periksa kotak masuk email UNESA Anda.",
              style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.ecoTeal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mengirim link: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String userEmail = user?.email ?? "student@mhs.unesa.ac.id";

    return Scaffold(
      body: OceanGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button and title
                  Row(
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
                        'Security',
                        style: GoogleFonts.lexend(
                          color: AppTheme.darkNavy,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Shield Illustration
                  Center(
                    child: TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      builder: (context, double val, child) {
                        return Transform.scale(
                          scale: 0.8 + 0.2 * val,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: AppTheme.softShadow(),
                          border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.05), width: 2),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          size: 72,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Registered Email Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppTheme.softShadow(),
                      border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.03), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.email_outlined, color: AppTheme.primaryBlue, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Email Terdaftar",
                                style: GoogleFonts.lexend(
                                  color: AppTheme.secondaryBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userEmail,
                                style: GoogleFonts.lexend(
                                  color: AppTheme.darkNavy,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Reset password button
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.glowShadow(color: AppTheme.primaryBlue),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _sendResetPasswordEmail(context, userEmail),
                      icon: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 22),
                      label: Text(
                        "Atur Ulang Password",
                        style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Soft safety info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.sunsetOrange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.sunsetOrange.withValues(alpha: 0.15), width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppTheme.sunsetOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Sistem akan mengirimkan tautan enkripsi pengubahan kata sandi langsung ke email resmi UNESA Anda demi menjaga keamanan akun.",
                            style: GoogleFonts.lexend(
                              color: AppTheme.darkNavy.withValues(alpha: 0.8),
                              fontSize: 11,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

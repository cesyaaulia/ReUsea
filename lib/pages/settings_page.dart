import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reusea/services/auth_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // ====================================================================
  // TODO 2: DIALOG POPUP ABOUT APP (IDENTITAS PROYEK UNESA)
  // ====================================================================
  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFE9E2D7),
              child: Icon(
                Icons.eco_rounded,
                size: 45,
                color: Color(0xFF1A2235),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "ReUsea v1.0.0",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(
              "Platform marketplace preloved ramah lingkungan khusus Civitas Akademika Universitas Negeri Surabaya (UNESA). Mendukung program Green Campus dan Circular Economy.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const Divider(height: 30),
            Text(
              "Dikembangkan oleh Tim Kelompok 3 Mobile",
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2235),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Tutup",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F1EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F1EE),
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
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. PUSH NOTIFICATIONS
              _buildSettingsTile(
                Icons.notifications_none,
                'Push Notifications',
                Colors.blue.shade50,
                Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationSettingsPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),

              // 2. SECURITY & PASSWORD
              _buildSettingsTile(
                Icons.verified_user_outlined,
                'Security & Password',
                Colors.orange.shade50,
                Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SecuritySettingsPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),

              // 4. ABOUT APP
              _buildSettingsTile(
                Icons.info_outline,
                'About App',
                Colors.grey.shade100,
                Colors.grey.shade700,
                onTap: () => _showAboutAppDialog(context),
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    Color bgIconColor,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgIconColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}

// ====================================================================
// TODO 3: IMPLEMENTASI HALAMAN PENGATURAN NOTIFIKASI
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
      backgroundColor: const Color(0xFFF2F1EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F1EE),
        title: const Text(
          "Push Notifications",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text(
                  "Notifikasi Chat",
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                subtitle: const Text(
                  "Terima pemberitahuan saat ada pesan masuk dari pembeli/penjual",
                ),
                value: _chatNotif,
                activeColor: const Color(0xFF1A2235),
                onChanged: (val) => setState(() => _chatNotif = val),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text(
                  "Update Transaksi",
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                subtitle: const Text(
                  "Terima pemberitahuan status COD (Processing, Completed, Cancelled)",
                ),
                value: _orderNotif,
                activeColor: const Color(0xFF1A2235),
                onChanged: (val) => setState(() => _orderNotif = val),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================================================================
// TODO 4: IMPLEMENTASI HALAMAN KEAMANAN & PASSWORD (SINKRONISASI FIREBASE)
// ====================================================================
class SecuritySettingsPage extends StatelessWidget {
  const SecuritySettingsPage({super.key});

  void _sendResetPasswordEmail(BuildContext context, String email) async {
    try {
      await AuthService().resetPassword(email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Link reset password berhasil dikirim! Silakan periksa kotak masuk email UNESA Anda.",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mengirim link: $e"),
            backgroundColor: Colors.redAccent,
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
      backgroundColor: const Color(0xFFF2F1EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F1EE),
        title: const Text(
          "Security & Password",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, color: Colors.grey),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Email Terdaftar",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _sendResetPasswordEmail(context, userEmail),
                icon: const Icon(Icons.lock_reset_rounded, color: Colors.white),
                label: const Text(
                  "Atur Ulang Password",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2235),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "*Sistem akan mengirimkan tautan enkripsi pengubahan kata sandi langsung ke email resmi UNESA Anda demi menjaga keamanan akun.",
                style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:reusea/services/auth_service.dart';
import 'package:reusea/utils/page_transitions.dart';
import 'main_navigation.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final AuthService _authService = AuthService();
  bool _isChecking = false;

  void _verifyEmailStatus() async {
    setState(() => _isChecking = true);

    bool isVerified = await _authService.checkEmailVerification();

    setState(() => _isChecking = false);

    if (isVerified) {
      // Jika terbukti sudah klik link di Gmail, langsung masuk aplikasi utama
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          ElegantFadeRoute(page: const MainNavigation()),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Email belum diverifikasi. Buka Gmail dan klik tautan dari Firebase dahulu!",
            ),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_unread_outlined,
              size: 100,
              color: Color(0xFFBC8E52),
            ),
            const SizedBox(height: 30),
            const Text(
              "Verifikasi Akun",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            const Text(
              "Kami telah mengirimkan tautan verifikasi ke email mahasiswa UNESA Anda.\n\nSilakan buka kotak masuk Gmail Anda, klik tautan tersebut, kemudian kembali ke aplikasi ini.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isChecking ? null : _verifyEmailStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBC8E52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isChecking
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Saya Sudah Klik Tautan Verifikasi",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

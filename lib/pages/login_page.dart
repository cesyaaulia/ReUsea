import 'package:flutter/material.dart';
import 'package:reusea/services/auth_service.dart';
import 'package:reusea/utils/page_transitions.dart';
import 'register_page.dart';
import 'main_navigation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _resetEmailController =
      TextEditingController(); // Controller untuk email reset
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose(); // Bersihkan controller reset email
    super.dispose();
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);

    await _authService.loginWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      onSuccess: (user) {
        setState(() => _isLoading = false);
        // Berhasil login, arahkan ke navigasi utama
        Navigator.pushReplacement(
          context,
          ElegantFadeRoute(page: const MainNavigation()),
        );
      },
      onError: (errorMessage) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      },
    );
  }

  // ====================================================================
  // FUNGSI POPUP DIALOG FORGOT PASSWORD
  // ====================================================================
  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          "Lupa Password?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Masukkan email UNESA Anda. Kami akan mengirimkan tautan untuk mengatur ulang kata sandi.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "student@mhs.unesa.ac.id",
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _resetEmailController.clear();
              Navigator.pop(context);
            },
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              String email = _resetEmailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Email tidak boleh kosong!")),
                );
                return;
              }

              try {
                Navigator.pop(context); // Tutup dialog

                // Memanggil fungsi reset dari AuthService tim kamu
                // Catatan: Pastikan fungsi 'resetPassword' sudah kamu tambahkan di auth_service.dart sebelumnya
                await _authService.resetPassword(email);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Link reset password telah dikirim ke email Anda!",
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                _resetEmailController.clear();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBC8E52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Kirim", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Text(
                "Login",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 40),
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFFE9E2D7),
                child: Icon(Icons.school, size: 50, color: Color(0xFFBC8E52)),
              ),
              const SizedBox(height: 24),
              const Text(
                "Welcome back!",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Login with your official UNESA account",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              _buildTextField(
                "UNESA Email",
                "student@mhs.unesa.ac.id",
                Icons.email_outlined,
                _emailController,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                "Password",
                "********",
                Icons.lock_outline,
                _passwordController,
                isPassword: true,
              ),

              // ========================================================
              // SISIPAN TOMBOL TEXT FORGOT PASSWORD (PAS SESUAI DESAIN)
              // ========================================================
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _showForgotPasswordDialog,
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Color(0xFFBC8E52),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25), // Jarak seimbang menuju button login

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBC8E52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      SlideRightRoute(page: const RegisterPage()),
                    ),
                    child: const Text(
                      "Register",
                      style: TextStyle(
                        color: Color(0xFFBC8E52),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ],
    );
  }
}

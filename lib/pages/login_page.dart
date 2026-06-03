import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reusea/services/auth_service.dart';
import 'package:reusea/utils/page_transitions.dart';
import 'package:reusea/utils/theme.dart';
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
  final TextEditingController _resetEmailController = TextEditingController(); 
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose(); 
    super.dispose();
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);

    await _authService.loginWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      onSuccess: (user) {
        setState(() => _isLoading = false);
        TextInput.finishAutofillContext(shouldSave: true);
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
            backgroundColor: AppTheme.coralPeach,
          ),
        );
      },
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              style: TextStyle(fontSize: 13, color: AppTheme.secondaryBlue),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _resetEmailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.darkNavy),
              decoration: InputDecoration(
                hintText: "student@mhs.unesa.ac.id",
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
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
                Navigator.pop(context); 

                await _authService.resetPassword(email);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Link reset password telah dikirim ke email Anda!"),
                      backgroundColor: AppTheme.ecoTeal,
                    ),
                  );
                }
                _resetEmailController.clear();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppTheme.coralPeach,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
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
      backgroundColor: Colors.transparent,
      body: OceanGradientBackground(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  // Logo/Avatar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.oceanWaveGradient,
                    ),
                    child: const CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.eco_rounded, size: 48, color: AppTheme.primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "ReUsea",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.darkNavy,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Login with your official UNESA account",
                    style: TextStyle(
                      color: AppTheme.secondaryBlue.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Glassmorphism Form Card
                  GlassContainer(
                    radius: 28,
                    blur: 20,
                    opacity: 0.75,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        AutofillGroup(
                          child: Column(
                            children: [
                              _buildTextField(
                                "UNESA Email",
                                "student@mhs.unesa.ac.id",
                                Icons.email_outlined,
                                _emailController,
                                autofillHints: const [AutofillHints.email, AutofillHints.username],
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                "Password",
                                "********",
                                Icons.lock_outline,
                                _passwordController,
                                isPassword: true,
                                autofillHints: const [AutofillHints.password],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _showForgotPasswordDialog,
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login Button with scale and gradient
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: AppTheme.glowShadow(color: AppTheme.primaryBlue),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                        "Login",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: AppTheme.secondaryBlue, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          SlideRightRoute(page: const RegisterPage()),
                        ),
                        child: const Text(
                          "Register",
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildTextField(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
    Iterable<String>? autofillHints,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkNavy),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.softShadow(),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword ? _obscurePassword : false,
            autofillHints: autofillHints,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.darkNavy),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppTheme.secondaryBlue.withValues(alpha: 0.4), fontWeight: FontWeight.w500),
              prefixIcon: Icon(icon, color: AppTheme.secondaryBlue.withValues(alpha: 0.7)),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: AppTheme.secondaryBlue.withValues(alpha: 0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    )
                  : null,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

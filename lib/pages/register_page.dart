import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reusea/services/auth_service.dart';
import 'package:reusea/utils/page_transitions.dart';
import 'package:reusea/utils/theme.dart';
import 'otp_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    setState(() => _isLoading = true);

    await _authService.registerWithEmail(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      onSuccess: () {
        setState(() => _isLoading = false);
        TextInput.finishAutofillContext(shouldSave: true);
        Navigator.push(
          context,
          SlideUpRoute(page: const OtpPage()),
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
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.eco_rounded, size: 40, color: AppTheme.primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Join ReUsea",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.darkNavy,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Please use your official UNESA email\nto verify your status.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.secondaryBlue.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 28),

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
                              _buildField(
                                "Full Name",
                                "Enter your full name",
                                Icons.person_outline_rounded,
                                _nameController,
                                autofillHints: const [AutofillHints.name],
                              ),
                              const SizedBox(height: 16),
                              _buildField(
                                "UNESA Email",
                                "student@mhs.unesa.ac.id",
                                Icons.email_outlined,
                                _emailController,
                                autofillHints: const [AutofillHints.email, AutofillHints.username],
                              ),
                              const SizedBox(height: 16),
                              _buildField(
                                "Password",
                                "Create a strong password",
                                Icons.lock_outline,
                                _passwordController,
                                isPassword: true,
                                autofillHints: const [AutofillHints.newPassword],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Register Button with scale and gradient
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
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
                                        "Create Account",
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
                  const SizedBox(height: 24),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Already have an account? Login",
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
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

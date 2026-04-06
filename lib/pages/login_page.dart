import 'package:flutter/material.dart';
import 'register_page.dart';
import 'main_navigation.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 80),
            const Text("Login", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 40),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFE9E2D7),
              child: Icon(Icons.school, size: 50, color: Color(0xFFBC8E52)),
            ),
            const SizedBox(height: 24),
            const Text("Welcome back!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const Text("Login with your official UNESA account", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            _buildTextField("UNESA Email", "student@mhs.unesa.ac.id", Icons.email_outlined),
            const SizedBox(height: 20),
            _buildTextField("Password", "********", Icons.lock_outline, isPassword: true),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () {}, child: const Text("Forgot password?", style: TextStyle(color: Color(0xFFBC8E52)))),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBC8E52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Login", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())),
                  child: const Text("Register", style: TextStyle(color: Color(0xFFBC8E52), fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, IconData icon, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: isPassword ? const Icon(Icons.visibility_off_outlined) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ],
    );
  }
}
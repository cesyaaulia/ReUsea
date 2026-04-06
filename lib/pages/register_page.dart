import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Text("Register", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 30),
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFE9E2D7),
              child: Icon(Icons.school, size: 40, color: Color(0xFFBC8E52)),
            ),
            const SizedBox(height: 20),
            const Text("Join ReUsea", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const Text("Please use your official UNESA email\nto verify your status.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            _buildField("Full Name", "Enter your full name", Icons.person_outline),
            const SizedBox(height: 15),
            _buildField("UNESA Email", "student@mhs.unesa.ac.id", Icons.email_outlined),
            const SizedBox(height: 15),
            _buildField("Password", "Create a strong password", Icons.lock_outline, isPassword: true),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBC8E52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("Create Account", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Already have an account? Login", style: TextStyle(color: Color(0xFFBC8E52))),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint, IconData icon, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          obscureText: isPassword,
          decoration: InputDecoration(
            filled: true, fillColor: Colors.white,
            hintText: hint, prefixIcon: Icon(icon),
            suffixIcon: isPassword ? const Icon(Icons.visibility_outlined) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
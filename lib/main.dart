import 'package:flutter/material.dart';
import 'package:reusea/views/home_page.dart'; 

void main() {
  runApp(const ReUseaApp());
}

class ReUseaApp extends StatelessWidget {
  const ReUseaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReUsea App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        // Menggunakan primary color hijau neon sesuai desain Figma kamu
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2ECC71),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A1A12),
        useMaterial3: true,
      ),
      // Di sini kita panggil class HomePage dari desain yang saya buatkan tadi
      home: const HomePage(), 
    );
  }
}
import 'package:flutter/material.dart';
import 'package:reusea/pages/login_page.dart';

void main() {
  runApp(const ReUseaApp());
}

class ReUseaApp extends StatelessWidget {
  const ReUseaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF9F7F4), 
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
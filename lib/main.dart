import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const ReUseaApp());
}

class ReUseaApp extends StatelessWidget {
  const ReUseaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ReUsea',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Sans-Serif', 
      ),
      home: const LoginPage(),
    );
  }
}
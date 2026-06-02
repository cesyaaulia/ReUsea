import 'package:flutter/material.dart';
import 'package:reusea/pages/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // Pastikan binding Flutter sudah siap sebelum memanggil Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ReUseaApp());
}

class ReUseaApp extends StatelessWidget {
  const ReUseaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReUsea',
      initialRoute: '/', // Halaman pertama kali dibuka
      routes: {
        '/login': (context) =>
            const LoginPage(), // Daftarkan rute login di sini
      },
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

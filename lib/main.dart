import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reusea/pages/login_page.dart';
import 'package:reusea/pages/main_navigation.dart';
import 'package:reusea/pages/landing_page.dart';
import 'firebase_options.dart';
import 'dart:ui';

void main() async {
  // Overiding target platform ke android di web agar google_maps_flutter_web terdaftar
  if (kIsWeb) {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  }

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
        '/login': (context) => const LoginPage(), // Daftarkan rute login di sini
        '/landing': (context) => const LandingPage(), // Daftarkan rute landing page
      },
      debugShowCheckedModeBanner: false,

      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),

      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF2F1EE),
        primaryColor: const Color(0xFF1A2235),
        useMaterial3: true,
        textTheme: GoogleFonts.lexendTextTheme(
          ThemeData.light().textTheme.apply(
            bodyColor: const Color(0xFF0F172A),
            displayColor: const Color(0xFF0F172A),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF1A2235)),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const MainNavigation();
          }
          return const LandingPage();
        },
      ),
    );
  }
}


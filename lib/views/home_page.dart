import 'package:flutter/material.dart';
// Pastikan file profile_page.dart kamu sudah ada di folder views
import 'package:reusea/views/profile_page.dart'; 

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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A1A12),
      ),
      // Kita panggil MainNavigation sebagai home
      home: const MainNavigation(),
    );
  }
}

// Ini adalah Wrapper untuk Navigasi
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0; // Index untuk melacak halaman aktif

  // List halaman yang akan ditampilkan
  final List<Widget> _pages = [
    const HomePageContent(), // Isi halaman Home
    const Center(child: Text('Chat Page')),
    const Center(child: Text('My Items Page')),
    const ProfilePage(), // Halaman Profil kamu yang di file terpisah
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Mengubah halaman saat icon diklik
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF2ECC71),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 35, color: Colors.black),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF0A1A12),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_filled, 'Home', 0),
              _buildNavItem(Icons.chat_bubble_outline, 'Chat', 1),
              const SizedBox(width: 40),
              _buildNavItem(Icons.storefront_outlined, 'My Items', 2),
              _buildNavItem(Icons.person_outline, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF2ECC71) : Colors.grey),
          Text(label, style: TextStyle(color: isSelected ? const Color(0xFF2ECC71) : Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}

// Pindahkan isi body Home kamu ke sini
class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: Colors.transparent, // Agar ikut background MainNavigation
       appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('ReUsea', style: TextStyle(color: Color(0xFF2ECC71), fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search preloved items...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF14261D),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            // ... (Sisanya sama seperti kode Home kamu sebelumnya)
            const Text('Fresh Listings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 16, mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(color: const Color(0xFF14261D), borderRadius: BorderRadius.circular(12)),
          child: const Center(child: Icon(Icons.image, color: Colors.white24)),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:reusea/utils/page_transitions.dart';
import 'home_page.dart';
import 'chat_page.dart';
import 'my_items_page.dart';
import 'profile_page.dart';
import 'sell_item_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  int _previousIndex = 0;

  // Daftar halaman utama Bottom Navigation Bar ReUsea
  final List<Widget> _pages = [
    const HomePage(), // Sekarang memanggil file terpisah
    const ChatPage(),
    const MyItemsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          // Tentukan arah slide berdasarkan index tab
          final isForward = _selectedIndex > _previousIndex;
          final slideAnimation = Tween<Offset>(
            begin: Offset(isForward ? 0.15 : -0.15, 0.0),
            end: Offset.zero,
          ).animate(animation);

          return SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _pages[_selectedIndex],
        ),
      ),
      // TOMBOL PLUS TENGAH MELAYANG (Desain Hijau Khas Eco-Friendly)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            SlideUpRoute(page: const SellItemPage()),
          );
        },
        backgroundColor: const Color(0xFF1A2235),
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // BOTTOM BAR DENGAN CEKUNGAN TENGAH (CircularNotchedRectangle)
      bottomNavigationBar: BottomAppBar(
        padding: EdgeInsets.zero,
        height: 70,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
            _buildNavItem(
              Icons.chat_bubble_outline,
              Icons.chat_bubble,
              'Chat',
              1,
            ),
            const SizedBox(width: 40), // Ruang kosong khusus untuk cekungan FAB
            _buildNavItem(
              Icons.storefront_outlined,
              Icons.storefront,
              'My Items',
              2,
            ),
            _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 3),
          ],
        ),
      ),
    );
  }

  // Helper Widget pembentuk item menu navigasi bawah
  Widget _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
  ) {
    bool isSelected = _selectedIndex == index;
    Color activeColor = const Color(0xFF1A2235); // Warna navy premium ReUsea

    return InkWell(
      onTap: () => setState(() {
        _previousIndex = _selectedIndex;
        _selectedIndex = index;
      }),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? activeColor : Colors.grey,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : Colors.grey,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

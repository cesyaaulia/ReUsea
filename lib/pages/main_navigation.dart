import 'package:flutter/material.dart';
import 'package:reusea/models/product_model.dart'; 
import 'package:reusea/pages/profile_page.dart'; 
import 'package:reusea/pages/my_items_page.dart';
import 'package:reusea/pages/sell_item_page.dart';
import 'package:reusea/pages/chat_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePageContent(),
    const ChatPage(),
    const MyItemsPage(),
    const ProfilePage(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigasi pindah halaman ke SellItemPage
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SellItemPage()),
          );
        },
        backgroundColor: const Color(0xFF7BA699), 
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
            _buildNavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat', 1),
            const SizedBox(width: 40), 
            _buildNavItem(Icons.storefront_outlined, Icons.storefront, 'My Items', 2),
            _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    Color activeColor = const Color(0xFFBC8E52); 
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? activeIcon : icon, color: isSelected ? activeColor : Colors.grey),
          Text(label, style: TextStyle(
            color: isSelected ? activeColor : Colors.grey, 
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
          )),
        ],
      ),
    );
  }
}

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  String _selectedCategory = "All Items";
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text('ReUsea', style: TextStyle(
          color: Color(0xFFBC8E52),
          fontWeight: FontWeight.bold, 
          fontSize: 22
        )),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none_outlined, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                // SUDAH DIGANTI KE withValues
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search preloved items...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 25),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip("All Items"),
                  _buildCategoryChip("Books"),
                  _buildCategoryChip("Electronics"),
                  _buildCategoryChip("Fashion"),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text('Fresh Listings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        child: Chip(
          label: Text(label),
          backgroundColor: isSelected ? const Color(0xFFBC8E52) : Colors.grey[200],
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    var filteredProducts = _selectedCategory == "All Items" 
        ? dummyProducts 
        : dummyProducts.where((product) => product.category.toUpperCase() == _selectedCategory.toUpperCase()).toList();

    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts
          .where((product) => product.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredProducts.length, 
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 16, mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            // SUDAH DIGANTI KE withValues
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    image: DecorationImage(image: AssetImage(product.imagePath), fit: BoxFit.cover),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.category, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(product.price, style: const TextStyle(color: Color(0xFFBC8E52), fontWeight: FontWeight.bold)),
                        Text(product.time, style: const TextStyle(color: Colors.grey, fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
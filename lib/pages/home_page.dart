import 'package:flutter/material.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1410),
      body: _index == 0 ? const HomePage() : Center(child: Text("Page $_index", style: const TextStyle(color: Colors.white))),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (val) => setState(() => _index = val),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFBC8E52),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: "Sell"),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: "My Items"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("ReUsea", style: TextStyle(color: Color(0xFF4CAF50), fontSize: 24, fontWeight: FontWeight.bold)),
                const Icon(Icons.notifications_outlined, color: Colors.black, size: 28),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: "Search preloved items...",
                prefixIcon: const Icon(Icons.search),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ["All Items", "Books", "Electronics", "Fashion"].map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Chip(label: Text(cat), backgroundColor: cat == "All Items" ? const Color(0xFFBC8E52) : const Color(0xFFE9E2D7)),
                )).toList(),
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 15, mainAxisSpacing: 15),
              itemCount: 4,
              itemBuilder: (context, i) => _buildProductCard(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Container(decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(15)))),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("BOOKS", style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text("Calculus Vol. 1", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Rp 120.000", style: TextStyle(color: Color(0xFFBC8E52), fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
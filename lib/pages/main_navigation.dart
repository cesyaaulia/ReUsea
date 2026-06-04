import 'package:flutter/material.dart';
import 'package:reusea/utils/page_transitions.dart';
import 'package:reusea/utils/theme.dart';
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
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(
        onProfileTap: () {
          setState(() {
            _previousIndex = _selectedIndex;
            _selectedIndex = 3;
          });
        },
      ),
      const ChatPage(),
      const MyItemsPage(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Memungkinkan body menggantung di belakang Bottom Bar melayang
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
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
      bottomNavigationBar: Container(
        color: Colors.transparent,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SafeArea(
          bottom: true,
          child: GlassContainer(
            radius: 28,
            blur: 15,
            opacity: 0.65,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, Icons.home_rounded, 'Home', 0),
                _buildNavItem(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chat', 1),
                
                // Tombol Sell di Tengah
                AnimatedSellButton(
                  onTap: () {
                    Navigator.push(
                      context,
                      SlideUpRoute(page: const SellItemPage()),
                    );
                  },
                ),
                
                _buildNavItem(Icons.storefront_outlined, Icons.storefront_rounded, 'My Items', 2),
                _buildNavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
  ) {
    bool isSelected = _selectedIndex == index;
    Color activeColor = AppTheme.primaryBlue;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          _previousIndex = _selectedIndex;
          _selectedIndex = index;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? activeColor : AppTheme.secondaryBlue.withValues(alpha: 0.7),
                  size: 24,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : AppTheme.secondaryBlue.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol Sell di Tengah dengan Skala Animasi & Wave Glow
class AnimatedSellButton extends StatefulWidget {
  final VoidCallback onTap;
  const AnimatedSellButton({super.key, required this.onTap});

  @override
  State<AnimatedSellButton> createState() => _AnimatedSellButtonState();
}

class _AnimatedSellButtonState extends State<AnimatedSellButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.85),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.primaryGradient,
            boxShadow: AppTheme.glowShadow(color: AppTheme.primaryBlue),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reusea/utils/theme.dart';
import 'package:reusea/utils/page_transitions.dart';
import 'login_page.dart';

// ============================================================================
// REUSEA PREMIUM LANDING PAGE
// Designed with Apple & Dribbble quality standards.
// Features: Responsive layout, Custom Paint Logo & Waves, Floating 3D Cards,
// Tilt hover interactions, and Animated Counter statistics.
// ============================================================================

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _bubbleController;

  // Keys to scroll to specific sections
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _benefitsKey = GlobalKey();
  final GlobalKey _categoriesKey = GlobalKey();
  final GlobalKey _impactKey = GlobalKey();
  final GlobalKey _testimonialsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Animation controller for floating bubbles / particles
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main Scrollable Content
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeroSection(context, isMobile, screenWidth),
                _buildWaveTransition(AppTheme.primaryGradient.colors[1], Colors.white),
                _buildHowItWorksSection(isMobile),
                _buildWaveTransition(Colors.white, AppTheme.bgLight, inverted: true),
                _buildBenefitsSection(isMobile),
                _buildWaveTransition(AppTheme.bgLight, Colors.white),
                _buildCategoriesSection(isMobile),
                _buildImpactSection(isMobile),
                _buildTestimonialsSection(isMobile),
                _buildFooterSection(isMobile),
              ],
            ),
          ),

          // Floating Glassmorphic Navbar at the top
          Positioned(
            top: 16,
            left: isMobile ? 16 : 32,
            right: isMobile ? 16 : 32,
            child: _buildNavbar(context, isMobile),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // NAVBAR WIDGET
  // ============================================================================
  Widget _buildNavbar(BuildContext context, bool isMobile) {
    return SafeArea(
      child: GlassContainer(
        radius: 24,
        blur: 15,
        opacity: 0.7,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo & Brand Name
            GestureDetector(
              onTap: () => _scrollController.animateTo(0,
                  duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
              child: Row(
                children: [
                  CustomPaint(
                    size: const Size(36, 36),
                    painter: ReUseaLogoPainter(showBackground: true),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ReUsea',
                    style: GoogleFonts.lexend(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkNavy,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Links (Desktop only)
            if (!isMobile)
              Row(
                children: [
                  _buildNavLink('How It Works', () => _scrollToSection(_howItWorksKey)),
                  _buildNavLink('Benefits', () => _scrollToSection(_benefitsKey)),
                  _buildNavLink('Categories', () => _scrollToSection(_categoriesKey)),
                  _buildNavLink('Impact', () => _scrollToSection(_impactKey)),
                  _buildNavLink('Testimonials', () => _scrollToSection(_testimonialsKey)),
                ],
              ),

            // Sign In Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  ElegantFadeRoute(page: const LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppTheme.primaryBlue.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Sign In',
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavLink(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.secondaryBlue,
        ),
        child: Text(
          label,
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // HERO SECTION
  // ============================================================================
  Widget _buildHeroSection(BuildContext context, bool isMobile, double screenWidth) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Stack(
        children: [
          // Bubble 1 (Aqua)
          Positioned(
            top: 150,
            left: screenWidth * 0.1,
            child: AnimatedBuilder(
              animation: _bubbleController,
              builder: (context, _) {
                double floatOffset = 20 * math.sin(_bubbleController.value * 2 * math.pi);
                return Transform.translate(
                  offset: Offset(0, floatOffset),
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.aquaTurquoise.withValues(alpha: 0.35),
                          AppTheme.aquaTurquoise.withValues(alpha: 0.05),
                        ],
                        center: const Alignment(-0.3, -0.3),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bubble 2 (Coral)
          Positioned(
            top: 400,
            left: screenWidth * 0.8,
            child: AnimatedBuilder(
              animation: _bubbleController,
              builder: (context, _) {
                double floatOffset = 15 * math.cos(_bubbleController.value * 2 * math.pi);
                return Transform.translate(
                  offset: Offset(0, floatOffset),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.coralPeach.withValues(alpha: 0.35),
                          AppTheme.coralPeach.withValues(alpha: 0.05),
                        ],
                        center: const Alignment(-0.3, -0.3),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bubble 3 (Yellow)
          Positioned(
            top: 600,
            left: screenWidth * 0.25,
            child: AnimatedBuilder(
              animation: _bubbleController,
              builder: (context, _) {
                double floatOffset = 25 * math.sin(_bubbleController.value * 2 * math.pi + 1);
                return Transform.translate(
                  offset: Offset(0, floatOffset),
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.sunYellow.withValues(alpha: 0.35),
                          AppTheme.sunYellow.withValues(alpha: 0.05),
                        ],
                        center: const Alignment(-0.3, -0.3),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bubble 4 (Teal)
          Positioned(
            top: 250,
            left: screenWidth * 0.65,
            child: AnimatedBuilder(
              animation: _bubbleController,
              builder: (context, _) {
                double floatOffset = 15 * math.cos(_bubbleController.value * 2 * math.pi * 1.5);
                return Transform.translate(
                  offset: Offset(0, floatOffset),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.ecoTeal.withValues(alpha: 0.35),
                          AppTheme.ecoTeal.withValues(alpha: 0.05),
                        ],
                        center: const Alignment(-0.3, -0.3),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Main Hero Column
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 160, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Centered Large Logo with Ripple Animation
                const Center(
                  child: HeroLogoWidget(),
                ),
                const SizedBox(height: 32),

                // 2. Headline
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFE2E8F0), AppTheme.lightBlueGrey],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: Text(
                    "Give Things a Second Life",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: isMobile ? 38 : 64,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -1.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Subheadline
                Container(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Text(
                    "Buy and sell preloved items within your university community. Save money, reduce waste, and support sustainability.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: isMobile ? 15 : 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // 4. CTA Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          ElegantFadeRoute(page: const LoginPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.coralPeach,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: AppTheme.coralPeach.withValues(alpha: 0.4),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 24 : 36,
                          vertical: isMobile ? 18 : 22,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Get Started',
                            style: GoogleFonts.lexend(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 15 : 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          ElegantFadeRoute(page: const LoginPage()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30, width: 2),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 20 : 32,
                          vertical: isMobile ? 18 : 22,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Explore Marketplace',
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 15 : 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),

                // 5. Hero Illustration: Floating 3D items above waves
                FloatingHeroIllustration(isMobile: isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HOW IT WORKS SECTION
  // ============================================================================
  Widget _buildHowItWorksSection(bool isMobile) {
    return Container(
      key: _howItWorksKey,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          _buildSectionHeader(
            category: "PROCESS",
            title: "How It Works",
            subtitle: "Start your circular economy journey in 3 simple steps",
          ),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              if (isMobile) {
                return Column(
                  children: [
                    _buildStepCard(
                      step: "01",
                      title: "Upload Your Item",
                      description: "Snap photos, set your student-friendly price, and add a brief description of your preloved item.",
                      icon: Icons.camera_enhance_rounded,
                      color: AppTheme.coralPeach,
                    ),
                    const SizedBox(height: 32),
                    _buildStepCard(
                      step: "02",
                      title: "Find Interested Students",
                      description: "Chat securely with other university students on campus. Negotiate prices and arrange a meeting spot.",
                      icon: Icons.forum_rounded,
                      color: AppTheme.aquaTurquoise,
                    ),
                    const SizedBox(height: 32),
                    _buildStepCard(
                      step: "03",
                      title: "Complete The Transaction",
                      description: "Meet up safely at designated campus areas (like Ketintang/Lidah Wetan) and hand over the item.",
                      icon: Icons.handshake_rounded,
                      color: AppTheme.sunYellow,
                    ),
                  ],
                );
              } else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildStepCard(
                        step: "01",
                        title: "Upload Your Item",
                        description: "Snap photos, set your student-friendly price, and add a brief description of your preloved item.",
                        icon: Icons.camera_enhance_rounded,
                        color: AppTheme.coralPeach,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildStepCard(
                        step: "02",
                        title: "Find Interested Students",
                        description: "Chat securely with other university students on campus. Negotiate prices and arrange a meeting spot.",
                        icon: Icons.forum_rounded,
                        color: AppTheme.aquaTurquoise,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildStepCard(
                        step: "03",
                        title: "Complete The Transaction",
                        description: "Meet up safely at designated campus areas (like Ketintang/Lidah Wetan) and hand over the item.",
                        icon: Icons.handshake_rounded,
                        color: AppTheme.sunYellow,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return HoverCard(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.radiusXL,
          boxShadow: AppTheme.softShadow(color: AppTheme.secondaryBlue),
          border: Border.all(color: AppTheme.lightBlueGrey.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Step Number Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    step,
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                // Icon
                Icon(icon, size: 36, color: color),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: GoogleFonts.lexend(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkNavy,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: GoogleFonts.lexend(
                fontSize: 14,
                color: AppTheme.secondaryBlue,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // BENEFITS SECTION
  // ============================================================================
  Widget _buildBenefitsSection(bool isMobile) {
    return Container(
      key: _benefitsKey,
      color: AppTheme.bgLight,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          _buildSectionHeader(
            category: "BENEFITS",
            title: "Built For University Life",
            subtitle: "Solve local waste, support each other, and enjoy a sustainable lifestyle",
          ),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              if (isMobile) {
                return Column(
                  children: [
                    _buildBenefitItem(
                      icon: Icons.savings_rounded,
                      title: "Save Money",
                      description: "Buy textbooks, gadgets, and furniture at a fraction of their retail price. Perfect for student budgets.",
                      color: AppTheme.sunYellow,
                    ),
                    const SizedBox(height: 24),
                    _buildBenefitItem(
                      icon: Icons.delete_sweep_rounded,
                      title: "Reduce Waste",
                      description: "Prevent functioning items from reaching local landfills. Keep the resource loop circular and active.",
                      color: AppTheme.ecoTeal,
                    ),
                    const SizedBox(height: 24),
                    _buildBenefitItem(
                      icon: Icons.eco_rounded,
                      title: "Support Sustainability",
                      description: "Contribute to building a green campus. Every reused item lowers the carbon footprint of production.",
                      color: AppTheme.aquaTurquoise,
                    ),
                    const SizedBox(height: 24),
                    _buildBenefitItem(
                      icon: Icons.school_rounded,
                      title: "Help Fellow Students",
                      description: "Make university transition smoother for juniors by passing down your study and living essentials.",
                      color: AppTheme.coralPeach,
                    ),
                  ],
                );
              } else {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 1.6,
                  children: [
                    _buildBenefitItem(
                      icon: Icons.savings_rounded,
                      title: "Save Money",
                      description: "Buy textbooks, gadgets, and furniture at a fraction of their retail price. Perfect for student budgets.",
                      color: AppTheme.sunYellow,
                    ),
                    _buildBenefitItem(
                      icon: Icons.delete_sweep_rounded,
                      title: "Reduce Waste",
                      description: "Prevent functioning items from reaching local landfills. Keep the resource loop circular and active.",
                      color: AppTheme.ecoTeal,
                    ),
                    _buildBenefitItem(
                      icon: Icons.eco_rounded,
                      title: "Support Sustainability",
                      description: "Contribute to building a green campus. Every reused item lowers the carbon footprint of production.",
                      color: AppTheme.aquaTurquoise,
                    ),
                    _buildBenefitItem(
                      icon: Icons.school_rounded,
                      title: "Help Fellow Students",
                      description: "Make university transition smoother for juniors by passing down your study and living essentials.",
                      color: AppTheme.coralPeach,
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return HoverCard(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.radiusXL,
          boxShadow: AppTheme.softShadow(color: AppTheme.secondaryBlue),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lexend(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      color: AppTheme.secondaryBlue,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // CATEGORIES SECTION (WITH 3D TILT CARDS)
  // ============================================================================
  Widget _buildCategoriesSection(bool isMobile) {
    final List<Map<String, dynamic>> categoriesList = [
      {
        "title": "Books & Notes",
        "emoji": "📚",
        "desc": "Textbooks, course guides, novels",
        "gradient": const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFFA8A4FF)]),
      },
      {
        "title": "Electronics",
        "emoji": "💻",
        "desc": "Laptops, phones, accessories",
        "gradient": const LinearGradient(colors: [Color(0xFF0984E3), Color(0xFF74B9FF)]),
      },
      {
        "title": "Fashion",
        "emoji": "👕",
        "desc": "Jackets, shirts, varsity wear",
        "gradient": const LinearGradient(colors: [Color(0xFFFD79A8), Color(0xFFFFABE7)]),
      },
      {
        "title": "Sports Gear",
        "emoji": "⚽",
        "desc": "Rackets, jerseys, gym equipment",
        "gradient": const LinearGradient(colors: [Color(0xFF00B894), Color(0xFF55EFC4)]),
      },
      {
        "title": "Furniture",
        "emoji": "🛋",
        "desc": "Study chairs, desks, drawers",
        "gradient": const LinearGradient(colors: [Color(0xFFE17055), Color(0xFFFFB894)]),
      },
      {
        "title": "Essentials",
        "emoji": "🎒",
        "desc": "Bags, fans, daily tools",
        "gradient": const LinearGradient(colors: [Color(0xFFF1C40F), Color(0xFFFFEAA7)]),
      },
    ];

    return Container(
      key: _categoriesKey,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          _buildSectionHeader(
            category: "CATEGORIES",
            title: "Explore What Students Sell",
            subtitle: "Categorized beautifully with premium 3D cards. Hover to tilt!",
          ),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categoriesList.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : (constraints.maxWidth > 1000 ? 3 : 2),
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 1.45,
                ),
                itemBuilder: (context, index) {
                  final cat = categoriesList[index];
                  return TiltCard(
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: cat['gradient'],
                        borderRadius: AppTheme.radiusXL,
                        boxShadow: AppTheme.glowShadow(color: (cat['gradient'] as LinearGradient).colors[0]),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 3D Glassmorphic Icon Circle
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                            ),
                            child: Text(
                              cat['emoji'],
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            cat['title'],
                            style: GoogleFonts.lexend(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat['desc'],
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SUSTAINABILITY IMPACT SECTION
  // ============================================================================
  Widget _buildImpactSection(bool isMobile) {
    return Container(
      key: _impactKey,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Column(
        children: [
          _buildSectionHeader(
            category: "OUR FOOTPRINT",
            title: "Campus Sustainability Impact",
            subtitle: "Together we have made a measurable difference in our UNESA environment",
            lightMode: false,
          ),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              if (isMobile) {
                return Column(
                  children: [
                    _buildStatWidget(
                      icon: Icons.loop_rounded,
                      value: 1248,
                      suffix: "+",
                      label: "Items Reused",
                      color: AppTheme.aquaTurquoise,
                    ),
                    const SizedBox(height: 48),
                    _buildStatWidget(
                      icon: Icons.eco_rounded,
                      value: 2496,
                      suffix: " kg",
                      label: "Carbon Saved",
                      color: AppTheme.ecoTeal,
                    ),
                    const SizedBox(height: 48),
                    _buildStatWidget(
                      icon: Icons.savings_rounded,
                      value: 450,
                      prefix: "Rp ",
                      suffix: "M+",
                      label: "Student Savings",
                      color: AppTheme.sunYellow,
                    ),
                  ],
                );
              } else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildStatWidget(
                        icon: Icons.loop_rounded,
                        value: 1248,
                        suffix: "+",
                        label: "Items Reused",
                        color: AppTheme.aquaTurquoise,
                      ),
                    ),
                    Expanded(
                      child: _buildStatWidget(
                        icon: Icons.eco_rounded,
                        value: 2496,
                        suffix: " kg",
                        label: "Carbon Saved",
                        color: AppTheme.ecoTeal,
                      ),
                    ),
                    Expanded(
                      child: _buildStatWidget(
                        icon: Icons.savings_rounded,
                        value: 45, // 45 Juta
                        prefix: "Rp ",
                        suffix: "M+",
                        label: "Student Savings",
                        color: AppTheme.sunYellow,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatWidget({
    required IconData icon,
    required int value,
    String prefix = "",
    String suffix = "",
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        // Pulsing Icon Ring
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
          ),
          child: Icon(icon, size: 36, color: color),
        ),
        const SizedBox(height: 20),
        // Counting Text
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (prefix.isNotEmpty)
              Text(
                prefix,
                style: GoogleFonts.lexend(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            AnimatedStatCounter(
              targetValue: value,
              textStyle: GoogleFonts.lexend(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Text(
              suffix,
              style: GoogleFonts.lexend(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightBlueGrey,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // TESTIMONIALS SECTION (GLASSMORPHISM CARDS)
  // ============================================================================
  Widget _buildTestimonialsSection(bool isMobile) {
    final List<Map<String, dynamic>> reviews = [
      {
        "name": "Cesya Aulia",
        "faculty": "Fakultas Teknik, UNESA",
        "review": "ReUsea helps me find cheap reference books and calculators. It's incredibly easy to chat and meet seniors on campus Lidah Wetan!",
        "rating": 5,
        "color": AppTheme.aquaTurquoise,
      },
      {
        "name": "Siswanto",
        "faculty": "Fakultas Ilmu Sosial, UNESA",
        "review": "I sold my old electric fan and textbook within 2 days of uploading. Saving carbon feels real when you see it on the impact page!",
        "rating": 5,
        "color": AppTheme.coralPeach,
      },
      {
        "name": "Budi Raharjo",
        "faculty": "Fakultas Bahasa & Seni, UNESA",
        "review": "Awesome UI design! The glassmorphism and maps feature makes dealing preloved sports gear on campus feel like a premium startup experience.",
        "rating": 5,
        "color": AppTheme.sunYellow,
      },
    ];

    return Container(
      key: _testimonialsKey,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          _buildSectionHeader(
            category: "TESTIMONIALS",
            title: "What UNESA Students Say",
            subtitle: "Real stories from fellow campus peers using ReUsea to buy and sell",
          ),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              if (isMobile) {
                return Column(
                  children: reviews.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _buildTestimonialCard(r),
                  )).toList(),
                );
              } else {
                return Row(
                  children: reviews.map((r) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _buildTestimonialCard(r),
                    ),
                  )).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard(Map<String, dynamic> r) {
    return HoverCard(
      child: GlassContainer(
        radius: 28,
        blur: 20,
        opacity: 0.65,
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1), width: 1.5),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating Stars
            Row(
              children: List.generate(
                r['rating'],
                (index) => const Icon(Icons.star_rounded, color: AppTheme.sunYellow, size: 22),
              ),
            ),
            const SizedBox(height: 24),
            // Review Text
            Text(
              "\"${r['review']}\"",
              style: GoogleFonts.lexend(
                fontSize: 15,
                color: AppTheme.darkNavy,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 28),
            // Divider
            Divider(color: AppTheme.lightBlueGrey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            // Author info
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: (r['color'] as Color).withValues(alpha: 0.25),
                  child: Text(
                    r['name'][0],
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: r['color'] as Color,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['name'],
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        r['faculty'],
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: AppTheme.secondaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // FOOTER SECTION
  // ============================================================================
  Widget _buildFooterSection(bool isMobile) {
    return Container(
      color: AppTheme.darkNavy,
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFooterBrand(),
                    const SizedBox(height: 40),
                    _buildFooterLinks(),
                    const SizedBox(height: 40),
                    _buildFooterSocials(),
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(flex: 2, child: _buildFooterBrand()),
                    Expanded(child: _buildFooterLinks()),
                    Expanded(child: _buildFooterSocials()),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 60),
          Divider(color: Colors.white10),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2026 ReUsea Inc. All rights reserved.',
                style: GoogleFonts.lexend(fontSize: 12, color: Colors.white38),
              ),
              Text(
                'Built with 💙 for UNESA Campus Community',
                style: GoogleFonts.lexend(fontSize: 12, color: Colors.white38),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomPaint(
              size: const Size(40, 40),
              painter: ReUseaLogoPainter(showBackground: true),
            ),
            const SizedBox(width: 14),
            Text(
              'ReUsea',
              style: GoogleFonts.lexend(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Universitas Negeri Surabaya Sustainability Initiative.\nEmpowering students to build circular eco-friendly communities.',
          style: GoogleFonts.lexend(fontSize: 13, color: Colors.white60, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildFooterLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Links',
          style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        _buildFooterLink('How It Works', () => _scrollToSection(_howItWorksKey)),
        _buildFooterLink('Benefits', () => _scrollToSection(_benefitsKey)),
        _buildFooterLink('Categories', () => _scrollToSection(_categoriesKey)),
        _buildFooterLink('Sustainability Impact', () => _scrollToSection(_impactKey)),
      ],
    );
  }

  Widget _buildFooterLink(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: GoogleFonts.lexend(fontSize: 14, color: Colors.white60),
        ),
      ),
    );
  }

  Widget _buildFooterSocials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'University Branding',
          style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.school_outlined, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              'UNESA Ketintang / Lidah Wetan',
              style: GoogleFonts.lexend(fontSize: 14, color: Colors.white60),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildSocialIcon(Icons.public_rounded),
            _buildSocialIcon(Icons.camera_alt_outlined),
            _buildSocialIcon(Icons.alternate_email_rounded),
          ],
        )
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white70, size: 18),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================
  Widget _buildSectionHeader({
    required String category,
    required String title,
    required String subtitle,
    bool lightMode = true,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: (lightMode ? AppTheme.primaryBlue : AppTheme.aquaTurquoise).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            category,
            style: GoogleFonts.lexend(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: lightMode ? AppTheme.primaryBlue : AppTheme.aquaTurquoise,
              letterSpacing: 2.0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: lightMode ? AppTheme.darkNavy : Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            fontSize: 16,
            color: lightMode ? AppTheme.secondaryBlue : AppTheme.lightBlueGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildWaveTransition(Color topColor, Color bottomColor, {bool inverted = false}) {
    return Container(
      color: topColor,
      child: CustomPaint(
        size: const Size(double.infinity, 80),
        painter: WaveDividerPainter(
          topColor: topColor,
          bottomColor: bottomColor,
          inverted: inverted,
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET: HERO LOGO RIPPLE ANIMATION
// ============================================================================
class HeroLogoWidget extends StatefulWidget {
  const HeroLogoWidget({super.key});

  @override
  State<HeroLogoWidget> createState() => _HeroLogoWidgetState();
}

class _HeroLogoWidgetState extends State<HeroLogoWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulsing ring 2
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            double waveValue = (_pulseController.value + 0.5) % 1.0;
            return Container(
              width: 140 + (waveValue * 80),
              height: 140 + (waveValue * 80),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08 * (1.0 - waveValue)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15 * (1.0 - waveValue)),
                  width: 2,
                ),
              ),
            );
          },
        ),
        // Outer pulsing ring 1
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 140 + (_pulseController.value * 60),
              height: 140 + (_pulseController.value * 60),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1 * (1.0 - _pulseController.value)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2 * (1.0 - _pulseController.value)),
                  width: 2,
                ),
              ),
            );
          },
        ),
        // Main Logo Container
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(32),
            boxShadow: AppTheme.glowShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.5)),
          ),
          child: CustomPaint(
            size: const Size(120, 120),
            painter: ReUseaLogoPainter(showBackground: true),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// WIDGET: FLOATING HERO ILLUSTRATION (3D ELEMENTS ON WAVES)
// ============================================================================
class FloatingHeroIllustration extends StatelessWidget {
  final bool isMobile;
  const FloatingHeroIllustration({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final double illustrationWidth = isMobile ? 320 : 750;
    final double illustrationHeight = isMobile ? 360 : 380;

    return Container(
      width: illustrationWidth,
      height: illustrationHeight,
      margin: const EdgeInsets.only(top: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Vector Waves Painter
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 180,
              child: CustomPaint(
                painter: OceanWavesGraphicPainter(),
              ),
            ),
          ),

          // 5 Floating 3D-styled cards (Wrapped correctly in Positioned to avoid layout assertions)
          // 1. Books (📚)
          Positioned(
            left: isMobile ? 20 : 80,
            top: isMobile ? 120 : 50,
            child: Floating3DCard(
              label: "Books",
              emoji: "📚",
              tag: "Lidah Wetan",
              color: AppTheme.coralPeach,
              waveShift: 0.0,
            ),
          ),
          // 2. Laptop (💻)
          Positioned(
            left: isMobile ? 180 : 210,
            top: isMobile ? 60 : 20,
            child: Floating3DCard(
              label: "Electronics",
              emoji: "💻",
              tag: "Ketintang",
              color: AppTheme.aquaTurquoise,
              waveShift: 1.2,
            ),
          ),
          // 3. Fashion (👕)
          Positioned(
            left: isMobile ? 100 : 360,
            top: isMobile ? 220 : 90,
            child: Floating3DCard(
              label: "Fashion",
              emoji: "👟",
              tag: "-60%",
              color: AppTheme.sunsetOrange,
              waveShift: 2.4,
            ),
          ),
          // 4. Sports (⚽)
          Positioned(
            left: isMobile ? 30 : 500,
            top: isMobile ? 40 : 40,
            child: Floating3DCard(
              label: "Sports Gear",
              emoji: "⚽",
              tag: "Preloved",
              color: AppTheme.ecoTeal,
              waveShift: 3.6,
            ),
          ),
          // 5. Furniture (🛋)
          Positioned(
            left: isMobile ? 210 : 620,
            top: isMobile ? 180 : 80,
            child: Floating3DCard(
              label: "Furniture",
              emoji: "🪑",
              tag: "UNESA",
              color: AppTheme.sunYellow,
              waveShift: 4.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET: INDIVIDUAL 3D FLOATING CARD WITH SHADOW AND SIN-WAVE MOVEMENT
// ============================================================================
class Floating3DCard extends StatefulWidget {
  final String label;
  final String emoji;
  final String tag;
  final Color color;
  final double waveShift;

  const Floating3DCard({
    super.key,
    required this.label,
    required this.emoji,
    required this.tag,
    required this.color,
    required this.waveShift,
  });

  @override
  State<Floating3DCard> createState() => _Floating3DCardState();
}

class _Floating3DCardState extends State<Floating3DCard> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        // Calculate smooth wave offset using cosine
        double floatOffset = math.sin((_floatController.value * 2 * math.pi) + widget.waveShift) * 12.0;

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: TiltCard(
            child: Container(
              width: 120,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Floating Tag Badge
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.tag,
                        style: GoogleFonts.lexend(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: widget.color,
                        ),
                      ),
                    ),
                  ),
                  // Huge Emoji
                  Text(widget.emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  // Label
                  Text(
                    widget.label,
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkNavy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// WIDGET: MICRO-INTERACTION TILT CARD (REACTS TO CURSOR)
// ============================================================================
class TiltCard extends StatefulWidget {
  final Widget child;
  const TiltCard({super.key, required this.child});

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  double xRotation = 0.0;
  double yRotation = 0.0;
  double scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        // Calculate coordinates relative to the center of the widget
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final size = renderBox.size;
          final localPos = renderBox.globalToLocal(event.position);
          
          // Normalized coordinates: -1.0 to 1.0
          final dx = (localPos.dx - (size.width / 2)) / (size.width / 2);
          final dy = (localPos.dy - (size.height / 2)) / (size.height / 2);

          setState(() {
            // Cap the rotation at maximum 12 degrees (0.2 radians)
            xRotation = -dy * 0.15;
            yRotation = dx * 0.15;
            scale = 1.05;
          });
        }
      },
      onExit: (event) {
        setState(() {
          xRotation = 0.0;
          yRotation = 0.0;
          scale = 1.0;
        });
      },
      child: TweenAnimationBuilder<Matrix4>(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        tween: Matrix4Tween(
          begin: Matrix4.identity(),
          end: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateX(xRotation)
            ..rotateY(yRotation)
            ..scaleByDouble(scale, scale, 1.0, 1.0),
        ),
        builder: (context, matrix, child) {
          return Transform(
            alignment: FractionalOffset.center,
            transform: matrix,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

// ============================================================================
// WIDGET: MICRO-INTERACTION HOVER CARD (SIMPLE SCALE)
// ============================================================================
class HoverCard extends StatefulWidget {
  final Widget child;
  const HoverCard({super.key, required this.child});

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedScale(
        scale: isHovered ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

// ============================================================================
// WIDGET: ANIMATED STATS COUNTER
// ============================================================================
class AnimatedStatCounter extends StatefulWidget {
  final int targetValue;
  final TextStyle textStyle;

  const AnimatedStatCounter({
    super.key,
    required this.targetValue,
    required this.textStyle,
  });

  @override
  State<AnimatedStatCounter> createState() => _AnimatedStatCounterState();
}

class _AnimatedStatCounterState extends State<AnimatedStatCounter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _animation = IntTween(begin: 0, end: widget.targetValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Automatically trigger calculation when built (or visible in views)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          _animation.value.toString(),
          style: widget.textStyle,
        );
      },
    );
  }
}

// ============================================================================
// CUSTOM PAINTER: REUSEA LOGO
// Paints a custom vector R with wave caps below it
// ============================================================================
class ReUseaLogoPainter extends CustomPainter {
  final bool showBackground;
  ReUseaLogoPainter({this.showBackground = true});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    canvas.save();
    canvas.scale(w / 100, h / 100);

    if (showBackground) {
      final Paint bgPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF1A2295), Color(0xFF263759)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(0, 0, 100, 100));

      final RRect rrect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 100, 100),
        const Radius.circular(28),
      );
      canvas.drawRRect(rrect, bgPaint);

      // Draw border
      final Paint borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(rrect, borderPaint);
    }

    // Paint stylized 'R' in White
    final Paint rPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Stem (Vertical bar)
    final Path rPath = Path();
    rPath.moveTo(22, 18);
    rPath.lineTo(34, 18);
    rPath.lineTo(34, 82);
    rPath.lineTo(22, 82);
    rPath.close();
    canvas.drawPath(rPath, rPaint);

    // Loop
    final Path loopOuter = Path();
    loopOuter.moveTo(34, 18);
    loopOuter.cubicTo(66, 18, 76, 22, 76, 36);
    loopOuter.cubicTo(76, 50, 66, 54, 34, 54);
    loopOuter.close();

    final Path loopInner = Path();
    loopInner.moveTo(34, 28);
    loopInner.cubicTo(56, 28, 64, 30, 64, 36);
    loopInner.cubicTo(64, 42, 56, 44, 34, 44);
    loopInner.close();

    // R Loop: Outer minus Inner
    final Path loopCombined = Path.combine(PathOperation.difference, loopOuter, loopInner);
    canvas.drawPath(loopCombined, rPaint);

    // Leg (Wave-like sweeping tail)
    final Path legPath = Path();
    legPath.moveTo(34, 50);
    legPath.cubicTo(46, 50, 68, 70, 78, 80);
    legPath.lineTo(62, 82);
    legPath.cubicTo(52, 72, 42, 62, 34, 60);
    legPath.close();
    canvas.drawPath(legPath, rPaint);

    // Bottom Waves (overlapping the R)
    // Wave 1: Darker teal/blue wave
    final Paint wave1Paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2E86DE), Color(0xFF00D2D3)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(const Rect.fromLTWH(0, 50, 100, 50));

    final Path wave1Path = Path();
    wave1Path.moveTo(0, 78);
    wave1Path.cubicTo(25, 68, 45, 92, 75, 78);
    wave1Path.cubicTo(85, 73, 95, 75, 100, 78);
    wave1Path.lineTo(100, 100);
    wave1Path.lineTo(0, 100);
    wave1Path.close();

    // Clip to rounded rect if showBackground is true
    if (showBackground) {
      canvas.save();
      final Path clipPath = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 100, 100),
          const Radius.circular(28),
        ));
      canvas.clipPath(clipPath);
      canvas.drawPath(wave1Path, wave1Paint);
      canvas.restore();
    } else {
      canvas.drawPath(wave1Path, wave1Paint);
    }

    // Wave 2: White cap wave
    final Paint wave2Paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9);

    final Path wave2Path = Path();
    wave2Path.moveTo(0, 84);
    wave2Path.cubicTo(30, 74, 50, 94, 80, 82);
    wave2Path.cubicTo(90, 78, 95, 80, 100, 82);
    wave2Path.lineTo(100, 100);
    wave2Path.lineTo(0, 100);
    wave2Path.close();

    if (showBackground) {
      canvas.save();
      final Path clipPath = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 100, 100),
          const Radius.circular(28),
        ));
      canvas.clipPath(clipPath);
      canvas.drawPath(wave2Path, wave2Paint);
      canvas.restore();
    } else {
      canvas.drawPath(wave2Path, wave2Paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// CUSTOM PAINTER: WAVE TRANSITION DIVIDER
// Renders beautiful organic wave shapes between sections
// ============================================================================
class WaveDividerPainter extends CustomPainter {
  final Color topColor;
  final Color bottomColor;
  final bool inverted;

  WaveDividerPainter({
    required this.topColor,
    required this.bottomColor,
    this.inverted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Fill background with bottomColor
    final Paint bgPaint = Paint()..color = bottomColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final Paint wavePaint = Paint()
      ..color = topColor
      ..style = PaintingStyle.fill;

    final Path path = Path();
    if (!inverted) {
      path.moveTo(0, 0);
      path.quadraticBezierTo(w * 0.25, h * 0.7, w * 0.5, h * 0.45);
      path.quadraticBezierTo(w * 0.75, h * 0.2, w, h * 0.75);
      path.lineTo(w, 0);
      path.lineTo(0, 0);
    } else {
      path.moveTo(0, h);
      path.quadraticBezierTo(w * 0.25, h * 0.3, w * 0.5, h * 0.55);
      path.quadraticBezierTo(w * 0.75, h * 0.8, w, h * 0.25);
      path.lineTo(w, h);
      path.lineTo(0, h);
    }
    path.close();

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// CUSTOM PAINTER: OCEAN WAVES GRAPHIC IN HERO ILLUSTRATION
// Renders overlapping wave lines below floating cards
// ============================================================================
class OceanWavesGraphicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Wave 1 (Deep Blue Accent)
    final Paint paint1 = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.25)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final Path path1 = Path();
    path1.moveTo(0, h * 0.6);
    path1.cubicTo(w * 0.25, h * 0.4, w * 0.5, h * 0.85, w * 0.75, h * 0.5);
    path1.cubicTo(w * 0.88, h * 0.35, w * 0.95, h * 0.4, w, h * 0.45);
    path1.lineTo(w, h);
    path1.lineTo(0, h);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Wave 2 (Lighter Turquoise Accent)
    final Paint paint2 = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.35)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final Path path2 = Path();
    path2.moveTo(0, h * 0.75);
    path2.cubicTo(w * 0.3, h * 0.55, w * 0.55, h * 0.95, w * 0.8, h * 0.65);
    path2.cubicTo(w * 0.9, h * 0.55, w * 0.96, h * 0.6, w, h * 0.62);
    path2.lineTo(w, h);
    path2.lineTo(0, h);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

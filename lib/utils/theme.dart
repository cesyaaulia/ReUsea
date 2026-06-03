import 'dart:ui';
import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors (Ocean theme)
  static const Color primaryBlue = Color(0xFF1A2295);
  static const Color secondaryBlue = Color(0xFF566E8B);
  static const Color lightBlueGrey = Color(0xFFA8B4C0);
  static const Color darkNavy = Color(0xFF263759);
  static const Color bgLight = Color(0xFFF2F4F7);
  
  // Gen-Z Playful Accent Colors (Disney Luca & Space Explorer vibes)
  static const Color coralPeach = Color(0xFFFF7E67);
  static const Color sunsetOrange = Color(0xFFFF9F43);
  static const Color aquaTurquoise = Color(0xFF00D2D3);
  static const Color ecoTeal = Color(0xFF10AC84);
  static const Color sunYellow = Color(0xFFFECA57);

  // Soft Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, darkNavy],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient oceanWaveGradient = LinearGradient(
    colors: [Color(0xFF2E86DE), aquaTurquoise],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [sunsetOrange, coralPeach],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient ecoGradient = LinearGradient(
    colors: [ecoTeal, Color(0xFF01A3A4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Colors.white70, Colors.white30],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Soft Premium Shadows
  static List<BoxShadow> softShadow({Color? color}) => [
        BoxShadow(
          color: (color ?? Colors.black).withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> glowShadow({required Color color}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.25),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ];

  // Rounded Corners (24px - 32px)
  static const BorderRadius radiusM = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusL = BorderRadius.all(Radius.circular(24));
  static const BorderRadius radiusXL = BorderRadius.all(Radius.circular(32));
}

/// Glassmorphism Container dengan filter blur
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.5,
    this.radius = 24.0,
    this.padding,
    this.margin,
    this.border,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        boxShadow: AppTheme.softShadow(color: const Color(0xFF1A2295)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: opacity),
                  Colors.white.withValues(alpha: opacity * 0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(radius),
              border: border ??
                  Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Gelembung dekoratif laut yang melayang
class OceanBubble extends StatelessWidget {
  final double size;
  final Color color;
  final double top;
  final double left;

  const OceanBubble({
    super.key,
    required this.size,
    required this.color,
    required this.top,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.35),
              color.withValues(alpha: 0.05),
            ],
            center: const Alignment(-0.3, -0.3),
          ),
        ),
      ),
    );
  }
}

/// Background gradasi laut lembut
class OceanGradientBackground extends StatelessWidget {
  final Widget child;
  
  const OceanGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFE8F1F5),
                Color(0xFFF3F6F9),
                Color(0xFFEAF0F6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // Floating Bubbles
        const OceanBubble(size: 200, color: AppTheme.aquaTurquoise, top: -50, left: -60),
        const OceanBubble(size: 150, color: AppTheme.primaryBlue, top: 200, left: 300),
        const OceanBubble(size: 100, color: AppTheme.coralPeach, top: 500, left: -30),
        const OceanBubble(size: 120, color: AppTheme.sunYellow, top: 700, left: 240),
        child,
      ],
    );
  }
}

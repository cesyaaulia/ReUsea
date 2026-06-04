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
          color: (color ?? Colors.black).withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> glowShadow({required Color color}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.15),
          blurRadius: 8,
          offset: const Offset(0, 3),
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
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity * 1.2),
        borderRadius: BorderRadius.circular(radius),
        border: border ??
            Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
        boxShadow: AppTheme.softShadow(color: const Color(0xFF1A2295)),
      ),
      child: child,
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


import 'package:flutter/material.dart';

// ============================================================================
// REUSEA CUSTOM PAGE TRANSITIONS
// Koleksi animasi transisi halaman yang menarik ala Figma Prototype.
// Setiap transisi dirancang untuk konteks navigasi yang berbeda.
// ============================================================================

/// 1. SLIDE FROM RIGHT — Animasi geser dari kanan dengan kurva elastis.
///    Cocok untuk navigasi maju (push) dari halaman utama ke detail.
class SlideRightRoute extends PageRouteBuilder {
  final Widget page;

  SlideRightRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Animasi slide dari kanan
            var slideAnimation = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            // Animasi fade halus
            var fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
            ));

            // Halaman sebelumnya sedikit bergeser ke kiri dan mengecil
            var secondarySlide = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.25, 0.0),
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOutCubic,
            ));

            return SlideTransition(
              position: secondarySlide,
              child: SlideTransition(
                position: slideAnimation,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: child,
                ),
              ),
            );
          },
        );
}

/// 2. SLIDE UP (MODAL STYLE) — Animasi naik dari bawah layar.
///    Cocok untuk form, sell item, edit profile, dan halaman modal-style.
class SlideUpRoute extends PageRouteBuilder {
  final Widget page;

  SlideUpRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var slideAnimation = Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
            ));

            var fadeAnimation = Tween<double>(
              begin: 0.3,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
            ));

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}

/// 3. FADE + SCALE — Animasi zoom in halus dengan fade.
///    Cocok untuk navigasi ke halaman notifikasi dan settings.
class FadeScaleRoute extends PageRouteBuilder {
  final Widget page;

  FadeScaleRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var scaleAnimation = Tween<double>(
              begin: 0.85,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ));

            var fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
            ));

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            );
          },
        );
}

/// 4. SLIDE + FADE FROM RIGHT (SMOOTH) — Versi lebih halus dari SlideRight.
///    Cocok untuk navigasi ke order detail, sale detail dari list.
class SlideFadeRightRoute extends PageRouteBuilder {
  final Widget page;

  SlideFadeRightRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var slideAnimation = Tween<Offset>(
              begin: const Offset(0.3, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            var fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ));

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}

/// 5. HERO FADE — Animasi fade dengan sedikit scale, mirip Hero transition.
///    Cocok untuk navigasi dari product card ke detail page.
class HeroFadeRoute extends PageRouteBuilder {
  final Widget page;

  HeroFadeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 550),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Scale dari sedikit lebih kecil ke ukuran penuh
            var scaleAnimation = Tween<double>(
              begin: 0.92,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            // Fade in yang halus
            var fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
            ));

            // Halaman sebelumnya fade out sedikit
            var secondaryFade = Tween<double>(
              begin: 1.0,
              end: 0.7,
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOut,
            ));

            return FadeTransition(
              opacity: secondaryFade,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: child,
                ),
              ),
            );
          },
        );
}

/// 6. ELEGANT FADE — Animasi crossfade yang sangat halus.
///    Cocok untuk pushReplacement (login -> main, auth flow).
class ElegantFadeRoute extends PageRouteBuilder {
  final Widget page;

  ElegantFadeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ));

            var scaleAnimation = Tween<double>(
              begin: 1.05,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            // Halaman lama sedikit zoom out dan fade
            var secondaryFade = Tween<double>(
              begin: 1.0,
              end: 0.0,
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInOut,
            ));

            var secondaryScale = Tween<double>(
              begin: 1.0,
              end: 0.95,
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInOut,
            ));

            return FadeTransition(
              opacity: secondaryFade,
              child: ScaleTransition(
                scale: secondaryScale,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: ScaleTransition(
                    scale: scaleAnimation,
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
}

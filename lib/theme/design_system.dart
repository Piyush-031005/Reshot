import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The Universal ReShot Design System (Vision 2.0 - Spider-Verse Edition)
/// 
/// Rule: "Same Theme Everywhere = NO"
/// But they all share the ReShot DNA: Thick borders, funky gradients, 
/// comic typography, bold shadows, and glitch accents.
class ReShotDesignSystem {
  
  // ─── Core Identity (The DNA) ──────────────────────────────────────────
  
  // Global Structural Colors
  static const Color creamBg = Color(0xFFFFF8F0);
  static const Color darkBg = Color(0xFF0D0F12);
  static const Color inkBlack = Color(0xFF121212);
  static const Color cardWhite = Color(0xFFF8F5F2); // Off-white for stickers/cards
  static const Color darkSurface = Color(0xFF15181F); // tactical HUD background Neons
  
  // Brand Neons
  static const Color neonLime = Color(0xFFB8FF00);
  static const Color hotPink = Color(0xFFFF3E6C);
  static const Color cyberCyan = Color(0xFF00E5FF);
  static const Color sunOrange = Color(0xFFFF7A2F);

  // Brutalist Borders & Shadows
  static const double borderWidth = 4.0;
  static const Offset shadowOffset = Offset(8, 8);
  
  static Border get brutalistBorder => Border.all(color: inkBlack, width: borderWidth);
  
  static List<BoxShadow> get brutalistShadow => [
    const BoxShadow(color: inkBlack, offset: shadowOffset, blurRadius: 0),
  ];

  static List<BoxShadow> get brutalistShadowPink => [
    const BoxShadow(color: hotPink, offset: shadowOffset, blurRadius: 0),
  ];

  static List<BoxShadow> get brutalistShadowCyan => [
    const BoxShadow(color: cyberCyan, offset: shadowOffset, blurRadius: 0),
  ];

  // ─── Typography System ────────────────────────────────────────────────
  
  static TextTheme get textTheme {
    return TextTheme(
      // Display: Boogaloo (Comic/Graffiti vibe)
      displayLarge: GoogleFonts.boogaloo(fontSize: 48, color: inkBlack, height: 1.1),
      displayMedium: GoogleFonts.boogaloo(fontSize: 36, color: inkBlack, height: 1.1),
      displaySmall: GoogleFonts.boogaloo(fontSize: 28, color: inkBlack, height: 1.1),
      
      // Titles: Boogaloo or Bungee
      titleLarge: GoogleFonts.boogaloo(fontSize: 24, color: inkBlack, letterSpacing: 0.5),
      titleMedium: GoogleFonts.boogaloo(fontSize: 20, color: inkBlack, letterSpacing: 0.5),
      titleSmall: GoogleFonts.boogaloo(fontSize: 16, color: inkBlack, letterSpacing: 0.5),
      
      // Body: Nunito (Friendly, readable, geometric)
      bodyLarge: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: inkBlack),
      bodyMedium: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF333333)),
      bodySmall: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF666666)),
      
      // Labels: Techy/Mono feel for data (Press Start 2P or bold Nunito)
      labelLarge: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
    );
  }

  // ─── Chapters (Multiverse Moods) ──────────────────────────────────────
  
  /// Chapter 1: Dashboard (Street Pop / Graffiti)
  /// Hypebeast, magazine layouts, posters, huge typography.
  static BoxDecoration get streetPopCard {
    return BoxDecoration(
      color: cardWhite,
      borderRadius: BorderRadius.circular(16),
      border: brutalistBorder,
      boxShadow: brutalistShadow,
    );
  }

  static BoxDecoration streetPopColoredCard(Color color) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      border: brutalistBorder,
      boxShadow: brutalistShadow,
    );
  }

  /// Chapter 2: Camera (Cyber Tactical HUD)
  /// Minimal, Dark, Focused, Anime targeting system.
  static BoxDecoration get cyberTacticalOverlay {
    return BoxDecoration(
      color: darkBg.withOpacity(0.85),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: cyberCyan, width: 2),
      boxShadow: [
        BoxShadow(color: cyberCyan.withOpacity(0.5), blurRadius: 10, spreadRadius: 2),
      ],
    );
  }
  
  /// Chapter 3: Map (Treasure Hunt)
  /// Hand-drawn paths, vintage paper, floating rewards.
  static BoxDecoration get treasureMapCard {
    return BoxDecoration(
      color: creamBg, // Paper feel
      borderRadius: BorderRadius.circular(24), // Softer corners
      border: Border.all(color: const Color(0xFF8B5A2B), width: 3), // Brown ink
      boxShadow: const [
        BoxShadow(color: Color(0xFF8B5A2B), offset: Offset(6, 6), blurRadius: 0),
      ],
    );
  }

  /// Chapter 4: Profile (Explorer Passport)
  /// Stamps, polaroids, travel journal.
  static BoxDecoration get passportStamp {
    return BoxDecoration(
      color: Colors.transparent,
      border: Border.all(color: hotPink, width: 4),
      borderRadius: BorderRadius.circular(100),
    ); // Usually applied with a slight rotation transform
  }
}

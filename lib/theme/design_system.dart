import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The Universal ReShot Design System (Vision 2.0 - Spider-Verse Edition)
/// 
/// Rule: "Same Theme Everywhere = NO"
/// But they all share the ReShot DNA: Thick borders, funky gradients, 
/// comic typography, bold shadows, and glitch accents.
class ReShotDesignSystem {
  
  // ─── Core Identity (Editorial Brutalism) ─────────────────────────
  
  // Global Structural Colors
  static const Color creamBg = Color(0xFFF4F0EA); // Newspaper off-white
  static const Color darkBg = Color(0xFF0F0F0F);
  static const Color inkBlack = Color(0xFF111111);
  static const Color cardWhite = Color(0xFFFAFAFA); 
  static const Color darkSurface = Color(0xFF1A1A1A); 
  
  // Editorial Accent Colors (From Inspiration)
  static const Color editorialRed = Color(0xFFD63220); // The Graphic Design Bible Red
  static const Color editorialBlue = Color(0xFF0D25B9); // The COLOR blue
  static const Color editorialYellow = Color(0xFFE2D016); // Brand Gap Yellow
  
  // Legacy mappings for backward compatibility
  static const Color neonLime = editorialYellow;
  static const Color hotPink = editorialRed;
  static const Color cyberCyan = editorialBlue;
  static const Color sunOrange = Color(0xFFFF5500);

  // Brutalist Borders & Shadows
  static const double borderWidth = 3.0;
  static const Offset shadowOffset = Offset(6, 6);
  
  static Border get brutalistBorder => Border.all(color: inkBlack, width: borderWidth);
  
  static List<BoxShadow> get brutalistShadow => [
    const BoxShadow(color: inkBlack, offset: shadowOffset, blurRadius: 0),
  ];

  static List<BoxShadow> get brutalistShadowPink => [
    const BoxShadow(color: editorialRed, offset: shadowOffset, blurRadius: 0),
  ];

  static List<BoxShadow> get brutalistShadowCyan => [
    const BoxShadow(color: editorialBlue, offset: shadowOffset, blurRadius: 0),
  ];

  // ─── Typography System ────────────────────────────────────────────────
  
  static TextTheme get textTheme {
    return TextTheme(
      // Display: Anton (Massive, condensed, brutalist)
      displayLarge: GoogleFonts.anton(fontSize: 56, color: inkBlack, height: 1.0, letterSpacing: 1),
      displayMedium: GoogleFonts.anton(fontSize: 42, color: inkBlack, height: 1.0, letterSpacing: 1),
      displaySmall: GoogleFonts.anton(fontSize: 32, color: inkBlack, height: 1.1, letterSpacing: 0.5),
      
      // Titles: Oswald (Structured, editorial)
      titleLarge: GoogleFonts.oswald(fontSize: 26, color: inkBlack, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      titleMedium: GoogleFonts.oswald(fontSize: 20, color: inkBlack, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      titleSmall: GoogleFonts.oswald(fontSize: 16, color: inkBlack, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      
      // Body: Inter (Clean, readable, Swiss design style)
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: inkBlack),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF333333)),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: const Color(0xFF555555)),
      
      // Labels: Caveat (Shooting Star vibe, handwritten accent)
      labelLarge: GoogleFonts.caveat(fontSize: 24, fontWeight: FontWeight.w700, color: inkBlack),
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

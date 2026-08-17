import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ReShot Street Cartoon Pop Theme
/// Bold, fun, social-media-ready. White cards, chunky borders, offset shadows.
class CyberTheme {
  // ─── Core Palette (Editorial Brutalism) ───────────────────────────────────────────────────────────
  static const Color cream = Color(0xFFF4F0EA);          // newspaper off-white bg
  static const Color cardWhite = Color(0xFFFAFAFA);      // card backgrounds
  static const Color inkBlack = Color(0xFF111111);       // text + outlines
  static const Color outlineBlack = Color(0xFF111111);   // thick border color

  static const Color limeGreen = Color(0xFFE2D016);      // Brand Gap Yellow (repurposed lime)
  static const Color hotPink = Color(0xFFD63220);        // Graphic Design Bible Red (repurposed pink)
  static const Color electricBlue = Color(0xFF0D25B9);   // COLOR Blue (repurposed cyan)
  static const Color sunOrange = Color(0xFFFF5500);      // vivid orange
  static const Color goldenYellow = Color(0xFFFFD700);   // golden badge yellow
  static const Color mintGreen = Color(0xFF00E5A0);      // mint teal (success)

  // ─── Dark Surface (camera overlay screens only) ──────────────────────────
  static const Color darkBg = Color(0xFF0D0F12);
  static const Color darkSurface = Color(0xFF15181F);
  static const Color darkCard = Color(0xFF1E2230);

  // ─── Legacy aliases (keep backward compat for camera screen) ────────────
  static const Color cyberBlack = darkBg;
  static const Color cyberDark = darkSurface;
  static const Color cyberGray = Color(0xFF2B2F3A);

  // ─── ThemeData ──────────────────────────────────────────────────────────────
  static ThemeData get themeData {
    return ThemeData(
      scaffoldBackgroundColor: cream,
      primaryColor: limeGreen,
      colorScheme: ColorScheme.light(
        primary: limeGreen,
        secondary: hotPink,
        surface: cardWhite,
        onPrimary: inkBlack,
        onSecondary: cardWhite,
        onSurface: inkBlack,
        error: hotPink,
      ),
      textTheme: TextTheme(
        // Big editorial headings — Anton
        displayLarge: GoogleFonts.anton(
          fontSize: 56,
          color: inkBlack,
          letterSpacing: 1,
        ),
        displayMedium: GoogleFonts.anton(
          fontSize: 42,
          color: inkBlack,
          letterSpacing: 1,
        ),
        titleLarge: GoogleFonts.oswald(
          fontSize: 26,
          color: inkBlack,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.oswald(
          fontSize: 20,
          color: inkBlack,
          fontWeight: FontWeight.w600,
        ),
        // Body — Inter: clean, editorial
        bodyLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: inkBlack,
        ),
        bodyMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: const Color(0xFF333333),
        ),
        bodySmall: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          fontSize: 12,
          color: const Color(0xFF555555),
        ),
        // Labels — Caveat (Shooting Star vibe)
        labelLarge: GoogleFonts.caveat(
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: inkBlack,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cream,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        titleTextStyle: GoogleFonts.anton(
          fontSize: 28,
          color: inkBlack,
          letterSpacing: 2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: limeGreen,
          foregroundColor: inkBlack,
          textStyle: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: outlineBlack, width: 3),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: outlineBlack, width: 2.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: limeGreen, width: 3),
        ),
        hintStyle: GoogleFonts.inter(color: const Color(0xFFAAAAAA), fontWeight: FontWeight.w500),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardWhite,
        selectedColor: limeGreen,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: outlineBlack, width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }

  // ─── Cartoon Card Decoration ─────────────────────────────────────────────
  /// Standard white card with fat black border + offset drop shadow
  static BoxDecoration get cartoonCard {
    return BoxDecoration(
      color: cardWhite,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: outlineBlack, width: 4), // Thicker border
      boxShadow: const [
        BoxShadow(
          color: outlineBlack,
          offset: Offset(8, 8), // More extreme 2D offset
          blurRadius: 0,
        ),
      ],
    );
  }

  /// Active / selected card — lime green border
  static BoxDecoration get activeCartoonCard {
    return BoxDecoration(
      color: cardWhite,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: limeGreen, width: 4),
      boxShadow: const [
        BoxShadow(
          color: outlineBlack,
          offset: Offset(8, 8),
          blurRadius: 0,
        ),
      ],
    );
  }

  /// Hot pink accent card (banner / highlighted)
  static BoxDecoration get pinkCartoonCard {
    return BoxDecoration(
      color: hotPink,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: outlineBlack, width: 4),
      boxShadow: const [
        BoxShadow(
          color: outlineBlack,
          offset: Offset(8, 8),
          blurRadius: 0,
        ),
      ],
    );
  }

  /// Lime green accent card
  static BoxDecoration get limeCartoonCard {
    return BoxDecoration(
      color: limeGreen,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: outlineBlack, width: 4),
      boxShadow: const [
        BoxShadow(
          color: outlineBlack,
          offset: Offset(8, 8),
          blurRadius: 0,
        ),
      ],
    );
  }

  /// Electric blue accent card
  static BoxDecoration get blueCartoonCard {
    return BoxDecoration(
      color: electricBlue,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: outlineBlack, width: 4),
      boxShadow: const [
        BoxShadow(
          color: outlineBlack,
          offset: Offset(8, 8),
          blurRadius: 0,
        ),
      ],
    );
  }

  // ─── Legacy aliases (backward compat for camera overlay widgets) ─────────
  static BoxDecoration get cartoonDecoration => BoxDecoration(
    color: darkSurface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.black, width: 4),
    boxShadow: const [
      BoxShadow(color: Colors.black, offset: Offset(6, 6), blurRadius: 0),
    ],
  );

  static BoxDecoration get activeCardDecoration => BoxDecoration(
    color: darkSurface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: limeGreen, width: 4),
    boxShadow: const [
      BoxShadow(color: Colors.black, offset: Offset(6, 6), blurRadius: 0),
    ],
  );

  // ─── Cartoon Button Style ────────────────────────────────────────────────
  static ButtonStyle cartoonButton({Color bg = limeGreen, Color fg = inkBlack}) {
    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      textStyle: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: outlineBlack, width: 4),
      ),
      elevation: 0,
      minimumSize: const Size(double.infinity, 60),
      shadowColor: Colors.transparent,
    );
  }

  // ─── Gem Type Color Map ──────────────────────────────────────────────────
  static Color gemTypeColor(String tag) {
    const map = {
      'Waterfall': Color(0xFF00BFFF),
      'Viewpoint': Color(0xFF7C4DFF),
      'Temple': Color(0xFFFF7A2F),
      'Cafe': Color(0xFFFFD700),
      'Sunrise Spot': Color(0xFFFF3E6C),
      'Hidden Gem': Color(0xFFB8FF00),
      'Beach': Color(0xFF00E5A0),
      'Forest': Color(0xFF4CAF50),
    };
    return map[tag] ?? const Color(0xFFB8FF00);
  }

  /// Emoji per gem tag
  static String gemTypeEmoji(String tag) {
    const map = {
      'Waterfall': '🌊',
      'Viewpoint': '🏔️',
      'Temple': '🛕',
      'Cafe': '☕',
      'Sunrise Spot': '🌅',
      'Hidden Gem': '💎',
      'Beach': '🏖️',
      'Forest': '🌲',
    };
    return map[tag] ?? '📍';
  }
}

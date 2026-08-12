import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ReShot Street Cartoon Pop Theme
/// Bold, fun, social-media-ready. White cards, chunky borders, offset shadows.
class CyberTheme {
  // ─── Core Palette ───────────────────────────────────────────────────────────
  static const Color cream = Color(0xFFFFF8F0);          // warm off-white bg
  static const Color cardWhite = Color(0xFFFFFFFF);      // card backgrounds
  static const Color inkBlack = Color(0xFF1A1A1A);       // text + outlines
  static const Color outlineBlack = Color(0xFF0D0D0D);   // thick border color

  static const Color limeGreen = Color(0xFFB8FF00);      // electric lime (primary)
  static const Color hotPink = Color(0xFFFF3E6C);        // hot coral pink (secondary)
  static const Color electricBlue = Color(0xFF00BFFF);   // electric sky blue (accent)
  static const Color sunOrange = Color(0xFFFF7A2F);      // vivid orange (highlight)
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
        // Big cartoon headings — Fredoka One is perfectly playful + bold
        displayLarge: GoogleFonts.boogaloo(
          fontSize: 36,
          color: inkBlack,
          letterSpacing: 0.5,
        ),
        displayMedium: GoogleFonts.boogaloo(
          fontSize: 28,
          color: inkBlack,
        ),
        titleLarge: GoogleFonts.boogaloo(
          fontSize: 20,
          color: inkBlack,
        ),
        titleMedium: GoogleFonts.boogaloo(
          fontSize: 16,
          color: inkBlack,
        ),
        // Body — Nunito: friendly, rounded, great readability
        bodyLarge: GoogleFonts.nunito(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: inkBlack,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: const Color(0xFF555555),
        ),
        bodySmall: GoogleFonts.nunito(
          fontWeight: FontWeight.w400,
          fontSize: 12,
          color: const Color(0xFF888888),
        ),
        // Labels — slightly bolder Nunito
        labelLarge: GoogleFonts.nunito(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: inkBlack,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cream,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        titleTextStyle: GoogleFonts.boogaloo(
          fontSize: 22,
          color: inkBlack,
          letterSpacing: 1,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: limeGreen,
          foregroundColor: inkBlack,
          textStyle: GoogleFonts.boogaloo(fontSize: 16, letterSpacing: 1),
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
        hintStyle: GoogleFonts.nunito(color: const Color(0xFFAAAAAA), fontWeight: FontWeight.w500),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardWhite,
        selectedColor: limeGreen,
        labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 12),
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
      border: Border.all(color: outlineBlack, width: 3),
      boxShadow: const [
        BoxShadow(
          color: outlineBlack,
          offset: Offset(5, 5),
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
      border: Border.all(color: limeGreen, width: 3.5),
      boxShadow: const [
        BoxShadow(
          color: outlineBlack,
          offset: Offset(5, 5),
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
      border: Border.all(color: outlineBlack, width: 3),
      boxShadow: const [
        BoxShadow(
          color: outlineBlack,
          offset: Offset(5, 5),
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
      border: Border.all(color: outlineBlack, width: 3),
      boxShadow: const [
        BoxShadow(
          color: outlineBlack,
          offset: Offset(5, 5),
          blurRadius: 0,
        ),
      ],
    );
  }

  // ─── Legacy aliases (backward compat for camera overlay widgets) ─────────
  static BoxDecoration get cartoonDecoration => BoxDecoration(
    color: darkSurface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.black, width: 3),
    boxShadow: const [
      BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
    ],
  );

  static BoxDecoration get activeCardDecoration => BoxDecoration(
    color: darkSurface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: limeGreen, width: 3),
    boxShadow: const [
      BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
    ],
  );

  // ─── Cartoon Button Style ────────────────────────────────────────────────
  static ButtonStyle cartoonButton({Color bg = limeGreen, Color fg = inkBlack}) {
    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      textStyle: GoogleFonts.boogaloo(fontSize: 16, letterSpacing: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: outlineBlack, width: 3),
      ),
      elevation: 0,
      minimumSize: const Size(double.infinity, 56),
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

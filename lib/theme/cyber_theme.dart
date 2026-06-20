import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CyberTheme {
  static const Color limeGreen = Color(0xFFCEFF05);
  static const Color hotPink = Color(0xFFFF2E9B);
  static const Color cyberBlack = Color(0xFF0D0F12);
  static const Color cyberDark = Color(0xFF15181F);
  static const Color cyberGray = Color(0xFF2B2F3A);

  static ThemeData get themeData {
    return ThemeData(
      scaffoldBackgroundColor: cyberBlack,
      primaryColor: limeGreen,
      colorScheme: const ColorScheme.dark(
        primary: limeGreen,
        secondary: hotPink,
        surface: cyberDark,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w900,
          fontSize: 32,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.normal,
          fontSize: 16,
          color: Colors.white70,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.normal,
          fontSize: 14,
          color: Colors.white60,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cyberDark,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  // Cartoon 3D Border styling decoration
  static BoxDecoration get cartoonDecoration {
    return BoxDecoration(
      color: cyberDark,
      border: Border.all(color: Colors.black, width: 4),
      boxShadow: const [
        BoxShadow(
          color: Colors.black,
          offset: Offset(6, 6),
          blurRadius: 0,
        )
      ],
    );
  }

  static BoxDecoration get activeCardDecoration {
    return BoxDecoration(
      color: cyberDark,
      border: Border.all(color: limeGreen, width: 4),
      boxShadow: const [
        BoxShadow(
          color: Colors.black,
          offset: Offset(6, 6),
          blurRadius: 0,
        )
      ],
    );
  }
}

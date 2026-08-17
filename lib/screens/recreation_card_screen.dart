import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cyber_theme.dart';
import '../theme/design_system.dart';
import '../theme/motion_system.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class RecreationCardScreen extends StatelessWidget {
  final String originalImagePath;
  final String capturedImagePath;
  final double matchScore;
  final String locationName;

  const RecreationCardScreen({
    super.key,
    required this.originalImagePath,
    required this.capturedImagePath,
    required this.matchScore,
    required this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.cream,
      appBar: AppBar(
        backgroundColor: CyberTheme.inkBlack,
        iconTheme: const IconThemeData(color: CyberTheme.cardWhite),
        title: Text(
          'RESHOT COMPLETE',
          style: GoogleFonts.boogaloo(
            color: CyberTheme.sunOrange,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Your viral Recreation Card is ready!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CyberTheme.inkBlack,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // The Shareable Card
              Expanded(
                child: MotionSystem.comicStamp(
                  isVisible: true,
                  child: Container(
                    decoration: BoxDecoration(
                      color: CyberTheme.cardWhite,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: CyberTheme.inkBlack, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: CyberTheme.inkBlack,
                          offset: Offset(8, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Side-by-side images
                        Expanded(
                          child: Row(
                            children: [
                              // Original
                              Expanded(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    border: Border(right: BorderSide(color: CyberTheme.inkBlack, width: 2)),
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      originalImagePath.startsWith('http')
                                          ? Image.network(originalImagePath, fit: BoxFit.cover)
                                          : Image.file(File(originalImagePath), fit: BoxFit.cover),
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          color: CyberTheme.inkBlack,
                                          child: Text('ORIGINAL', style: GoogleFonts.boogaloo(color: Colors.white, fontSize: 12)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Recreated
                              Expanded(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    border: Border(left: BorderSide(color: CyberTheme.inkBlack, width: 2)),
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      kIsWeb || capturedImagePath.startsWith('http')
                                          ? Image.network(capturedImagePath, fit: BoxFit.cover)
                                          : Image.file(File(capturedImagePath), fit: BoxFit.cover),
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          color: CyberTheme.limeGreen,
                                          child: Text('RESHOT', style: GoogleFonts.boogaloo(color: CyberTheme.inkBlack, fontSize: 12)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Footer Stats
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: CyberTheme.inkBlack,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '📍 $locationName',
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '#ReShotTheWorld',
                                    style: GoogleFonts.nunito(
                                      color: CyberTheme.sunOrange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: CyberTheme.limeGreen,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$matchScore% MATCH',
                                  style: GoogleFonts.boogaloo(
                                    fontSize: 16,
                                    color: CyberTheme.inkBlack,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Share Button
              MotionSystem.elasticBounce(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Saving to Gallery and opening Share sheet...', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
                      backgroundColor: CyberTheme.limeGreen,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: CyberTheme.hotPink,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: CyberTheme.inkBlack, width: 3),
                    boxShadow: const [
                      BoxShadow(color: CyberTheme.inkBlack, offset: Offset(4, 4)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '🚀 SHARE TO INSTAGRAM',
                      style: GoogleFonts.boogaloo(
                        fontSize: 20,
                        color: CyberTheme.cardWhite,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: Text(
                  'Back to Dashboard',
                  style: GoogleFonts.nunito(
                    color: CyberTheme.inkBlack,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

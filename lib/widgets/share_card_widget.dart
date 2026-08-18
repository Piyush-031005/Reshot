import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/cyber_theme.dart';
import '../models/reshot_capture_model.dart';

class ShareCardWidget extends StatelessWidget {
  final String imagePath;
  final String title;
  final String location;
  final String? emoji;
  final int? score;

  const ShareCardWidget({
    super.key,
    required this.imagePath,
    required this.title,
    required this.location,
    this.emoji,
    this.score,
  });

  factory ShareCardWidget.fromCapture(ReShotCaptureModel capture) {
    return ShareCardWidget(
      imagePath: capture.filePath,
      title: capture.locationName,
      location: 'ReSHOT Discovery',
      emoji: '💎',
      score: capture.score.round(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080 / 3, // Roughly 1/3 of Instagram story width for preview
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CyberTheme.cream,
        border: Border.all(color: CyberTheme.outlineBlack, width: 4),
        boxShadow: const [
          BoxShadow(
            color: CyberTheme.outlineBlack,
            offset: Offset(8, 8),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photo
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: CyberTheme.outlineBlack, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: imagePath.isNotEmpty
                    ? Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                      )
                    : Container(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (emoji != null) ...[
                Text(emoji!, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.boogaloo(
                        fontSize: 28,
                        color: CyberTheme.inkBlack,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📍 $location',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              if (score != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: CyberTheme.limeGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CyberTheme.outlineBlack, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$score%',
                        style: GoogleFonts.boogaloo(fontSize: 20, color: CyberTheme.inkBlack),
                      ),
                      Text(
                        'MATCH',
                        style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 24),
          const Divider(color: CyberTheme.outlineBlack, thickness: 2, height: 2),
          const SizedBox(height: 16),
          
          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📷', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Captured on ReSHOT',
                style: GoogleFonts.boogaloo(
                  fontSize: 18,
                  color: CyberTheme.electricBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> captureAndShare(BuildContext context, ReShotCaptureModel capture) async {
    final controller = ScreenshotController();
    final widget = ShareCardWidget.fromCapture(capture);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating Polaroid...', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: CyberTheme.inkBlack,
        duration: const Duration(milliseconds: 1500),
      ),
    );

    try {
      final bytes = await controller.captureFromWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: CyberTheme.themeData,
          home: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: widget),
          ),
        ),
        delay: const Duration(milliseconds: 200),
      );

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/share_${capture.id}.png').create();
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        xFiles: [XFile(file.path)],
        text: 'Check out my ${capture.score.round()}% match on ReSHOT! 📸',
      );
    } catch (e) {
      debugPrint('Share Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share.', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            backgroundColor: CyberTheme.hotPink,
          ),
        );
      }
    }
  }
}

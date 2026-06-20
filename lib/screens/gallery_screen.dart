import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/reshot_capture_model.dart';
import '../providers/repository_provider.dart';
import '../theme/cyber_theme.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _isLoading = true;
  List<ReShotCaptureModel> _captures = [];

  @override
  void initState() {
    super.initState();
    _loadCaptures();
  }

  Future<void> _loadCaptures() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await context.read<AppRepositoryProvider>().galleryRepository.getCaptures();
      setState(() {
        _captures = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading captures: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getBadgeTier(double score) {
    if (score >= 95.0) return 'LEGENDARY';
    if (score >= 85.0) return 'EPIC';
    if (score >= 70.0) return 'GREAT';
    return 'GOOD TRY';
  }

  Color _getBadgeColor(double score) {
    if (score >= 95.0) return CyberTheme.limeGreen;
    if (score >= 85.0) return CyberTheme.hotPink;
    if (score >= 70.0) return Colors.cyanAccent;
    return Colors.white54;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RESHOT_GALLERY.LOG',
          style: GoogleFonts.pressStart2p(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: CyberTheme.limeGreen,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: CyberTheme.limeGreen),
            )
          : _captures.isEmpty
              ? _buildEmptyState(context, textTheme)
              : _buildGalleryGrid(context, textTheme),
    );
  }

  Widget _buildEmptyState(BuildContext context, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: CyberTheme.cartoonDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.photo_library_outlined,
                color: CyberTheme.hotPink,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'NO RECREATIONS YET',
                style: GoogleFonts.pressStart2p(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Launch the position camera from the Dashboard, align with composition markers, and snap your first perfect photo!',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryGrid(BuildContext context, TextTheme textTheme) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: _captures.length,
      itemBuilder: (context, index) {
        final capture = _captures[index];
        final badge = _getBadgeTier(capture.score);      // raw score for classification
        final badgeColor = _getBadgeColor(capture.score); // raw score for color

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: CyberTheme.cartoonDecoration.copyWith(
            color: Colors.white, // Classic Polaroid background
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Frame
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: kIsWeb || capture.filePath.startsWith('http')
                      ? Image.network(
                          capture.filePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: CyberTheme.hotPink,
                                size: 32,
                              ),
                            );
                          },
                        )
                      : Image.file(
                          File(capture.filePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: CyberTheme.hotPink,
                                size: 32,
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 8),

              // Title and Score details
              Text(
                capture.locationName.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Badge tier
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.pressStart2p(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Date timestamp and score percentage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${capture.displayScore}% MATCH',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    _formatDate(capture.timestamp),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      color: Colors.black45,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year.toString().substring(2)}';
  }
}

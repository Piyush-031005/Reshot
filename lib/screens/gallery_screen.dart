import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/reshot_capture_model.dart';
import '../widgets/share_card_widget.dart';
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
    setState(() => _isLoading = true);
    try {
      final data = await context
          .read<AppRepositoryProvider>()
          .galleryRepository
          .getCaptures();
      setState(() {
        _captures = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading captures: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getBadgeTier(double score) {
    if (score >= 95.0) return '🌟 LEGENDARY';
    if (score >= 85.0) return '🔥 EPIC';
    if (score >= 70.0) return '✨ GREAT';
    return '👍 GOOD TRY';
  }

  Color _getBadgeColor(double score) {
    if (score >= 95.0) return CyberTheme.limeGreen;
    if (score >= 85.0) return CyberTheme.hotPink;
    if (score >= 70.0) return CyberTheme.electricBlue;
    return CyberTheme.sunOrange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.cream,
      appBar: AppBar(
        backgroundColor: CyberTheme.cream,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CyberTheme.cardWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CyberTheme.outlineBlack, width: 2),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: CyberTheme.inkBlack, size: 20),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🖼️', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'MY GALLERY',
              style: GoogleFonts.boogaloo(
                fontSize: 20,
                color: CyberTheme.inkBlack,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: CyberTheme.limeGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CyberTheme.limeGreen, width: 2),
            ),
            child: Text(
              '${_captures.length} shots',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: CyberTheme.inkBlack,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _captures.isEmpty
              ? _buildEmptyState()
              : _buildGalleryGrid(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(28),
        decoration: CyberTheme.cartoonCard,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📷', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Loading shots...',
              style: GoogleFonts.boogaloo(fontSize: 18, color: CyberTheme.inkBlack),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              color: CyberTheme.limeGreen,
              backgroundColor: CyberTheme.cream,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: CyberTheme.cartoonCard,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📸', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                'No shots yet!',
                style: GoogleFonts.boogaloo(fontSize: 22, color: CyberTheme.inkBlack),
              ),
              const SizedBox(height: 8),
              Text(
                'Launch Director Camera, align with a spot, and capture your first perfect shot!',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF888888),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: CyberTheme.hotPink,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: CyberTheme.outlineBlack, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: CyberTheme.outlineBlack,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    '🏠 Go to Dashboard',
                    style: GoogleFonts.boogaloo(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.68,
      ),
      itemCount: _captures.length,
      itemBuilder: (context, index) {
        final capture = _captures[index];
        final badgeColor = _getBadgeColor(capture.score);
        final badgeLabel = _getBadgeTier(capture.score);
        // Slight random tilt for polaroid feel
        final tiltAngle = (index % 3 == 1) ? 0.02 : (index % 3 == 2) ? -0.015 : 0.0;

        return Transform.rotate(
          angle: tiltAngle,
          child: _PolaroidCard(
            capture: capture,
            badgeColor: badgeColor,
            badgeLabel: badgeLabel,
          ),
        );
      },
    );
  }



}

// ─── Polaroid Card ────────────────────────────────────────────────────────────
class _PolaroidCard extends StatefulWidget {
  final ReShotCaptureModel capture;
  final Color badgeColor;
  final String badgeLabel;

  const _PolaroidCard({
    required this.capture,
    required this.badgeColor,
    required this.badgeLabel,
  });

  @override
  State<_PolaroidCard> createState() => _PolaroidCardState();
}

class _PolaroidCardState extends State<_PolaroidCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () async {
        await ShareCardWidget.captureAndShare(context, widget.capture);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: _pressed
            ? (Matrix4.identity()..translate(4.0, 4.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: CyberTheme.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CyberTheme.outlineBlack, width: 3),
          boxShadow: _pressed
              ? []
              : const [
                  BoxShadow(
                    color: CyberTheme.outlineBlack,
                    offset: Offset(5, 5),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo frame
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                    child: kIsWeb || widget.capture.filePath.startsWith('http')
                        ? Image.network(
                            widget.capture.filePath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFEEEEEE),
                              child: const Center(child: Text('🖼️', style: TextStyle(fontSize: 32))),
                            ),
                          )
                        : Image.file(
                            File(widget.capture.filePath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFEEEEEE),
                              child: const Center(child: Text('🖼️', style: TextStyle(fontSize: 32))),
                            ),
                          ),
                  ),
                  // Score badge overlay
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.badgeColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Text(
                        '${widget.capture.displayScore}%',
                        style: GoogleFonts.boogaloo(
                          fontSize: 12,
                          color: CyberTheme.inkBlack,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Polaroid label area
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.capture.locationName,
                    style: GoogleFonts.boogaloo(
                      fontSize: 13,
                      color: CyberTheme.inkBlack,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.badgeColor, width: 1.5),
                    ),
                    child: Text(
                      widget.badgeLabel,
                      style: GoogleFonts.nunito(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: widget.badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

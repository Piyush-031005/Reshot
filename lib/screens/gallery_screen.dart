import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/reshot_capture_model.dart';
import '../widgets/share_card_widget.dart';
import '../providers/repository_provider.dart';
import '../theme/design_system.dart';
import '../theme/motion_system.dart';
import 'dart:math' as math;

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
      
      if (!mounted) return;
      setState(() {
        _captures = data.reversed.toList(); // Newest first
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading captures: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Color _getBadgeColor(double score) {
    if (score >= 95.0) return ReShotDesignSystem.neonLime;
    if (score >= 85.0) return Colors.cyanAccent;
    if (score >= 70.0) return ReShotDesignSystem.sunOrange;
    return ReShotDesignSystem.hotPink;
  }

  String _getBadgeLabel(double score) {
    if (score >= 95.0) return 'GOD TIER';
    if (score >= 85.0) return 'EPIC';
    if (score >= 70.0) return 'SOLID';
    return 'NOVICE';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReShotDesignSystem.darkBg,
      appBar: AppBar(
        backgroundColor: ReShotDesignSystem.darkBg,
        elevation: 0,
        toolbarHeight: 80,
        leading: GestureDetector(
          onTap: () {
            MotionSystem.triggerImpactShake();
            Navigator.pop(context);
          },
          child: Container(
            margin: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
            decoration: BoxDecoration(
              color: ReShotDesignSystem.cardWhite,
              border: ReShotDesignSystem.brutalistBorder,
            ),
            child: const Icon(Icons.arrow_back_rounded, color: ReShotDesignSystem.inkBlack, size: 24),
          ),
        ),
        title: Text(
          'THE VAULT',
          style: ReShotDesignSystem.textTheme.displayMedium!.copyWith(
            color: Colors.white,
            fontSize: 28,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: ReShotDesignSystem.hotPink,
              border: ReShotDesignSystem.brutalistBorder,
            ),
            child: Center(
              child: Text(
                '${_captures.length} SHOTS',
                style: ReShotDesignSystem.textTheme.titleMedium!.copyWith(
                  color: Colors.white,
                ),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: ReShotDesignSystem.neonLime, strokeWidth: 6),
          const SizedBox(height: 24),
          Text(
            'LOADING ARCHIVES...',
            style: ReShotDesignSystem.textTheme.titleLarge!.copyWith(color: ReShotDesignSystem.neonLime),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: ReShotDesignSystem.streetPopCard.copyWith(color: ReShotDesignSystem.darkSurface),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('☠️', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              Text(
                'NO SHOTS YET',
                style: ReShotDesignSystem.textTheme.displayMedium!.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                'Hit the streets and start capturing.',
                style: ReShotDesignSystem.textTheme.bodyLarge!.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              MotionSystem.elasticBounce(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: ReShotDesignSystem.neonLime,
                    border: ReShotDesignSystem.brutalistBorder,
                  ),
                  child: Center(
                    child: Text(
                      'BACK TO RADAR',
                      style: ReShotDesignSystem.textTheme.titleLarge!.copyWith(color: ReShotDesignSystem.inkBlack),
                    ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
        childAspectRatio: 0.65,
      ),
      itemCount: _captures.length,
      itemBuilder: (context, index) {
        final capture = _captures[index];
        final badgeColor = _getBadgeColor(capture.score);
        final badgeLabel = _getBadgeLabel(capture.score);
        
        // Random slight rotation for that chaotic sticker-bomb look
        final isEven = index % 2 == 0;
        final rotation = isEven ? 0.03 : -0.02;

        return Transform.rotate(
          angle: rotation,
          child: MotionSystem.elasticBounce(
            onTap: () async {
              MotionSystem.triggerImpactShake();
              await ShareCardWidget.captureAndShare(context, capture);
            },
            child: Container(
              decoration: ReShotDesignSystem.streetPopCard.copyWith(
                color: ReShotDesignSystem.cardWhite,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: ReShotDesignSystem.brutalistBorder,
                            color: ReShotDesignSystem.inkBlack,
                          ),
                          child: kIsWeb || capture.filePath.startsWith('http')
                              ? Image.network(
                                  capture.filePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54),
                                )
                              : Image.file(
                                  File(capture.filePath),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54),
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              capture.locationName.toUpperCase(),
                              style: ReShotDesignSystem.textTheme.titleMedium!.copyWith(
                                color: ReShotDesignSystem.inkBlack,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${capture.displayScore}% MATCH',
                              style: ReShotDesignSystem.textTheme.bodyLarge!.copyWith(
                                color: ReShotDesignSystem.hotPink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Anime Sticker Badge
                  Positioned(
                    top: -10,
                    right: -10,
                    child: Transform.rotate(
                      angle: 0.15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          border: ReShotDesignSystem.brutalistBorder,
                          boxShadow: const [
                            BoxShadow(
                              color: ReShotDesignSystem.inkBlack,
                              offset: Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Text(
                          badgeLabel,
                          style: ReShotDesignSystem.textTheme.titleSmall!.copyWith(
                            color: badgeColor == ReShotDesignSystem.inkBlack ? Colors.white : ReShotDesignSystem.inkBlack,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

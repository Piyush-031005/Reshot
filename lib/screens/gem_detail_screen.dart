import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/hidden_gem_model.dart';
import '../models/location_model.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cartoon_widgets.dart';
import 'director_camera_screen.dart';

class GemDetailScreen extends StatelessWidget {
  final HiddenGemModel gem;

  const GemDetailScreen({
    super.key,
    required this.gem,
  });

  @override
  Widget build(BuildContext context) {
    final primaryTag = gem.tags.isNotEmpty ? gem.tags[0] : 'Hidden Gem';
    final tagColor = CyberTheme.gemTypeColor(primaryTag);
    final tagEmoji = CyberTheme.gemTypeEmoji(primaryTag);

    return Scaffold(
      backgroundColor: CyberTheme.cream,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Magazine-style hero header ────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
              decoration: BoxDecoration(
                color: tagColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
                border: const Border(
                  bottom: BorderSide(color: CyberTheme.outlineBlack, width: 3),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: CyberTheme.outlineBlack,
                    offset: Offset(0, 6),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black26, width: 1.5),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Big emoji badge
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white38, width: 2),
                    ),
                    child: Text(tagEmoji,
                        style: const TextStyle(fontSize: 36)),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    gem.name,
                    style: GoogleFonts.boogaloo(
                      fontSize: 30,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tags row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: gem.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white38, width: 1.5),
                        ),
                        child: Text(
                          '${CyberTheme.gemTypeEmoji(tag)} ${tag.toUpperCase()}',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // Coordinates card
                  Container(
                    width: double.infinity,
                    decoration: CyberTheme.cartoonCard,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: CyberTheme.inkBlack,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(18)),
                            border: const Border(
                              bottom: BorderSide(
                                  color: CyberTheme.outlineBlack, width: 3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text('📍', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                'COORDINATES',
                                style: GoogleFonts.boogaloo(
                                  fontSize: 14,
                                  color: CyberTheme.limeGreen,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: CyberTheme.limeGreen,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '⬆ ${gem.altitude}m',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: CyberTheme.inkBlack,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _CoordBox(
                                  label: 'LAT',
                                  value:
                                      gem.latitude.toStringAsFixed(6),
                                  color: CyberTheme.hotPink,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _CoordBox(
                                  label: 'LNG',
                                  value:
                                      gem.longitude.toStringAsFixed(6),
                                  color: CyberTheme.electricBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  SectionHeader(title: 'ABOUT THIS SPOT', emoji: '📖'),
                  const SizedBox(height: 10),
                  CartoonCard(
                    child: Text(
                      gem.description,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: CyberTheme.inkBlack,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Composition tips
                  SectionHeader(title: 'SHOOTING TIPS', emoji: '💡'),
                  const SizedBox(height: 10),
                  _buildTipCard('📐 Recommended Lens',
                      'Wide angle to capture the massive landscape background details.'),
                  const SizedBox(height: 10),
                  _buildTipCard('☀️ Optimal Light',
                      'Morning golden hour (7:00 AM - 9:00 AM) for bright background contrasts.'),
                  const SizedBox(height: 10),
                  _buildTipCard('👤 Subject Placement',
                      'Center lower-third relative to background ridge landmarks.'),
                  const SizedBox(height: 32),

                  // Launch CTA
                  CartoonButton(
                    label: 'LAUNCH DIRECTOR CAMERA',
                    emoji: '🎬',
                    color: CyberTheme.hotPink,
                    textColor: Colors.white,
                    height: 60,
                    onTap: () => _launchCamera(context),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(String title, String body) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: CyberTheme.cartoonCard,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.boogaloo(
                    fontSize: 14,
                    color: CyberTheme.inkBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _launchCamera(BuildContext context) {
    final location = LocationModel(
      id: gem.id,
      name: gem.name,
      distance: 'Live spot',
      description: gem.description,
      latitude: gem.latitude,
      longitude: gem.longitude,
      altitude: gem.altitude,
      tips: [
        'Recommended lens: Wide Angle',
        'Subject: Center lower-third',
        'Light: Morning golden hour',
      ],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => DirectorCameraScreen(location: location, mode: 'director'),
      ),
    );
  }
}

// ─── Coordinate Box ───────────────────────────────────────────────────────────
class _CoordBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CoordBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: CyberTheme.inkBlack,
            ),
          ),
        ],
      ),
    );
  }
}

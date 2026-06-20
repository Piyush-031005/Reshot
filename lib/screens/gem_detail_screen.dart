import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/hidden_gem_model.dart';
import '../models/location_model.dart';
import '../theme/cyber_theme.dart';
import 'director_camera_screen.dart';

class GemDetailScreen extends StatelessWidget {
  final HiddenGemModel gem;

  const GemDetailScreen({
    super.key,
    required this.gem,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          gem.name.toUpperCase(),
          style: GoogleFonts.pressStart2p(
            fontSize: 10,
            color: CyberTheme.limeGreen,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map-casing panel showing coordinates
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: CyberTheme.cartoonDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'COORDINATES LOCKED',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 8,
                          color: CyberTheme.hotPink,
                        ),
                      ),
                      Text(
                        'ALT: ${gem.altitude}',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 8,
                          color: CyberTheme.limeGreen,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 16),
                  Text(
                    'LAT: ${gem.latitude.toStringAsFixed(6)}',
                    style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'LNG: ${gem.longitude.toStringAsFixed(6)}',
                    style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Description
            Text(
              'DESCRIPTION',
              style: textTheme.titleLarge?.copyWith(
                color: CyberTheme.limeGreen,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              gem.description,
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),

            // Tags Wrap
            Text(
              'SPOT TAGS',
              style: textTheme.titleLarge?.copyWith(
                color: CyberTheme.limeGreen,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: gem.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CyberTheme.cyberDark,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Text(
                  tag.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: CyberTheme.hotPink,
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),

            // Recreation Tips Mock
            Text(
              'COMPOSITION GUIDELINE TIPS',
              style: textTheme.titleLarge?.copyWith(
                color: CyberTheme.limeGreen,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            _buildTipRow('Recommended Lens', 'Wide angle to capture the massive landscape background details.'),
            _buildTipRow('Optimal Light', 'Morning golden hour (7:00 AM - 9:00 AM) for bright background contrasts.'),
            _buildTipRow('Subject Placement', 'Center lower-third relative to background ridge landmarks.'),
            const SizedBox(height: 32),

            // Launch button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: CyberTheme.hotPink,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 55),
                shape: const RoundedRectangleBorder(
                  side: BorderSide(color: Colors.black, width: 3),
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed: () => _launchCamera(context),
              child: Text(
                'LAUNCH AUTO-CAPTURE CAMERA',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: CyberTheme.hotPink, fontSize: 16)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.white70),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  TextSpan(text: value),
                ],
              ),
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
        'Light: Morning golden hour'
      ],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => DirectorCameraScreen(
          location: location,
          mode: 'director',
        ),
      ),
    );
  }
}

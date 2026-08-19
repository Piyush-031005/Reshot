import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/hidden_gem_model.dart';
import '../models/location_model.dart';
import '../theme/cyber_theme.dart';
import '../theme/design_system.dart';
import '../theme/motion_system.dart';
import 'director_camera_screen.dart';

class NavigationStandbyScreen extends StatelessWidget {
  final HiddenGemModel targetGem;
  final String detectedPose;

  const NavigationStandbyScreen({
    super.key,
    required this.targetGem,
    required this.detectedPose,
  });

  Future<void> _launchMaps() async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${targetGem.latitude},${targetGem.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch maps for $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: CyberTheme.cream,
      appBar: AppBar(
        backgroundColor: CyberTheme.inkBlack,
        iconTheme: const IconThemeData(color: CyberTheme.cardWhite),
        title: Text(
          'EN ROUTE',
          style: textTheme.titleLarge!.copyWith(
            color: CyberTheme.limeGreen,
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
              // Header
              Text(
                'DESTINATION',
                style: textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                targetGem.name,
                style: textTheme.titleLarge!.copyWith(color: CyberTheme.hotPink),
              ),
              Text(
                targetGem.description,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // Maps Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: ReShotDesignSystem.streetPopColoredCard(CyberTheme.cardWhite),
                child: Column(
                  children: [
                    Text('ðŸ—ºï¸', style: textTheme.displayLarge),
                    const SizedBox(height: 16),
                    Text(
                      'Let Google Maps guide you there.',
                      style: textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    MotionSystem.elasticBounce(
                      onTap: _launchMaps,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: CyberTheme.electricBlue,
                          borderRadius: BorderRadius.circular(12),
                          border: ReShotDesignSystem.brutalistBorder,
                          boxShadow: ReShotDesignSystem.brutalistShadow,
                        ),
                        child: Center(
                          child: Text(
                            'OPEN GOOGLE MAPS',
                            style: textTheme.titleLarge!.copyWith(color: CyberTheme.cardWhite),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),

              // The "I've Arrived" Button
              Text(
                'Once you reach the spot, tap below to launch the AI Camera Coach.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              MotionSystem.elasticBounce(
                onTap: () {
                  final locationModel = LocationModel(
                    id: targetGem.id,
                    name: targetGem.name,
                    distance: 'Arrived',
                    description: targetGem.description,
                    latitude: targetGem.latitude,
                    longitude: targetGem.longitude,
                    altitude: targetGem.altitude,
                    photoPath: targetGem.photoPath,
                    tags: targetGem.tags,
                    tips: [
                      'AI Detected Pose: $detectedPose',
                      'Align the ghost vector to match the reference'
                    ],
                  );

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (c) => DirectorCameraScreen(
                        location: locationModel,
                        mode: 'director',
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: CyberTheme.limeGreen,
                    borderRadius: BorderRadius.circular(16),
                    border: ReShotDesignSystem.brutalistBorder,
                    boxShadow: ReShotDesignSystem.brutalistShadow,
                  ),
                  child: Center(
                    child: Text(
                      "I'VE ARRIVED (LAUNCH CAMERA)",
                      style: textTheme.titleLarge!.copyWith(
                        color: CyberTheme.inkBlack,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}



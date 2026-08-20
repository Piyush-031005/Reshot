import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../theme/cyber_theme.dart';
import '../theme/design_system.dart';
import '../theme/motion_system.dart';
import '../models/hidden_gem_model.dart';
import '../providers/findra_engine_provider.dart';
import 'navigation_standby_screen.dart';

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> with TickerProviderStateMixin {
  File? _selectedImage;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      if (mounted) {
        context.read<FindraEngineProvider>().reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final engine = context.watch<FindraEngineProvider>();

    return Scaffold(
      backgroundColor: CyberTheme.cream,
      appBar: AppBar(
        backgroundColor: CyberTheme.inkBlack,
        iconTheme: const IconThemeData(color: CyberTheme.cardWhite),
        title: Text(
          'FINDRA AI',
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
              Text(
                'Upload a photo to find a similar vibe nearby.',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Image Container
              Expanded(
                child: MotionSystem.elasticBounce(
                  onTap: () { if (engine.state != EngineState.analyzing) _pickImage(); },
                  scaleDown: 0.95,
                  child: Container(
                    decoration: BoxDecoration(
                      color: CyberTheme.cardWhite,
                      borderRadius: BorderRadius.circular(24),
                      border: ReShotDesignSystem.brutalistBorder,
                      boxShadow: ReShotDesignSystem.brutalistShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _selectedImage != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_selectedImage!, fit: BoxFit.cover),
                              if (engine.state == EngineState.analyzing)
                                Container(
                                  color: Colors.black87,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ScaleTransition(
                                          scale: Tween<double>(begin: 0.9, end: 1.1).animate(_pulseController),
                                          child: Text('ðŸ‘ï¸', style: textTheme.displayLarge!.copyWith(color: Colors.white)),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Analyzing Image...',
                                          style: textTheme.titleLarge!.copyWith(color: CyberTheme.limeGreen),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Extracting labels & searching maps',
                                          style: textTheme.bodySmall!.copyWith(color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_rounded, size: 64, color: CyberTheme.hotPink),
                              const SizedBox(height: 16),
                              Text(
                                'Tap to Upload',
                                style: textTheme.titleLarge,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Result Card
              if (engine.state == EngineState.success && engine.resultName != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: ReShotDesignSystem.streetPopColoredCard(CyberTheme.limeGreen),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('âœ¨', style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Similar Vibe Found!',
                                  style: textTheme.titleLarge,
                                ),
                                Text(
                                  'Found a similar spot nearby based on labels.',
                                  style: textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // AI Inference Details
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: CyberTheme.inkBlack,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Detected: ${engine.detectedLabels.take(3).join(", ")}',
                                style: textTheme.bodySmall!.copyWith(color: CyberTheme.cardWhite),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CyberTheme.cardWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: CyberTheme.outlineBlack, width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(engine.resultName!, style: textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                                  Text('${engine.resultLat!.toStringAsFixed(4)}, ${engine.resultLon!.toStringAsFixed(4)}', style: textTheme.bodySmall),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CyberTheme.inkBlack,
                                foregroundColor: CyberTheme.cardWhite,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                textStyle: textTheme.bodyLarge,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              onPressed: () {
                                final gem = HiddenGemModel(
                                  id: 'osm-temp',
                                  name: engine.resultName!,
                                  description: 'Discovered via Findra AI',
                                  latitude: engine.resultLat!,
                                  longitude: engine.resultLon!,
                                  altitude: 'Unknown',
                                  tags: engine.detectedLabels,
                                  photoPath: _selectedImage?.path ?? '',
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                  ownerId: 'findra-ai',
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (c) => NavigationStandbyScreen(
                                      targetGem: gem,
                                      detectedPose: 'Standing', // Defaulting for now
                                    ),
                                  ),
                                );
                              },
                              child: const Text('GO THERE'),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ] else if (engine.state == EngineState.error) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: ReShotDesignSystem.streetPopColoredCard(CyberTheme.hotPink),
                  child: Text(
                    engine.errorMessage ?? 'An error occurred.',
                    style: textTheme.bodyMedium!.copyWith(color: CyberTheme.inkBlack, fontWeight: FontWeight.bold),
                  ),
                ),
              ] else if (_selectedImage != null && engine.state == EngineState.idle) ...[
                MotionSystem.elasticBounce(
                  onTap: () {
                    context.read<FindraEngineProvider>().processPhoto(_selectedImage!.path);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: CyberTheme.inkBlack,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: CyberTheme.outlineBlack, offset: Offset(4, 4)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'FIND THIS PLACE',
                        style: textTheme.titleLarge!.copyWith(
                          color: CyberTheme.cardWhite,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


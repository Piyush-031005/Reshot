import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/cyber_theme.dart';
import '../theme/design_system.dart';
import '../theme/motion_system.dart';
import 'package:provider/provider.dart';
import '../models/hidden_gem_model.dart';
import '../providers/repository_provider.dart';
import 'navigation_standby_screen.dart';

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> with TickerProviderStateMixin {
  File? _selectedImage;
  bool _isAnalyzing = false;
  bool _showResult = false;
  
  // AI Mock Data
  HiddenGemModel? _matchedGem;
  bool _isExactMatch = false;
  String _detectedPose = "Standing";
  
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
        _showResult = false;
      });
    }
  }

  Future<void> _analyzeImage() async {
    setState(() => _isAnalyzing = true);
    
    // ─── AI Mock Logic (Vibe & Pose Detection) ───
    final allGems = await context.read<AppRepositoryProvider>().hiddenGemRepository.getHiddenGems();
    if (allGems.isEmpty) return; // Should not happen, but safeguard
    
    final random = Random();
    
    // Randomly pick a gem to "match"
    _matchedGem = allGems[random.nextInt(allGems.length)];
    // Randomly decide if it's an exact match or similar vibe (mostly similar)
    _isExactMatch = random.nextDouble() > 0.7; 
    // Randomly detect a pose
    _detectedPose = random.nextBool() ? "Standing" : "Sitting";
    
    // Mock AI Analysis Delay
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _showResult = true;
      });
    });
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
          'AI PLACE FINDER',
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
                'Upload a photo you want to recreate.',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Image Container
              Expanded(
                child: MotionSystem.elasticBounce(
                  onTap: () { if (!_isAnalyzing) _pickImage(); },
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
                              if (_isAnalyzing)
                                Container(
                                  color: Colors.black87,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ScaleTransition(
                                          scale: Tween<double>(begin: 0.9, end: 1.1).animate(_pulseController),
                                          child: Text('👁️', style: textTheme.displayLarge!.copyWith(color: Colors.white)),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Analyzing Image...',
                                          style: textTheme.titleLarge!.copyWith(color: CyberTheme.limeGreen),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Extracting subject pose & background vibe',
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
              if (_showResult && _matchedGem != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: ReShotDesignSystem.streetPopColoredCard(CyberTheme.limeGreen),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(_isExactMatch ? '📍' : '✨', style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isExactMatch ? 'Exact Match Found!' : 'Similar Vibe Found!',
                                  style: textTheme.titleLarge,
                                ),
                                Text(
                                  _isExactMatch 
                                    ? 'We found the exact location from the photo.'
                                    : 'No exact match. Found a similar ${_matchedGem!.tags.first.toLowerCase()} nearby.',
                                  style: textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // AI Inference Details (Confidence/Pose)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: CyberTheme.inkBlack,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pose: $_detectedPose',
                              style: textTheme.bodySmall!.copyWith(color: CyberTheme.cardWhite),
                            ),
                            Text(
                              'Match: ${_isExactMatch ? '99%' : '${80 + Random().nextInt(15)}%'}',
                              style: textTheme.bodySmall!.copyWith(color: CyberTheme.limeGreen),
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
                                  Text(_matchedGem!.name, style: textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                                  Text('${_matchedGem!.latitude.toStringAsFixed(4)}, ${_matchedGem!.longitude.toStringAsFixed(4)}', style: textTheme.bodySmall),
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (c) => NavigationStandbyScreen(
                                      targetGem: _matchedGem!,
                                      detectedPose: _detectedPose,
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
              ] else if (_selectedImage != null && !_isAnalyzing) ...[
                MotionSystem.elasticBounce(
                  onTap: _analyzeImage,
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

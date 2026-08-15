import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/cyber_theme.dart';
import '../theme/design_system.dart';
import '../theme/motion_system.dart';
import 'dashboard.dart';

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> with TickerProviderStateMixin {
  File? _selectedImage;
  bool _isAnalyzing = false;
  bool _showResult = false;
  
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

  void _analyzeImage() {
    setState(() => _isAnalyzing = true);
    
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
    return Scaffold(
      backgroundColor: CyberTheme.cream,
      appBar: AppBar(
        backgroundColor: CyberTheme.inkBlack,
        iconTheme: const IconThemeData(color: CyberTheme.cardWhite),
        title: Text(
          'AI PLACE FINDER',
          style: GoogleFonts.boogaloo(
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
              const Text(
                'Upload a photo you want to recreate.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CyberTheme.inkBlack,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Image Container
              Expanded(
                child: MotionSystem.elasticBounce(
                  onTap: _isAnalyzing ? null : () => _pickImage(),
                  scaleDown: 0.95,
                  child: Container(
                    decoration: BoxDecoration(
                      color: CyberTheme.cardWhite,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: CyberTheme.outlineBlack, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: CyberTheme.outlineBlack,
                          offset: Offset(8, 8),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _selectedImage != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_selectedImage!, fit: BoxFit.cover),
                              if (_isAnalyzing)
                                Container(
                                  color: Colors.black54,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ScaleTransition(
                                          scale: Tween<double>(begin: 0.9, end: 1.1).animate(_pulseController),
                                          child: const Text('🧠', style: TextStyle(fontSize: 48)),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Analyzing Scenery...',
                                          style: GoogleFonts.nunito(
                                            color: CyberTheme.limeGreen,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Extracting landmarks & terrain data',
                                          style: TextStyle(color: Colors.white70),
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
                                style: GoogleFonts.boogaloo(fontSize: 24),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Result Card
              if (_showResult) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: ReShotDesignSystem.streetPopColoredCard(CyberTheme.limeGreen),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Similar Vibe Found!',
                                  style: GoogleFonts.boogaloo(fontSize: 20),
                                ),
                                const Text(
                                  'No exact match. Found a similar waterfall nearby.',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Sasling Cascade', style: GoogleFonts.boogaloo(fontSize: 18)),
                                Text('98% Match', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: CyberTheme.hotPink)),
                              ],
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CyberTheme.inkBlack,
                                foregroundColor: CyberTheme.cardWhite,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                Navigator.pop(context); // Go back to dashboard where Sasling is
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
                        style: GoogleFonts.boogaloo(
                          fontSize: 20,
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

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../widgets/cartoon_widgets.dart';
import 'recreation_card_screen.dart';
import '../models/location_model.dart';
import '../models/reshot_capture_model.dart';
import '../providers/repository_provider.dart';
import '../theme/design_system.dart';
import '../theme/motion_system.dart';
import '../widgets/composition_overlay_painter.dart';

class DirectorCameraScreen extends StatefulWidget {
  final LocationModel location;
  final String mode; // 'director' or 'echo'

  const DirectorCameraScreen({
    super.key,
    required this.location,
    required this.mode,
  });

  @override
  State<DirectorCameraScreen> createState() => _DirectorCameraScreenState();
}

class _DirectorCameraScreenState extends State<DirectorCameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;

  // Real-time sensor indicators
  double _pitch = 0.0;
  double _roll = 0.0;
  StreamSubscription<AccelerometerEvent>? _sensorSubscription;

  // Simulated framing parameters
  double _posX = 20.0;
  double _scale = 75.0;

  // RAW score â€” never rounded. Used for badge classification.
  double _rawScore = 30.0;
  // Display score â€” rounded to 1dp for UI only.
  double _displayScore = 30.0;

  bool _isAligned = false;
  bool _isCapturing = false;
  Timer? _shutterTimer;

  String _activeState = 'lock';
  XFile? _capturedFile;
  
  double _ghostOpacity = 0.4;
  double _ghostOffsetX = 0.0;
  double _ghostOffsetY = 0.0;
  double _ghostScale = 1.0;
  bool _hasPerson = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startSensorTracking();
    
    final tags = widget.location.tags ?? [];
    _hasPerson = tags.any((tag) {
      final t = tag.toLowerCase();
      return t.contains('person') || t.contains('human') || t.contains('face') || t.contains('people') || t.contains('boy') || t.contains('girl');
    });
    
    if (!_hasPerson) {
      _activeState = 'handover'; // skip lock state if no person
      _isAligned = true; // allow free shooting
    }
  }

  void _initializeCamera() {
    final cameras = context.read<AppRepositoryProvider>().cameras;
    if (cameras.isEmpty) {
      debugPrint('No camera devices found');
      return;
    }

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _controller!.initialize().then((_) {
      // Fix 1: mounted check after async gap
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    }).catchError((e) {
      debugPrint('Camera init error: $e');
    });
  }

  DateTime _lastSensorUpdate = DateTime.now();

  void _startSensorTracking() {
    _sensorSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (!mounted) return;
      
      final now = DateTime.now();
      if (now.difference(_lastSensorUpdate).inMilliseconds > 50) {
        _lastSensorUpdate = now;
        setState(() {
          _pitch = event.x;
          _roll = event.y;
          _calculateScore();
        });
      }
    });
  }

  void _calculateScore() {
    // Fix 2: compute raw score â€” NO rounding applied here.
    // Badge classification uses _rawScore directly, never _displayScore.
    double pitchDiff = _pitch.abs();
    double rollDiff = (_roll.abs() - 9.8).abs();
    double xDiff = (_posX - 50.0).abs();
    double scaleDiff = (_scale - 100.0).abs();

    double pitchAccuracy = (100 - (pitchDiff * 10)).clamp(0, 100);
    double rollAccuracy = (100 - (rollDiff * 10)).clamp(0, 100);
    double xAccuracy = (100 - (xDiff * 2)).clamp(0, 100);
    double scaleAccuracy = (100 - (scaleDiff * 2)).clamp(0, 100);

    // Raw score â€” full precision double, no rounding.
    _rawScore = (pitchAccuracy * 0.25) +
                (rollAccuracy * 0.25) +
                (xAccuracy * 0.25) +
                (scaleAccuracy * 0.25);

    // Display score â€” rounded to 1dp for UI display only.
    _displayScore = double.parse(_rawScore.toStringAsFixed(1));

    // Alignment uses _rawScore (strict, unrounded).
    if (!_hasPerson) {
      _isAligned = true;
      return;
    }

    if (_rawScore >= 92.0) {
      if (!_isAligned) {
        _isAligned = true;
        if (_activeState == 'handover') {
          _triggerAutoShutter();
        }
      }
    } else {
      if (_isAligned) {
        _isAligned = false;
        _shutterTimer?.cancel();
      }
    }
  }

  String _getGuidanceText() {
    if (!_hasPerson) return 'Align ghost image and shoot when ready!';
    if (_isAligned) return 'Hold steady...';
    
    // Pitch is up/down tilt. Ideal is 0.
    if (_pitch > 1.5) return 'Tilt phone down slightly ðŸ‘‡';
    if (_pitch < -1.5) return 'Tilt phone up slightly ðŸ‘†';
    
    // Roll is side-to-side twist. Ideal is 9.8 (upright).
    if (_roll > 10.5) return 'Level phone left ðŸ‘ˆ';
    if (_roll < 9.0) return 'Level phone right ðŸ‘‰';

    // Position & Scale (simulated by sliders right now, ideal 50/100)
    if (_posX < 45) return 'Move camera right ðŸ‘‰';
    if (_posX > 55) return 'Move camera left ðŸ‘ˆ';
    if (_scale < 95) return 'Move closer to subject ðŸš¶â€â™‚ï¸';
    if (_scale > 105) return 'Step back from subject ðŸš¶â€â™€ï¸';

    return 'Almost there...';
  }

  void _triggerAutoShutter() {
    _shutterTimer?.cancel();
    _shutterTimer = Timer(const Duration(milliseconds: 1200), () async {
      // Fix 1: guard â€” if widget disposed before timer fires, abort.
      if (!mounted) return;
      if (_isAligned && !_isCapturing) {
        await _captureImage();
      }
    });
  }

  // Fix 2: Badge uses raw unrounded score.
  String _getBadgeTier(double rawScore) {
    if (rawScore >= 95.0) return 'LEGENDARY';
    if (rawScore >= 85.0) return 'EPIC';
    if (rawScore >= 70.0) return 'GREAT';
    return 'GOOD TRY';
  }

  Future<void> _captureImage() async {
    // Fix 1: mounted check at entry of async operation.
    if (!mounted) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // Cache provider before any await â€” avoids BuildContext across async gap warning.
      final provider = context.read<AppRepositoryProvider>();

      XFile file;
      if (_controller == null || !_controller!.value.isInitialized || kIsWeb) {
        // Anime-style Mount Fuji / Japan mock photo
        final mockUrl = 'https://images.unsplash.com/photo-1528164344705-47542687000d?w=600&h=800&fit=crop';
        file = XFile(mockUrl);
      } else {
        file = await _controller!.takePicture();
      }

      // Fix 2: badge computed from raw unrounded score.
      final newCapture = ReShotCaptureModel(
        id: const Uuid().v4(),
        filePath: file.path,
        score: _rawScore,          // store full precision
        displayScore: _displayScore, // store rounded for display
        badge: _getBadgeTier(_rawScore), // classified from raw
        timestamp: DateTime.now(),
        updatedAt: DateTime.now(),
        locationName: widget.location.name,
      );

      await provider.saveCapture(newCapture);

      // Fix 1: mounted check after all awaits before any UI call.
      if (!mounted) return;

      setState(() {
        _capturedFile = file;
        _isCapturing = false;
      });
      _showCaptureSuccessDialog();
    } catch (e) {
      debugPrint('Error snapping picture: $e');
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save photo! Check storage permissions.',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
          ),
          backgroundColor: ReShotDesignSystem.hotPink,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCaptureSuccessDialog() {
    if (!mounted || _capturedFile == null) return;

    // Trigger haptic impact
    MotionSystem.triggerImpactShake();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RecreationCardScreen(
          originalImagePath: widget.location.photoPath,
          capturedImagePath: _capturedFile!.path,
          matchScore: _displayScore,
          locationName: widget.location.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReShotDesignSystem.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top HUD Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              color: ReShotDesignSystem.darkBg,
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white30, width: 1.5),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.mode == 'director' ? 'ðŸŽ¬ DIRECTOR CAMERA' : 'ðŸ”ï¸ LANDMARK ECHO',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // Stage badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _activeState == 'lock'
                          ? ReShotDesignSystem.neonLime
                          : ReShotDesignSystem.hotPink,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Text(
                      _activeState == 'lock' ? 'â‘  SET COMP' : 'â‘¡ HANDED OVER',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w800,
                        color: ReShotDesignSystem.inkBlack,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Live Camera Area
            Expanded(
              child: Stack(
                children: [
                  // Camera preview
                  if (_isCameraInitialized && _controller != null && !kIsWeb)
                    SizedBox.expand(child: CameraPreview(_controller!))
                  else
                    Container(
                      color: ReShotDesignSystem.darkBg,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: 0.25,
                            child: Image.network(
                              'https://images.unsplash.com/photo-1528164344705-47542687000d?w=600&h=800&fit=crop',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.videocam_outlined,
                                color: ReShotDesignSystem.neonLime,
                                size: 48,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'SIMULATING LIVE FEED',
                                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                  color: ReShotDesignSystem.neonLime,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Align sliders below to lock and test matching logic.',
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Ghost Photographer AR Layer (Reference Photo)
                  Positioned(
                    left: _ghostOffsetX,
                    top: _ghostOffsetY,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _ghostOffsetX += details.delta.dx;
                          _ghostOffsetY += details.delta.dy;
                        });
                      },
                      child: Opacity(
                        opacity: _ghostOpacity,
                        child: Transform.scale(
                          scale: _ghostScale,
                          child: (widget.location.photoPath != null && widget.location.photoPath!.isNotEmpty)
                              ? Image.file(
                                  File(widget.location.photoPath!),
                                  width: MediaQuery.of(context).size.width,
                                  height: MediaQuery.of(context).size.height,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  'https://images.unsplash.com/photo-1528164344705-47542687000d?w=600&h=800&fit=crop',
                                  width: MediaQuery.of(context).size.width,
                                  height: MediaQuery.of(context).size.height,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                  ),

                  // The Grid/Crosshair overlay
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: CompositionOverlayPainter(
                          pitch: _pitch,
                          roll: _roll,
                          posX: _posX,
                          scale: _scale,
                          isAligned: _isAligned,
                          activeState: _activeState,
                          hasPerson: _hasPerson,
                          detectedPose: widget.location.tips.firstWhere(
                              (t) => t.startsWith('AI Detected Pose: '),
                              orElse: () => 'Standing').replaceAll('AI Detected Pose: ', '').trim(),
                        ),
                      ),
                    ),
                  ),
                  
                  // Vertical Opacity Slider for Ghost Layer
                  Positioned(
                    right: 16,
                    top: 100,
                    bottom: 200,
                    child: Column(
                      children: [
                        Text(
                          'GHOST',
                          style: ReShotDesignSystem.textTheme.titleSmall!.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                        Expanded(
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: ReShotDesignSystem.neonLime,
                                inactiveTrackColor: Colors.white30,
                                thumbColor: ReShotDesignSystem.cardWhite,
                                overlayColor: ReShotDesignSystem.neonLime.withValues(alpha: 0.2),
                                trackHeight: 6,
                              ),
                              child: Slider(
                                value: _ghostOpacity,
                                min: 0.0,
                                max: 1.0,
                                onChanged: (val) {
                                  setState(() => _ghostOpacity = val);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Alignment HUD â€” cartoon speech bubble style
                  Positioned(
                    top: 14,
                    left: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isAligned
                            ? ReShotDesignSystem.neonLime.withValues(alpha: 0.95)
                            : ReShotDesignSystem.hotPink.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Emoji status
                          Text(
                            _isAligned ? 'âœ…' : 'ðŸŽ¯',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isAligned ? 'PERFECT!' : 'ALIGN IT',
                                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                    color: ReShotDesignSystem.inkBlack,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  _getGuidanceText(),
                                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                                    color: ReShotDesignSystem.inkBlack.withValues(alpha: 0.8),
                                    fontSize: 22, // Caveat needs larger size
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Big score display
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: ReShotDesignSystem.inkBlack,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$_displayScore%',
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                fontSize: 22,
                                color: _isAligned ? ReShotDesignSystem.neonLime : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Shutter flash
                  if (_isCapturing)
                    Container(color: Colors.white),
                ],
              ),
            ),

            // Bottom Controller Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              color: ReShotDesignSystem.darkSurface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_activeState == 'lock') ...[
                    Text(
                      'ðŸ•¹ï¸ DRAG TO COMPOSE',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white54,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // The POS and ZOOM sliders were removed to simplify the Smart Coach UI
                    const SizedBox(height: 12),
                    // Lock & Handover button
                    GestureDetector(
                      onTap: () => setState(() {
                        _activeState = 'handover';
                        _posX = 24.0;
                        _scale = 80.0;
                        _calculateScore();
                      }),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: ReShotDesignSystem.neonLime,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'ðŸ”’ LOCK & HAND OVER',
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                              color: ReShotDesignSystem.inkBlack,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Handed-over panel
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ReShotDesignSystem.hotPink.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: ReShotDesignSystem.hotPink, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Text('ðŸ¤³', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HANDED OVER!',
                                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                    color: ReShotDesignSystem.hotPink,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Stranger just needs to align â€” auto-clicks when matched!',
                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _activeState = 'lock';
                              _shutterTimer?.cancel();
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white30, width: 2),
                              ),
                              child: Center(
                                  child: Text(
                                    'â†© RE-COMPOSE',
                                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Shutter button
                        GestureDetector(
                          onTap: _isCapturing ? null : _captureImage,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: _isAligned ? ReShotDesignSystem.neonLime : const Color(0xFF333333),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isAligned ? Colors.black : Colors.white30,
                                width: 3,
                              ),
                              boxShadow: _isAligned
                                  ? const [
                                      BoxShadow(
                                        color: Colors.black,
                                        offset: Offset(3, 3),
                                        blurRadius: 0,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              _isCapturing ? Icons.hourglass_top : Icons.camera_alt_rounded,
                              color: _isAligned ? Colors.black : Colors.white30,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _shutterTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}




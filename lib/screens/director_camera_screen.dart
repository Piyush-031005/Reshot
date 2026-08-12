import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/location_model.dart';
import '../models/reshot_capture_model.dart';
import '../providers/repository_provider.dart';
import '../theme/cyber_theme.dart';
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

  // RAW score — never rounded. Used for badge classification.
  double _rawScore = 30.0;
  // Display score — rounded to 1dp for UI only.
  double _displayScore = 30.0;

  bool _isAligned = false;
  bool _isCapturing = false;
  Timer? _shutterTimer;

  String _activeState = 'lock';
  XFile? _capturedFile;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startSensorTracking();
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

  void _startSensorTracking() {
    _sensorSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      // Fix 1: mounted check inside stream listener
      if (!mounted) return;
      setState(() {
        _pitch = event.x;
        _roll = event.y;
        _calculateScore();
      });
    });
  }

  void _calculateScore() {
    // Fix 2: compute raw score — NO rounding applied here.
    // Badge classification uses _rawScore directly, never _displayScore.
    double pitchDiff = _pitch.abs();
    double rollDiff = (_roll.abs() - 9.8).abs();
    double xDiff = (_posX - 50.0).abs();
    double scaleDiff = (_scale - 100.0).abs();

    double pitchAccuracy = (100 - (pitchDiff * 10)).clamp(0, 100);
    double rollAccuracy = (100 - (rollDiff * 10)).clamp(0, 100);
    double xAccuracy = (100 - (xDiff * 2)).clamp(0, 100);
    double scaleAccuracy = (100 - (scaleDiff * 2)).clamp(0, 100);

    // Raw score — full precision double, no rounding.
    _rawScore = (pitchAccuracy * 0.25) +
                (rollAccuracy * 0.25) +
                (xAccuracy * 0.25) +
                (scaleAccuracy * 0.25);

    // Display score — rounded to 1dp for UI display only.
    _displayScore = double.parse(_rawScore.toStringAsFixed(1));

    // Alignment uses _rawScore (strict, unrounded).
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

  void _triggerAutoShutter() {
    _shutterTimer?.cancel();
    _shutterTimer = Timer(const Duration(milliseconds: 1200), () async {
      // Fix 1: guard — if widget disposed before timer fires, abort.
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
      // Cache provider before any await — avoids BuildContext across async gap warning.
      final provider = context.read<AppRepositoryProvider>();

      XFile file;
      if (_controller == null || !_controller!.value.isInitialized || kIsWeb) {
        final seed = DateTime.now().millisecondsSinceEpoch;
        final mockUrl = 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600&h=800&fit=crop&sig=$seed';
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
      // Fix 1: mounted check in error handler too.
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
      });
    }
  }

  void _showCaptureSuccessDialog() {
    // Fix 1: mounted check before showDialog.
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: CyberTheme.outlineBlack, width: 3),
            boxShadow: const [
              BoxShadow(
                color: CyberTheme.outlineBlack,
                offset: Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CyberTheme.limeGreen,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  border: const Border(
                    bottom: BorderSide(color: CyberTheme.outlineBlack, width: 3),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'PERFECT SHOT!',
                        style: GoogleFonts.boogaloo(
                          fontSize: 22,
                          color: CyberTheme.inkBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Photo preview
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: CyberTheme.outlineBlack, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: CyberTheme.outlineBlack,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: _capturedFile != null
                            ? (kIsWeb || _capturedFile!.path.startsWith('http')
                                ? Image.network(_capturedFile!.path, fit: BoxFit.cover)
                                : Image.file(File(_capturedFile!.path), fit: BoxFit.cover))
                            : Container(
                                color: const Color(0xFFEEEEEE),
                                child: const Center(child: Text('📷', style: TextStyle(fontSize: 48))),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Score badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: CyberTheme.inkBlack,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🎯', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            'MATCH: $_displayScore%',
                            style: GoogleFonts.boogaloo(
                              fontSize: 18,
                              color: CyberTheme.limeGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Saved to your gallery! Great work! 🌟',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF666666),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Return button
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        if (mounted) Navigator.pop(context);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                        child: Center(
                          child: Text(
                            '🏠 BACK TO HOME',
                            style: GoogleFonts.boogaloo(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top HUD Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              color: CyberTheme.darkBg,
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
                      widget.mode == 'director' ? '🎬 DIRECTOR CAMERA' : '🏔️ LANDMARK ECHO',
                      style: GoogleFonts.boogaloo(
                        fontSize: 16,
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
                          ? CyberTheme.limeGreen
                          : CyberTheme.hotPink,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Text(
                      _activeState == 'lock' ? '① SET COMP' : '② HANDED OVER',
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

            // Live Camera Area
            Expanded(
              child: Stack(
                children: [
                  // Camera preview
                  if (_isCameraInitialized && _controller != null && !kIsWeb)
                    SizedBox.expand(child: CameraPreview(_controller!))
                  else
                    Container(
                      color: CyberTheme.cyberBlack,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: 0.15,
                            child: Image.network(
                              'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600&h=800&fit=crop',
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
                                color: CyberTheme.limeGreen,
                                size: 48,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'SIMULATING LIVE FEED',
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 10,
                                  color: CyberTheme.limeGreen,
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

                  // Overlay
                  Positioned.fill(
                    child: CustomPaint(
                      painter: CompositionOverlayPainter(
                        pitch: _pitch,
                        roll: _roll,
                        posX: _posX,
                        scale: _scale,
                        isAligned: _isAligned,
                        activeState: _activeState,
                      ),
                    ),
                  ),

                  // Alignment HUD — cartoon speech bubble style
                  Positioned(
                    top: 14,
                    left: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isAligned
                            ? CyberTheme.limeGreen.withValues(alpha: 0.95)
                            : CyberTheme.hotPink.withValues(alpha: 0.95),
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
                            _isAligned ? '✅' : '🎯',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isAligned ? 'PERFECT!' : 'ALIGN IT',
                                  style: GoogleFonts.boogaloo(
                                    fontSize: 14,
                                    color: CyberTheme.inkBlack,
                                  ),
                                ),
                                Text(
                                  _getGuidanceText(),
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: CyberTheme.inkBlack.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Big score display
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: CyberTheme.inkBlack,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$_displayScore%',
                              style: GoogleFonts.boogaloo(
                                fontSize: 18,
                                color: _isAligned ? CyberTheme.limeGreen : Colors.white,
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
              color: CyberTheme.darkSurface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_activeState == 'lock') ...[
                    Text(
                      '🕹️ DRAG TO COMPOSE',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white54,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // POS Slider
                    Row(
                      children: [
                        Text(
                          'POS',
                          style: GoogleFonts.boogaloo(fontSize: 13, color: Colors.white60),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: CyberTheme.hotPink,
                              inactiveTrackColor: Colors.white12,
                              thumbColor: CyberTheme.hotPink,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                              overlayShape: SliderComponentShape.noOverlay,
                            ),
                            child: Slider(
                              value: _posX,
                              min: 0,
                              max: 100,
                              onChanged: (val) => setState(() { _posX = val; _calculateScore(); }),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // SCALE Slider
                    Row(
                      children: [
                        Text(
                          'ZOOM',
                          style: GoogleFonts.boogaloo(fontSize: 13, color: Colors.white60),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: CyberTheme.hotPink,
                              inactiveTrackColor: Colors.white12,
                              thumbColor: CyberTheme.hotPink,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                              overlayShape: SliderComponentShape.noOverlay,
                            ),
                            child: Slider(
                              value: _scale,
                              min: 50,
                              max: 150,
                              onChanged: (val) => setState(() { _scale = val; _calculateScore(); }),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                          color: CyberTheme.limeGreen,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '🔒 LOCK & HAND OVER',
                            style: GoogleFonts.boogaloo(
                              fontSize: 16,
                              color: CyberTheme.inkBlack,
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
                        color: CyberTheme.hotPink.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: CyberTheme.hotPink, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Text('🤳', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HANDED OVER!',
                                  style: GoogleFonts.boogaloo(
                                    fontSize: 14,
                                    color: CyberTheme.hotPink,
                                  ),
                                ),
                                Text(
                                  'Stranger just needs to align — auto-clicks when matched!',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
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
                                  '↩ RE-COMPOSE',
                                  style: GoogleFonts.boogaloo(
                                    fontSize: 13,
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
                              color: _isAligned ? CyberTheme.limeGreen : const Color(0xFF333333),
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

  String _getGuidanceText() {
    if (_rawScore >= 92.0) {
      return 'TARGET ACQUIRED! HOLD STEADY...';
    }
    if (_pitch.abs() > 1.5) {
      return _pitch > 0 ? '← TILT PHONE RIGHT' : 'TILT PHONE LEFT →';
    }
    double rollDiff = _roll.abs() - 9.8;
    if (rollDiff.abs() > 1.5) {
      return rollDiff > 0 ? '↓ TILT PHONE FORWARD' : 'TILT PHONE BACKWARD ↑';
    }
    if (_posX < 45) {
      return '← MOVE DEVICE RIGHT';
    } else if (_posX > 55) {
      return 'MOVE DEVICE LEFT →';
    } else if (_scale < 90) {
      return '🔎 STEP CLOSER';
    } else if (_scale > 110) {
      return '🔎 STEP BACK';
    }
    return '🎯 ALIGNING Composition...';
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _shutterTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}

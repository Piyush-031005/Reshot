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
        final mockUrl = 'https://picsum.photos/seed/$seed/600/800';
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
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberTheme.cyberBlack,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.black, width: 4),
          borderRadius: BorderRadius.zero,
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: CyberTheme.limeGreen),
            const SizedBox(width: 8),
            Text(
              'RESHOT_SUCCESS.SYS',
              style: GoogleFonts.pressStart2p(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 3),
              ),
              child: _capturedFile != null
                  ? (kIsWeb || _capturedFile!.path.startsWith('http')
                      ? Image.network(
                          _capturedFile!.path,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(_capturedFile!.path),
                          fit: BoxFit.cover,
                        ))
                  : Container(color: Colors.black),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.black,
              child: Text(
                'COMPOSITION MATCH: $_displayScore%',
                style: GoogleFonts.pressStart2p(
                  fontSize: 10,
                  color: CyberTheme.limeGreen,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Photo successfully aligned and captured! Saved to device gallery.',
              style: Theme.of(ctx).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberTheme.hotPink,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.black, width: 2),
                borderRadius: BorderRadius.zero,
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // Fix 1: mounted check before navigating from outer context.
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(
              'RETURN TO DASHBOARD',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top HUD Bar
            Container(
              padding: const EdgeInsets.all(12),
              color: CyberTheme.cyberDark,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    widget.mode == 'director' ? 'DIRECTOR CAMERA' : 'LANDMARK ECHO',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 10,
                      color: CyberTheme.limeGreen,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _activeState == 'lock' ? CyberTheme.cyberGray : CyberTheme.hotPink,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Text(
                      _activeState == 'lock' ? '1. SETTING COMP' : '2. HANDED OVER',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 8,
                        color: _activeState == 'lock' ? Colors.white70 : Colors.black,
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
                              'https://picsum.photos/id/10/600/800',
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

                  // Alignment HUD
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(217),
                        border: Border.all(
                          color: _isAligned ? CyberTheme.limeGreen : CyberTheme.hotPink,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isAligned ? 'COMPOSITION PERFECT' : 'ALIGNMENT NEEDED',
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 8,
                                  color: _isAligned ? CyberTheme.limeGreen : CyberTheme.hotPink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getGuidanceText(),
                                style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                          // Show display score (rounded) in UI.
                          Text(
                            '$_displayScore%',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 16,
                              color: _isAligned ? CyberTheme.limeGreen : CyberTheme.hotPink,
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
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              color: CyberTheme.cyberDark,
              child: Column(
                children: [
                  if (_activeState == 'lock') ...[
                    Text(
                      'SIMULATE CAMERA MOVEMENT (DRAG TO COMPOSE)',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 8,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('POS: ', style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: Slider(
                            value: _posX,
                            min: 0,
                            max: 100,
                            activeColor: CyberTheme.hotPink,
                            onChanged: (val) {
                              setState(() {
                                _posX = val;
                                _calculateScore();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('SCALE: ', style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: Slider(
                            value: _scale,
                            min: 50,
                            max: 150,
                            activeColor: CyberTheme.hotPink,
                            onChanged: (val) {
                              setState(() {
                                _scale = val;
                                _calculateScore();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CyberTheme.limeGreen,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Colors.black, width: 3),
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _activeState = 'handover';
                          _posX = 24.0;
                          _scale = 80.0;
                          _calculateScore();
                        });
                      },
                      child: Text(
                        'LOCK COMPOSITION & HANDOVER',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'HANDED OVER TO STRANGER',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 10,
                        color: CyberTheme.hotPink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stranger only needs to align the phone. The camera auto-clicks when the horizon and skeleton align.',
                      style: textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white30, width: 2),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              setState(() {
                                _activeState = 'lock';
                                _shutterTimer?.cancel();
                              });
                            },
                            child: const Text('CANCEL / RE-COMPOSE'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: _isCapturing ? null : _captureImage,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _isAligned ? CyberTheme.limeGreen : Colors.white24,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 3),
                            ),
                            child: const Icon(Icons.camera, color: Colors.black),
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
